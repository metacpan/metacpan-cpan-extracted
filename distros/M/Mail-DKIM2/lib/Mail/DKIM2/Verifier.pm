package Mail::DKIM2::Verifier;
use strict;
use warnings;

our $VERSION = '0.27';

use base 'Mail::DKIM2::HeaderParser';
use Crypt::Digest::SHA256 qw(sha256);
use MIME::Base64 qw(encode_base64 decode_base64);
use Carp;
use POSIX qw();
use Time::HiRes ();
use Scalar::Util ();

use Mail::DKIM2::Common qw(
    MI_MISSING_M_ERROR
    parse_mime
    dkim2_canonicalize_header
    decode_tag_json
    encode_tag_json
    build_signing_input
    extract_mi_version
    domain_of
    to_alabel
    relaxed_domain_match
    check_ignore_prefixes
    MAX_CHAIN_LENGTH
    FUTURE_LIMIT
    EXPIRY
    chain_length_error
    duplicate_number_error
    valid_sequence
    unkeyable_signature_error
    chain_number_error
    mi_version_tag
);
use Email::MIME;
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::BodyPlan;
use Mail::DKIM2::HeaderPlan;

# The signing algorithms this verifier implements (-07 §3.2, §3.3), and
# the key class each needs. Every other s= item is ignored (§3.5).
my %IMPLEMENTED_ALG = (
    'rsa-sha256'     => 'Crypt::PK::RSA',
    'ed25519-sha256' => 'Crypt::PK::Ed25519',
);

# How long a key lookup sent in the background at the end of the headers is
# waited for, from when it was sent, before it is asked again the ordinary
# way (query(), with the resolver's retries and other nameservers). The
# answer normally arrives while the body is hashed; one that has not come in
# a second is treated as lost, not waited out.
our $PREFETCH_WAIT = 1;

# How often a background lookup still in flight is polled while waiting.
our $PREFETCH_POLL = 0.005;

# The most keys asked for in the background per message, the top signature's
# first. The prefetch runs before any field is judged, so a message naming
# thousands of selectors must not open thousands of sockets; a key not
# prefetched is asked for with query() if it is ever needed.
our $PREFETCH_MAX = 8;


sub known_options {
    return qw(SkipTimestampCheck AllowUnsignedMI MidProcess HeadersOnly
              PubkeyCallback Resolver IgnorePrefixes NextDomainOK StreamBody
              InstancesOnly);
}

sub init {
    my $self = shift;
    $self->SUPER::init;
    $self->{_mi_headers}         = {};
    $self->{_dk2_headers}        = {};
    $self->{_chain_counts}       = {};
    $self->{result}              = undef;
    $self->{details}             = undef;
    $self->{diagnostic}          = undef;
    # Options the constructor was given stay; the rest get their defaults.
    $self->{$_} //= 0 for qw(SkipTimestampCheck MidProcess AllowUnsignedMI HeadersOnly
                             InstancesOnly);
    $self->{StreamBody} //= 1;
    check_ignore_prefixes($self->{IgnorePrefixes});
}

sub skip_timestamp_check {
    my ($self, $val) = @_;
    $self->{SkipTimestampCheck} = $val if defined $val;
    return $self->{SkipTimestampCheck};
}

# allow_unsigned_mi: permit a Message-Instance whose m= is higher than any
# DKIM2-Signature's m=, which -07 §14 otherwise makes a PERMERROR (see
# finish_body).
#
# Set this on an OUTBOUND path. A Signer legitimately holds the new
# Message-Instance before the signature covering it exists, so a verify run
# over that in-progress state must not reject it. Do NOT set it when
# verifying mail that arrived from elsewhere: there the unsigned instance is
# exactly the accountability gap the spec is closing.
#
# mid_process implies it, because a partial chain view always looks like this:
# Validate.pm strips higher-numbered DKIM2-Signature headers for its top-down
# walk while keeping every Message-Instance.
sub allow_unsigned_mi {
    my ($self, $val) = @_;
    $self->{AllowUnsignedMI} = $val if defined $val;
    return $self->{AllowUnsignedMI};
}

# next_domain_ok: an OUTBOUND signer's own d=. A top DKIM2-Signature carrying
# nd= is then acceptable when nd= names that domain (case-insensitively): the
# caller is the hop the imaginary hop pointed at, and its signature is the one
# nd= promised. Any other nd= on top is refused. Unset (the default) keeps the
# inbound rule: a top nd= is a permerror.
sub next_domain_ok {
    my ($self, $val) = @_;
    $self->{NextDomainOK} = $val if defined $val;
    return $self->{NextDomainOK};
}

# mid_process: set when this Verifier is being run against a partial view of
# the chain (e.g. Validate.pm's per-level sub-verify, which strips
# higher-numbered DKIM2-Signature headers before re-verifying). In that view
# the highest remaining i= is NOT the true top of the whole chain, so the
# top-nd= rejection below (only valid for a final, whole-message verify)
# must be suppressed. Defaults to 0: a standalone/whole-message verify still
# rejects a true top nd=.
sub mid_process {
    my ($self, $val) = @_;
    $self->{MidProcess} = $val if defined $val;
    return $self->{MidProcess};
}

# headers_only: the message being verified has no body, as with the returned
# original in a DSN's text/rfc822-headers part (-07 §16.3). Signatures
# and the chain are checked as usual; of the Message-Instance content check,
# only the header hash of the top instance can be, so only that is.
sub headers_only {
    my ($self, $val) = @_;
    $self->{HeadersOnly} = $val if defined $val;
    return $self->{HeadersOnly};
}

# instances_only: check the Message-Instance chain and stop there, for a
# caller that has had the signatures verified already (Gate's VerifyResult).
# The result is 'pass' when the chain is intact. The signatures are not
# checked, so an instance none of them covers is no fault here either.
sub instances_only {
    my ($self, $val) = @_;
    $self->{InstancesOnly} = $val if defined $val;
    return $self->{InstancesOnly};
}

# stream_body: hash every instance's body as the body arrives, and work out
# every header hash from the fields as received (Mail::DKIM2::BodyPlan and
# HeaderPlan), instead of keeping the body and undoing each instance. On by
# default; off is the undo walk, kept to check the plans against.
sub stream_body {
    my ($self, $val) = @_;
    $self->{StreamBody} = $val if defined $val;
    return $self->{StreamBody};
}

sub handle_header {
    my ($self, $field_name, $contents, $line) = @_;

    my $lc_name = lc $field_name;
    if ($lc_name eq 'message-instance' || $lc_name eq 'dkim2-signature') {
        return if ++$self->{_chain_counts}{$lc_name} > MAX_CHAIN_LENGTH;
    }

    if ($lc_name eq 'message-instance') {
        eval {
            my $raw = mi_version_tag($contents);
            # Bounded here, before finish_body walks 1..m= for gaps. Keyed
            # by number, so m=01 is m=1.
            my $v = extract_mi_version($contents);
            if (!defined $raw) {
                # No m= at all: nothing to place it in the chain by.
                $self->{_mi_unusable} //= MI_MISSING_M_ERROR;
            }
            elsif (my $e = chain_number_error('Message-Instance', 'm', $raw)) {
                $self->{_mi_unusable} //= $e;
            }
            elsif ($v) {
                push @{$self->{_numbers}{'message-instance'}}, $v;
                $self->{_mi_headers}{$v} = $line || "$field_name:$contents";
            }
            1;
        } or do {
            die $@ if ref $@;
            # Defensive: neither helper dies on a string today, but a field
            # that could not be read has no m= to place it in the chain by.
            $self->{_mi_unusable} //= MI_MISSING_M_ERROR;
        };
    }
    elsif ($lc_name eq 'dkim2-signature') {
        # A signature this verifier cannot key -- one that does not parse,
        # or whose i= is missing or not a positive integer -- is a PERMERROR
        # (finish_header), never silently ignored: otherwise a junk
        # "DKIM2-Signature: m=2" would read as covering m=2 to anyone counting
        # coverage by m= (the signer gate) while nothing here checked it.
        my $sig = eval { Mail::DKIM2::Signature->parse($contents) };
        die $@ if ref $@;
        my $i = $sig ? $sig->sequence : undef;
        my $range = valid_sequence($i)
            && (chain_number_error('DKIM2-Signature', 'i', $i)
                // chain_number_error('DKIM2-Signature', 'm', $sig->version, $i));
        if ($range) {
            # Bounded here, before finish_body walks 1..i= for gaps.
            $self->{_sig_unusable} //= $range;
        }
        elsif (valid_sequence($i)) {
            push @{$self->{_numbers}{'dkim2-signature'}}, $i;
            $self->{_dk2_headers}{$i + 0} = {
                raw => $line || "$field_name:$contents",
                sig => $sig,
            };
        } else {
            $self->{_sig_unusable} //= unkeyable_signature_error($contents);
        }
    }
}

# Verification happens in finish_body, unless the header fields alone already
# decide the result.
sub finish_header {
    my $self = shift;
    if (my $error = $self->_structure_error) {
        $self->{result}  = 'permerror';
        $self->{details} = $error;
        $self->stop;
        return;
    }

    # With no DKIM2 field at all the verdict is 'none' already, so the body
    # is not kept: most mail carries no DKIM2, and a verifier run on every
    # message would otherwise hold a copy of each. Instances with no
    # signature (AllowUnsignedMI, MidProcess, InstancesOnly: anything else
    # has stopped above) still have their chain walked.
    unless (%{$self->{_dk2_headers}} || %{$self->{_mi_headers}}) {
        $self->finish_body;
        $self->stop;
        return;
    }

    $self->_prefetch_keys
        if %{$self->{_dk2_headers}} && !$self->{InstancesOnly};

    $self->_start_plans if $self->{StreamBody} && !$self->{HeadersOnly};
}

# -07 section 14.2, structure: what the fields' names and m=/i= numbers
# alone decide, in the interop contract's fixed order (C9: a..h), so every
# verifier names the same fault first. The faults that decide which fields
# are in the chain at all (a..e) come before the gaps and coverage worked
# out from them (f..h). undef if the chain's shape is sound.
sub _structure_error {
    my ($self) = @_;
    my $numbers = $self->{_numbers};
    # InstancesOnly: the signatures are the caller's, so only their count.
    my $sigs = !$self->{InstancesOnly};
    my %mi  = %{$self->{_mi_headers}};
    my %dk2 = $sigs ? %{$self->{_dk2_headers}} : ();
    my $error = chain_length_error($self->{_chain_counts})              # a
        // $self->{_mi_unusable}                                        # b
        // duplicate_number_error('Message-Instance', 'm',              # c
               @{$numbers->{'message-instance'} || []})
        // ($sigs ? $self->{_sig_unusable} : undef)                     # d
        // ($sigs ? duplicate_number_error('DKIM2-Signature', 'i',      # e
               @{$numbers->{'dkim2-signature'} || []}) : undef);
    return $error if $error;

    # f: every instance from m=1 up to the highest there is, or the highest
    # the top signature covers -- a signature naming an absent instance is
    # the same gap.
    my ($max_v) = sort { $b <=> $a } keys %mi;
    my ($max_i) = sort { $b <=> $a } keys %dk2;
    my $top_m = defined $max_i ? ($dk2{$max_i}{sig}->version || 0) : 0;
    my $upto = ($max_v // 0) > $top_m ? $max_v : $top_m;
    for my $v (1 .. $upto) {
        return "PERMERROR: Message-Instance m=$v missing" unless $mi{$v};
    }

    # g: an instance above every signature's m= is one nothing vouches for.
    # Not for an outbound signer (AllowUnsignedMI: it holds the instance it
    # is about to sign) or a partial chain view (MidProcess).
    if (defined $max_v && !$self->{AllowUnsignedMI} && !$self->{MidProcess}
        && !$self->{InstancesOnly}) {
        my ($top_signed) = sort { $b <=> $a } grep { defined }
                           map { $_->{sig}->version } values %dk2;
        return "PERMERROR: Message-Instance m=$max_v is not signed"
            if !defined $top_signed || $max_v > $top_signed;
    }

    for my $i (1 .. ($max_i // 0)) {                                     # h
        return "PERMERROR: DKIM2-Signature i=$i missing" unless $dk2{$i};
    }
    return;
}

# StreamBody: from the header fields, parsed once as the undo walk's parser
# parses them, work out every instance's header hash (HeaderPlan) and plan
# its body (BodyPlan), then hash the body as it arrives rather than keeping
# it. The instances are parsed once, highest m= first, stopping at one that
# does not parse; the chain walk reports that one in verify()'s words.
sub _start_plans {
    my ($self) = @_;
    my $hplan  = Mail::DKIM2::HeaderPlan->new($self->{headers},
        IgnorePrefixes => $self->{IgnorePrefixes});
    my @values = $hplan->values('Message-Instance');
    my %by_v   = map { (extract_mi_version($_) // 0) => $_ } @values;

    my (@parsed, %parsed, %parse_error);
    for my $v (sort { $b <=> $a } grep { $_ } keys %by_v) {
        my $obj = eval { Mail::DKIM2::MessageInstance->parse($by_v{$v}) };
        die $@ if ref $@;
        unless ($obj) {
            $parse_error{$v} = Mail::DKIM2::MessageInstance::_parse_error($@);
            last;
        }
        push @parsed, $obj;
        $parsed{$v} = $obj;
    }
    $self->{_planned} = { values => \@values, by_v => \%by_v,
                          parsed => \%parsed, parse_error => \%parse_error };
    $self->{_header_plan} = $hplan->plan(@parsed);
    my $plan = $self->{_body_plan} = Mail::DKIM2::BodyPlan->new(@parsed);
    $self->{_body_sink} = sub { $plan->add($_[0]) };
}

sub finish_body {
    my $self = shift;

    my %mi_map  = %{$self->{_mi_headers}};
    my %dk2_map = %{$self->{_dk2_headers}};

    # -07 section 14.2, structure (also checked at the end of the headers,
    # which stops there on a fault).
    if (my $error = $self->_structure_error) {
        return $self->_outcome($error);
    }

    # The Message-Instances first, then the signatures over them: a
    # signature is worth checking, and its key worth fetching, only over
    # instances that describe the message.
    #
    # Section 14.2, content: every Message-Instance on its own, by ascending
    # m= -- its tag list, then a duplicate hash algorithm, then its Recipe
    # (MessageInstance->parse checks in that order), then the Recipe's copy
    # ranges. Only the bound a message gives a range is left for the chain
    # walk.
    for my $v (sort { $a <=> $b } keys %mi_map) {
        (my $value = $mi_map{$v}) =~ s/\A[^:]*:[ \t]*//;
        my $obj = eval { Mail::DKIM2::MessageInstance->parse($value) };
        die $@ if ref $@;
        return $self->_outcome(Mail::DKIM2::MessageInstance::_parse_error($@)) unless $obj;
        if (defined(my $why = $obj->recipe_order_error)) {
            $self->{diagnostic} = $why;
            return $self->_error(permerror => "Message-Instance m=$v contains invalid JSON");
        }
    }

    # Section 14.7: walk the chain. Verify the top instance against the
    # current content, then undo each instance and verify the reconstructed
    # content against the next one down, until m=1; past an instance with a
    # null body Recipe (previous body unrecoverable) the walk continues over
    # the header history only. Top down, so the highest instance that fails
    # is the one reported.
    #
    # MessageInstance::parse() dies (rather than returning an error) on a
    # malformed r= payload -- e.g. the §14.2 invalid-JSON PERMERROR -- so
    # this must run under eval or that die would propagate uncaught out of
    # finish_body() and crash the caller instead of yielding a clean
    # permerror result.
    my $mi_chain_ok = eval {
        $self->{HeadersOnly} ? $self->_verify_top_mi_headers() : $self->_verify_mi_chain()
    };
    if (my $err = $@) {
        die $err if ref $err;
        chomp $err;
        return $self->_outcome($err);
    }
    return unless $mi_chain_ok;

    if ($self->{InstancesOnly}) {
        my $top = (sort { $b <=> $a } keys %mi_map)[0];
        @{$self}{qw(result details)} = $top
            ? ('pass', "Message-Instance m=1..$top intact")
            : ('none', 'no Message-Instance headers found');
        return;
    }
    unless (keys %dk2_map) {
        $self->{result} = 'none';
        $self->{details} = 'no DKIM2-Signature headers found';
        return;
    }

    my $max_i = (sort { $b <=> $a } keys %dk2_map)[0];
    my $signature = $dk2_map{$max_i}{sig};

    # Contract C9: the signatures are checked in -07 section 14 order,
    # each section over every signature from i=1 up, so the first error
    # found is the primary one. Section 14.2: each field on its own.
    for my $i (1..$max_i) {
        return unless $self->_check_sig_field($i);
    }

    # Section 14.3: the timestamps.
    for my $i (1..$max_i) {
        return unless $self->_check_sig_time($i);
    }

    # Section 14.4: the top signature's nd=, then the Chain of Custody
    # (each signature against the one below it, and its own mf= against
    # its d=).
    #
    # Local policy (-07 sections 13.1, 14.4: a top nd= needs an out-of-band arrangement): the
    # highest-numbered DKIM2-Signature MUST NOT carry nd=. The only legitimate
    # nd= producer is reflector-brand-nd, which always emits the matching
    # higher-i= signature too, so nd= never appears on top.
    #
    # Only valid for a FINAL, whole-message verification: $max_i here is the
    # top of whatever chain view this Verifier was fed. During a partial/
    # mid-chain verify (mid_process set, e.g. by Validate.pm's per-level
    # sub-verify after stripping higher signatures) that "top" is not the
    # real top of the chain, so this rejection must be suppressed.
    #
    # An outbound signer (next_domain_ok set to its own d=) may extend a chain
    # whose top nd= names it: that is the bridge it was named to complete.
    if (!$self->{MidProcess}
        && defined $signature->next_domain && length $signature->next_domain) {
        my $ok = $self->{NextDomainOK};
        if (defined $ok && length $ok) {
            if (lc $signature->next_domain ne lc $ok) {
                return $self->_error(permerror => "not signing: top signature nd="
                    . $signature->next_domain . " names another domain");
            }
            # nd= names us: carry on
        } else {
            return $self->_error(permerror => "DKIM2-Signature i=$max_i unexpected nd= tag");
        }
    }
    return unless $self->_verify_chain();

    # Section 14.5 (every key), then section 14.6 (every signature).
    for my $i (1..$max_i) {
        return unless $self->_check_sig_keys($i);
    }
    for my $i (1..$max_i) {
        return unless $self->_check_sig_crypto($i);
    }

    # -07 section 11, 14.8: every From the message has had must be
    # Authentic for the signature that answers for it.
    return unless $self->_verify_from;

    $self->{result} = 'pass';
    $self->{details} = "i=1..$max_i verified";
}

# From must be Authentic (-07 sections 11 and 14.8): the From in effect
# when each signature was made (see the pairs below). A version of the header comes from the undo walk if that ran, else from the
# header plan (made here if the body was hashed without one). An instance
# no signature covers (AllowUnsignedMI, MidProcess) has no signature to
# answer for its From: the signer gate leaves that to the Signer, which
# checks the From it is about to sign.
sub _verify_from {
    my ($self) = @_;
    my %dk2_map = %{$self->{_dk2_headers}};
    my @sigs = map { [$_, 0 + ($dk2_map{$_}{sig}->version // 0)] } sort { $a <=> $b } keys %dk2_map;
    return 1 unless @sigs;

    my ($hplan, @parsed);
    if ($self->{_planned} && $self->{_header_plan}) {
        $hplan  = $self->{_header_plan};
        @parsed = values %{ $self->{_planned}{parsed} };
    } else {
        $hplan = Mail::DKIM2::HeaderPlan->new($self->{headers},
            IgnorePrefixes => $self->{IgnorePrefixes});
        for my $value ($hplan->values('Message-Instance')) {
            my $mi = eval { Mail::DKIM2::MessageInstance->parse($value) };
            die $@ if ref $@;
            push @parsed, $mi if $mi;
        }
        @parsed = sort { $b->get_tag('m') <=> $a->get_tag('m') } @parsed;
        $hplan->plan(@parsed);
    }
    my $from_at = sub {
        my ($m) = @_;
        return $self->{_from_at}{$m} if $self->{_from_at} && $self->{_from_at}{$m};
        return $hplan->values_at($m, 'From') // [];
    };

    # -07 §11, contract C5 as corrected by Ruling 19: the From in effect when
    # each signature was made. i=1 against the From at state m(i=1); each
    # i >= 2 against the From at state m(i) when an instance k with
    # m(i-1) < k <= m(i) replaced From. A From replaced before any signature
    # covered it (an unsigned ingress m=1 a list rewrote in m=2 before
    # signing i=1) is never checked.
    my %changes_from;
    for my $mi (@parsed) {
        my $k = 0 + $mi->get_tag('m');
        $changes_from{$k} = 1
            if $k >= 2 && $mi->get_tag('rh') && exists $mi->get_tag('rh')->{from};
    }
    my @pairs;
    my $prev_m;
    for my $sig (@sigs) {
        my ($i, $m) = @$sig;
        my $due = $i == 1
            || (defined $prev_m && grep { $_ > $prev_m && $_ <= $m } keys %changes_from);
        $prev_m = $m;
        push @pairs, [$m, $i] if $due;
    }
    for my $pair (@pairs) {
        my ($k, $i) = @$pair;
        my $d = $dk2_map{$i}{sig}->domain // '';
        next if Mail::DKIM2::Common::from_authentic($d, @{ $from_at->($k) });
        return $self->_error(permerror => "DKIM2-Signature i=$i matching From is not authentic");
    }
    return 1;
}

# The headers-only half of _verify_mi_chain: the top instance's header hash
# against the headers we were given. Nothing further down the chain can be
# checked without a body to undo into.
sub _verify_top_mi_headers {
    my ($self) = @_;

    my $raw = join('', @{$self->{headers}}) . "\r\n";
    my $msg = parse_mime($raw);
    my %by_v = map { (extract_mi_version($_) // 0) => $_ } $msg->header_raw('Message-Instance');
    return 1 unless %by_v;
    my $num = (sort { $b <=> $a } keys %by_v)[0];
    my $mi  = Mail::DKIM2::MessageInstance->parse($by_v{$num});

    my $hashes = $mi->get_tag('hashes') || {};
    my $impl   = Mail::DKIM2::MessageInstance::hash_algs();
    my @usable = sort grep { $impl->{$_} } keys %$hashes;
    return $self->_error(permerror => "Message-Instance m=$num no supported hash algorithm")
        unless @usable;
    for my $alg (@usable) {
        my $want = $hashes->{$alg}[0];
        my $have = Mail::DKIM2::MessageInstance::h_digest($msg, $alg, $self->{IgnorePrefixes});
        next if $want eq $have;
        return $self->_error(fail => "Message-Instance m=$num header hash $alg mismatch");
    }
    return 1;
}

sub _verify_mi_chain {
    my ($self) = @_;

    # With a BodyPlan the body was hashed as it arrived and is not here: the
    # walk checks and undoes the headers, and takes each body hash, and each
    # body Recipe's verdict, from the plan.
    my $plan = $self->{_body_plan};
    $plan->finish if $plan;
    my $hplan = $self->{_header_plan};
    return $self->_verify_mi_chain_planned
        if $hplan && !$hplan->rewrites_instances;

    my $raw = join('', @{$self->{headers}}) . "\r\n" . ($self->{_buf} // '');
    my $msg = parse_mime($raw);

    my $headers_only = 0;
    while (1) {
        my @mi = $msg->header_raw('Message-Instance');
        my %by_v = map { (extract_mi_version($_) // 0) => $_ } @mi;
        my $num = %by_v ? (sort { $b <=> $a } keys %by_v)[0] : 0;
        last unless $num;
        # This version's From fields, for the -07 section 11 check.
        $self->{_from_at}{$num} = [ $msg->header_raw('From') ];

        my %body = (HeadersOnly => $headers_only);
        if ($plan && !$headers_only) {
            my %hashes = map { my $h = $plan->body_hash($num, $_); defined $h ? ($_ => $h) : () }
                         keys %{ Mail::DKIM2::MessageInstance::hash_algs() };
            %body = %hashes ? (BodyHashes => \%hashes) : (HeadersOnly => 1);
        }
        my ($ok, $err) = Mail::DKIM2::MessageInstance->verify($msg,
            IgnorePrefixes => $self->{IgnorePrefixes}, %body);
        return $self->_mi_mismatch($num, $err) unless $ok;

        last if $num <= 1;

        # A null body Recipe loses the previous body, not the header
        # history: from here down, undo header Recipes only and check each
        # instance's header hashes, down to m=1.
        my $mi_obj = Mail::DKIM2::MessageInstance->parse($by_v{$num});
        $headers_only = 1 if $mi_obj->unrecoverable;

        my $prev = eval {
            if ($plan && (my $e = $plan->recipe_error($num))) {
                die $e;
            }
            Mail::DKIM2::MessageInstance->undo($msg, HeadersOnly => $headers_only || $plan)
        };
        die $@ if ref $@;
        return $self->_mi_undo_failed($num, $@) if $@ || !$prev;
        $msg = $prev;
    }

    return 1;
}

# _verify_mi_chain with both plans: the same walk and the same verdicts,
# but every hash and every Recipe's verdict is the plans' -- nothing is
# rebuilt. (Unless a header Recipe names Message-Instance, which changes
# the instances below it: _verify_mi_chain walks that itself.)
sub _verify_mi_chain_planned {
    my ($self) = @_;
    my ($plan, $hplan) = @{$self}{qw(_body_plan _header_plan)};
    my $p = $self->{_planned};
    my @nums = sort { $b <=> $a } grep { $_ } keys %{$p->{by_v}};
    return 1 unless @nums;

    if (my $err = Mail::DKIM2::MessageInstance::_chain_error_fields($p->{values},
            $self->{_chain_counts}{'dkim2-signature'} // 0)) {
        return $self->_mi_mismatch($nums[0], $err);
    }

    my $headers_only = 0;
    for my $num (@nums) {
        my $mi = $p->{parsed}{$num};
        my ($ok, $err) = $mi
            ? $mi->_check_hashes($num,
                  sub { $hplan->header_hash($num, $_[0]) // '' },
                  $headers_only ? undef : sub { $plan->body_hash($num, $_[0]) // '' })
            : (0, $p->{parse_error}{$num});
        return $self->_mi_mismatch($num, $err) unless $ok;

        last if $num <= 1;

        $headers_only = 1 if $mi->unrecoverable;
        if (my $e = $plan->recipe_error($num) // $hplan->recipe_error($num)) {
            return $self->_mi_undo_failed($num, $e);
        }
    }
    return 1;
}

# Instance $num does not match the content it describes.
sub _mi_mismatch {
    my ($self, $num, $err) = @_;
    # MessageInstance's reasons carry their state and -07 section 14.2 /
    # 14.7 words: a malformed instance is a PERMERROR, a hash that does
    # not match ("FAIL: Message-Instance m=N header hash sha256 mismatch")
    # a FAIL.
    return $self->_outcome($err // "FAIL: Message-Instance m=$num header hash mismatch");
}

# Instance $num's Recipe does not undo: a copy range past the end, out of
# order or overlapping -- every Recipe error is "contains invalid JSON"
# (the -07 contract). Which range is kept for diagnostic().
sub _mi_undo_failed {
    my ($self, $num, $err) = @_;
    if (defined $err) {
        (my $why = "$err") =~ s/\s+\z//;
        # Already a verdict (the instances do not form a chain, say).
        return $self->_outcome($why) if $why =~ /\A(?:PERMERROR|FAIL|TEMPERROR): /;
        $self->{diagnostic} = $why;
    }
    return $self->_error(permerror => "Message-Instance m=$num contains invalid JSON");
}

# Signature $i's checks, one -07 section 14 step at a time (contract C9:
# finish_body runs each step over every signature before the next). Each
# returns 1, or 0 with the outcome recorded.

# Section 14.2: the field on its own -- its tags, mf=/rt= form, the
# section 10.9 duplicate and limit rules, and every implemented item's
# value. Keeps the items to check and the signing input for the later steps.
sub _check_sig_field {
    my ($self, $i) = @_;

    my %mi_map  = %{$self->{_mi_headers}};
    my %dk2_map = %{$self->{_dk2_headers}};
    my $dk2_entry = $dk2_map{$i};
    my $signature = $dk2_entry->{sig};

    # -07 section 8: a tag given twice, in any case, makes the whole list
    # invalid; and a field that does not parse is a syntax error -- never
    # verified with its malformed parts dropped (follow-up review F3, F4).
    return $self->_error(permerror => "DKIM2-Signature i=$i syntax error")
        if $signature->duplicate_tag || $signature->syntax_error;

    # Only include headers that existed when signature $i was created:
    # - DKIM2-Sig headers with i <= $i
    # - MI headers with m <= the version referenced by signature $i
    my $max_v = $signature->version || 0;
    # If signature has no m= (i=1 with no prior MI), include MI up to $i
    $max_v = $i if !$max_v;

    my @mi_arr  = map { { v => $_, raw => $mi_map{$_} } }
                  sort { $a <=> $b }
                  grep { $_ <= $max_v } keys %mi_map;
    my @dk2_arr = map { { i => $_, raw => $dk2_map{$_}{raw}, sig => $dk2_map{$_}{sig} } }
                  sort { $a <=> $b }
                  grep { $_ <= $i } keys %dk2_map;

    # Build signing header: use as_string_without_data() then re-add trailing
    # semicolon if the raw header from the message had one (spec ABNF requires
    # trailing ';' on every tag; new signatures have it, old ones may not).
    my $sig_hdr_for_input = $signature->as_string_without_data();
    if ($dk2_entry->{raw} =~ /;\s*(?:\r\n)?$/ && $sig_hdr_for_input !~ /;\s*$/) {
        $sig_hdr_for_input .= ';';
    }

    my $signing_input = build_signing_input(
        mi_headers     => \@mi_arr,
        dk2_headers    => \@dk2_arr,
        signing_i      => $i,
        signature      => $signature,
        signing_header => $sig_hdr_for_input,
    );

    # -07 section 10: every DKIM2-Signature MUST carry i=, m=, t=, d=, s=. Checked
    # via get_tag() (not the sequence/version/timestamp/domain accessors)
    # because those accessors just proxy get_tag() and would themselves
    # return undef for an absent tag anyway -- get_tag() is used directly
    # here to make explicit that "missing" means "tag truly absent", not
    # coerced to 0/''. (Verified against TagValueList::get_tag/Signature.pm:
    # none of these accessors coerce a missing tag to a false-but-defined
    # value.)
    for my $t (qw(i m t d s)) {
        my $present =
              $t eq 's' ? ($signature->sig_count ? 1 : 0)
            : $t eq 'd' ? (defined($signature->get_tag('d')) && length $signature->get_tag('d'))
            :             defined $signature->get_tag($t);
        return $self->_error(permerror => "DKIM2-Signature i=$i tag=$t missing")
            unless $present;
    }

    # -07 section 10.9: reject a duplicate Selector, or the same algorithm 3+
    # times, within this signature's s= tag -- before any DNS lookup or
    # crypto work.
    if (my @dup_errors = $signature->check_duplicates) {
        return $self->_outcome($dup_errors[0]);
    }

    # -07 section 10: a signature carries either nd= or both mf= and rt=,
    # never both forms. nd= together with mf= or rt= makes the mf= (or rt=)
    # the unexpected tag.
    my $nd_tag = $signature->get_tag('nd');
    my $mf_tag = $signature->get_tag('mf');
    my $rt_tag = $signature->get_tag('rt');
    if (defined $nd_tag) {
        return $self->_error(permerror => "DKIM2-Signature i=$i tag=mf was unexpected")
            if defined $mf_tag;
        return $self->_error(permerror => "DKIM2-Signature i=$i tag=rt was unexpected")
            if defined $rt_tag;
    } else {
        return $self->_error(permerror => "DKIM2-Signature i=$i tag=mf missing")
            unless defined $mf_tag;
        return $self->_error(permerror => "DKIM2-Signature i=$i tag=rt missing")
            unless defined $rt_tag;
    }

    # Local check: n= nonce must not exceed 64 characters (no -07 string).
    my $nonce = $signature->get_tag('n');
    return $self->_error(permerror => "n= nonce exceeds 64 characters at i=$i")
        if defined $nonce && length($nonce) > 64;

    # t= is 1*DIGIT. A malformed value is a syntax error even when the
    # age check is skipped; it used to numify to 0 and skip that check.
    my $ts = $signature->timestamp;
    return $self->_error(permerror => "DKIM2-Signature i=$i syntax error")
        unless defined $ts && $ts =~ /\A[0-9]+\z/;

    # -07 sections 10.5, 10.6: mf= and each rt= MUST be a bracketed RFC 5321
    # path; one that is not is malformed.
    my $mf_raw = $signature->mail_from;
    return $self->_error(permerror => "DKIM2-Signature i=$i syntax error")
        if defined $mf_raw && length $mf_raw && $mf_raw !~ /^<.*>$/s;
    for my $r (@{ $signature->rcpt_to || [] }) {
        return $self->_error(permerror => "DKIM2-Signature i=$i syntax error")
            unless defined $r && $r =~ /^<.*>$/s;
    }

    # The items' outcome, in the order every implementation in this
    # repository follows (docs/superpowers/specs/
    # 2026-10-09-verifier-strictness-review-fixes.md, section E).
    #
    # -07 section 3.5: an algorithm this verifier does not implement is
    # ignored -- before any key lookup, so a list of unknown names costs
    # nothing. Names match exactly: tag values are case significant, and a
    # name that is merely like a known one must never be verified as it. A
    # known algorithm's value must be a padded base64string (section 2.14).
    my $sig_count = $signature->sig_count;
    my @items;
    for my $idx (0 .. $sig_count - 1) {
        my $alg = $signature->algorithm($idx) // '';
        next unless $IMPLEMENTED_ALG{$alg};
        my $sig_b64 = $signature->signature_value($idx) // '';
        return $self->_error(permerror => "DKIM2-Signature i=$i syntax error")
            unless Mail::DKIM2::Common::_is_base64string($sig_b64);
        push @items, [$idx, $alg, $sig_b64];
    }
    $dk2_entry->{items} = \@items;
    $dk2_entry->{signing_input} = $signing_input;
    return 1;
}

# Section 14.3: a signature made more than 14 days before delivery, or more
# than a day after it, is not Validly Signed.
sub _check_sig_time {
    my ($self, $i) = @_;
    return 1 if $self->{SkipTimestampCheck};
    my $ts  = $self->{_dk2_headers}{$i}{sig}->timestamp;
    my $now = time();
    return $self->_error(permerror => "DKIM2-Signature i=$i signature is from the future")
        if $ts > $now + FUTURE_LIMIT;
    return $self->_error(permerror => "DKIM2-Signature i=$i signature expired")
        if $now > $ts + EXPIRY;
    return 1;
}

# Section 14.5: every implemented item's public key. A key that cannot be
# had ends the check at once, in section 14.5's words; an absent one only
# skips its item, unless every item's is absent.
sub _check_sig_keys {
    my ($self, $i) = @_;
    my $dk2_entry = $self->{_dk2_headers}{$i};
    my $signature = $dk2_entry->{sig};
    # Local check: none of the algorithms is one this verifier implements.
    return $self->_error(permerror => "DKIM2-Signature i=$i has no signature with a supported algorithm")
        unless @{ $dk2_entry->{items} };

    my ($first_absent, @keyed);
    for my $item (@{ $dk2_entry->{items} }) {
        my ($idx, $alg, $sig_b64) = @$item;

        # Get the public key for this signature item.  The fetch is eval'd
        # whichever way the key is sourced: a pubkey callback may end in
        # fetch_public_key(), which dies on transient DNS. Guarding only the
        # no-callback branch once let that croak escape the verifier and take
        # the caller down with it -- the reflector dropped the message outright
        # instead of reflecting it unsigned.
        my $pubkey;
        my $fetched = eval {
            $pubkey = $self->{PubkeyCallback}
                ? $self->{PubkeyCallback}->($signature, $idx, $self)
                : $self->fetch_public_key($signature, $idx);
            1;
        };
        my $sel = $signature->selector($idx) // '?';
        unless ($fetched) {
            die $@ if ref $@;
            # Drop croak's " at FILE line N." tail: this reason may be
            # reported in Authentication-Results on mail we send out, and our
            # source paths are nobody else's business.
            (my $why = $@) =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
            $why =~ s/\s+\z//;
            # A key record that is there but unusable (-07 section 14.5:
            # several records, a syntax error, revoked, the wrong key type).
            return $self->_error(permerror => "DKIM2-Signature i=$i public key $sel $1")
                if $why =~ /\APERMERROR:\s*(.*)\z/s;
            # A transient DNS failure is a TEMPERROR -- retryable, not a
            # permanent "does not exist", and emphatically not a FAIL, which
            # reads as a forged signature. The resolver's reason goes to
            # diagnostic(), not into the -07 string.
            $self->{diagnostic} = $why;
            return $self->_error(temperror => "DKIM2-Signature i=$i public key $sel could not be fetched");
        }

        unless ($pubkey) {
            # No key published for this item: skip it, as long as another
            # item can be checked (below).
            $first_absent //= $sel;
            next;
        }

        # The key must be of the signature's algorithm. A PubkeyCallback
        # hands back any key object, so check what it is.
        return $self->_error(permerror => "DKIM2-Signature i=$i public key $sel algorithm mismatch")
            unless $pubkey->isa($IMPLEMENTED_ALG{$alg});

        # -07 section 3.2: RSA keys MUST be at least 1024 bits; a shorter key
        # is a local PERMERROR rather than a weak signature trusted.
        if ($alg eq 'rsa-sha256') {
            my $bits = $pubkey->size * 8;
            return $self->_error(permerror =>
                "DKIM2-Signature i=$i public key $sel is shorter than 1024 bits ($bits)")
                if $bits < 1024;
        }

        push @keyed, [@$item, $pubkey];
    }

    # -07 section 14.5: "a DNS result that indicates the key is absent MUST
    # be reported as a PERMERROR" -- when no item had a key to check.
    return $self->_error(permerror => "DKIM2-Signature i=$i public key $first_absent does not exist")
        unless @keyed;
    $dk2_entry->{keyed} = \@keyed;
    return 1;
}

# Section 14.6: every signature that can be checked is checked. All of them
# failing is "selector <s1> incorrect signature"; some passing and some
# failing is "signature <s1> signature <s2> failed" (s1 passed, s2 failed).
# Both are FAIL.
sub _check_sig_crypto {
    my ($self, $i) = @_;
    my $dk2_entry = $self->{_dk2_headers}{$i};
    my $signature = $dk2_entry->{sig};
    my $signing_input = $dk2_entry->{signing_input};
    my (@passed, @failed);
    for my $k (@{ $dk2_entry->{keyed} }) {
        my ($idx, $alg, $sig_b64, $pubkey) = @$k;
        my $sel = $signature->selector($idx) // '?';
        my $sig_raw = decode_base64($sig_b64);
        my $verified = eval {
            if ($alg eq 'ed25519-sha256') {
                # Ed25519-SHA256: SHA-256 hash first, then verify with PureEdDSA
                my $digest = sha256($signing_input);
                $pubkey->verify_message($sig_raw, $digest);
            } else {
                # RSA-SHA256: verify_message handles SHA-256 internally
                $pubkey->verify_message($sig_raw, $signing_input, 'SHA256', 'v1.5');
            }
        };
        if ($@) {
            die $@ if ref $@;
            ($self->{diagnostic} = "$@") =~ s/\s+\z//;
            $verified = 0;
        }
        push @{ $verified ? \@passed : \@failed }, $sel;
    }

    if (@failed) {
        return $self->_error(fail => "DKIM2-Signature i=$i signature $passed[0] signature $failed[0] failed")
            if @passed;
        return $self->_error(fail => "DKIM2-Signature i=$i selector $failed[0] incorrect signature");
    }

    return 1;
}

# Chain of Custody (-07 section 7.1 item 1, section 14.4). Every failure is
# a PERMERROR. For each signature S, from i=1 up:
#
# - S against the one below it, P (from i=2): if P carries nd=, S's d= must
#   be that domain (without regard to case), and nothing else is compared.
#   Otherwise some rt= address of P must relaxed-match (section 7.2) --
#   when S has nd= or a null mf=, S's d= (the rt= domain shortened);
#   otherwise S's mf= domain (shortened) against the rt= domain.
# - S's own mf= domain must relaxed-match its d=, unless the mf= is null or
#   S has nd= (and so no mf=).
#
# Which of the two tests runs first only matters for which error is
# reported when both fail; the link to P comes first.
sub _verify_chain {
    my ($self) = @_;
    my %dk2_map = %{$self->{_dk2_headers}};
    my @dk2_is = sort { $a <=> $b } keys %dk2_map;

    my $has_nd = sub { my $nd = $_[0]->next_domain; defined $nd && length $nd };
    for my $idx (0 .. $#dk2_is) {
        my $i   = $dk2_is[$idx];
        my $sig = $dk2_map{$i}{sig};
        my $d   = $sig->domain // '';
        my $mf  = $sig->mail_from;
        my $null_mf = defined $mf && $mf =~ /\A<\s*>\z/;

        if ($idx > 0) {
            my $p_i  = $dk2_is[$idx - 1];
            my $prev = $dk2_map{$p_i}{sig};
            if ($has_nd->($prev)) {
                return $self->_error(permerror => "DKIM2-Signature i=$p_i nd= does not match")
                    unless (to_alabel($prev->next_domain) =~ tr/A-Z/a-z/r) eq (to_alabel($d) =~ tr/A-Z/a-z/r);
            } else {
                my @rt = map { [domain_of($_)] } @{ $prev->rcpt_to || [] };
                if ($has_nd->($sig) || $null_mf) {
                    return $self->_error(permerror =>
                        "DKIM2-Signature i=$i d= does not match the rt= of i=$p_i")
                        unless grep { $_->[0] && !$_->[1] && relaxed_domain_match($_->[0], $d) } @rt;
                } else {
                    my ($mfd, $lit) = domain_of($mf);
                    return $self->_error(permerror =>
                        "DKIM2-Signature i=$i mf= does not match the rt= of i=$p_i")
                        unless $mfd && !$lit
                            && grep { $_->[0] && !$_->[1] && relaxed_domain_match($mfd, $_->[0]) } @rt;
                }
            }
        }

        if (defined $mf && !$null_mf && !$has_nd->($sig)) {
            my ($mfd, $lit) = domain_of($mf);
            return $self->_error(permerror => "DKIM2-Signature i=$i MAIL FROM and d= do not match")
                unless $mfd && !$lit && relaxed_domain_match($mfd, $d);
        }
    }

    return 1;
}

# Record an outcome: result $state, details "STATE: $text" (-07 section
# 14.1's form). Returns 0, for "return $self->_error(...)".
sub _error {
    my ($self, $state, $text) = @_;
    $self->{result}  = $state;
    $self->{details} = uc($state) . ": $text";
    return 0;
}

# Record a reason that may already carry its state ("FAIL: ...", as
# MessageInstance reports a hash mismatch): that state, else PERMERROR.
# Returns 0.
sub _outcome {
    my ($self, $reason) = @_;
    $reason //= 'unknown error';
    if ($reason =~ /\A(PERMERROR|FAIL|TEMPERROR): (.*)\z/s) {
        return $self->_error(lc $1 => $2);
    }
    return $self->_error(permerror => $reason);
}

# --- Public key lookup ---

# fetch_public_key($signature, $idx): the default key source, a TXT lookup of
# <selector>._domainkey.<d=> through the Resolver option (a Net::DNS::Resolver
# or anything with the same query/errorstring interface; one is made if none
# was given). Returns a Crypt::PK object, or undef when the answer positively
# says there is no such record. Anything else -- a timeout, SERVFAIL, REFUSED,
# a network error, or an errorstring this code has never seen -- dies with a
# TEMPERROR: -07 §13 makes a DNS failure retryable, never a permanent "no
# verifiable signature items", and emphatically never a 'fail', which reads as
# a forged signature. _check_sig_keys's eval maps the die to temperror.
# A record that is there but unusable dies with "PERMERROR: <why>" instead
# (-07 §14.5): more than one TXT record, a record that does not validate
# (parse_dkim_key_record), revoked, or a key type that is not the signature
# algorithm's -- mapped to permerror, with the selector.
#
# A PubkeyCallback replaces this; it is called as ($signature, $idx, $verifier)
# so a callback that only overrides some keys can fall back to
# $verifier->fetch_public_key($signature, $idx) and keep the classification.
sub fetch_public_key {
    my ($self, $signature, $idx) = @_;
    $idx //= 0;
    my $sel = $signature->selector($idx);
    my $dom = $signature->domain;
    croak "missing selector or domain" unless $sel && $dom;

    my $fqdn = "$sel._domainkey.$dom";
    my ($reply, $err) = @{ $self->{_key_replies}{lc $fqdn} //= $self->_key_reply($fqdn) };
    unless ($reply) {
        $err //= '';
        return if $err =~ /^(?:NXDOMAIN|NOERROR|NODATA)\s*$/i;
        croak "TEMPERROR: DNS lookup for $fqdn failed: $err";
    }
    # One TXT RR may hold several strings, joined with nothing between;
    # several RRs for one selector are an error (-07 §14.5).
    my @txt = map { join '', $_->txtdata } grep { $_->type eq 'TXT' } $reply->answer;
    return unless @txt;
    croak "PERMERROR: has multiple records\n" if @txt > 1;
    my ($key, $why) = Mail::DKIM2::Common::parse_dkim_key_record($txt[0]);
    $why = 'algorithm mismatch'
        if $why && $why eq 'has an unsupported key type';
    croak "PERMERROR: $why\n" if $why;
    # §10.9: the key's type must be the signature's algorithm's.
    my $alg = $signature->algorithm($idx) // '';
    croak "PERMERROR: algorithm mismatch\n"
        if $IMPLEMENTED_ALG{$alg} && !$key->isa($IMPLEMENTED_ALG{$alg});
    return $key;
}

sub _resolver {
    my ($self) = @_;
    return $self->{Resolver} //= do {
        require Net::DNS::Resolver;
        Net::DNS::Resolver->new;
    };
}

# Whether $resolver's background calls can be used for the prefetch. A
# subclass of Net::DNS::Resolver that overrides send or query (its own
# transport, caching, metrics -- FastMTA's and authentication_milter's do)
# but not bgsend would have Net::DNS's bgsend bypass it, and that asks only
# the first nameserver; such a resolver gets every lookup through query().
# One that provides its own bgsend is trusted with it.
sub _can_prefetch {
    my ($resolver) = @_;
    return 0 unless Scalar::Util::blessed($resolver);
    my $bgsend = $resolver->can('bgsend') or return 0;
    require Net::DNS::Resolver;
    return 1 if $bgsend != (Net::DNS::Resolver->can('bgsend') // 0);
    for my $method (qw(send query)) {
        my $own = $resolver->can($method) // 0;
        return 0 unless $own == (Net::DNS::Resolver->can($method) // -1);
    }
    return 1;
}

# Every key the signatures name, asked for at once, in the background, as
# soon as the header fields are in: the answers come back while the body
# arrives and is hashed. Only with a resolver whose background calls are
# safe to use (_can_prefetch), and not when a PubkeyCallback fetches the
# keys. Never fatal: a key not asked for here is asked for when it is wanted.
sub _prefetch_keys {
    my ($self) = @_;
    return if $self->{PubkeyCallback};
    my $resolver = $self->_resolver;
    return unless _can_prefetch($resolver);
    my $sent = 0;
    for my $entry (sort { $b->{sig}->sequence <=> $a->{sig}->sequence }
                   values %{$self->{_dk2_headers}}) {
        last if $sent >= $PREFETCH_MAX;
        my $sig = $entry->{sig};
        eval {
            my $dom = $sig->domain or return;
            for my $idx (0 .. ($sig->sig_count || 0) - 1) {
                return if $sent >= $PREFETCH_MAX;
                next unless $IMPLEMENTED_ALG{$sig->algorithm($idx) // ''};
                my $sel = $sig->selector($idx) or next;
                my $fqdn = "$sel._domainkey.$dom";
                next if $self->{_key_queries}{lc $fqdn};
                $sent++;
                my $handle = $resolver->bgsend($fqdn, 'TXT') or next;
                $self->{_key_queries}{lc $fqdn} =
                    [$handle, Time::HiRes::time() + $PREFETCH_WAIT];
            }
        };
        die $@ if ref $@;
    }
}

# The DNS answer for $fqdn as [$reply] or [undef, $error], query()'s
# results: from the background query if it gave one that settles it (an
# answer, NXDOMAIN, or NOERROR with none), else from query().
sub _key_reply {
    my ($self, $fqdn) = @_;
    my $resolver = $self->_resolver;
    if (my $q = delete $self->{_key_queries}{lc $fqdn}) {
        my $ready = 1;
        while ($resolver->bgbusy($q->[0])) {    # may swap in a TCP handle
            my $left = $q->[1] - Time::HiRes::time();
            if ($left <= 0) { $ready = 0; last }
            # Sleep between polls: a resolver's bgbusy need not block.
            my $poll = $PREFETCH_POLL > 0.001 ? $PREFETCH_POLL : 0.001;
            Time::HiRes::sleep($left < $poll ? $left : $poll);
        }
        # A truncated answer (Net::DNS's TCP retry failed) settles nothing.
        my $packet = $ready && $resolver->bgread($q->[0]);
        if ($packet && !$packet->header->tc) {
            my $rcode = $packet->header->rcode;
            return [$packet] if $packet->header->ancount;
            return [undef, $rcode] if $rcode eq 'NXDOMAIN' || $rcode eq 'NOERROR';
        }
    }
    my $reply = $resolver->query($fqdn, 'TXT');
    return [$reply, $reply ? undef : $resolver->errorstring];
}

sub resolver {
    my ($self, $val) = @_;
    $self->{Resolver} = $val if defined $val;
    return $self->{Resolver};
}

sub set_pubkey_callback {
    my ($self, $cb) = @_;
    $self->{PubkeyCallback} = $cb;
}

sub result {
    my $self = shift;
    return $self->{result} || 'none';
}

sub result_detail {
    my $self = shift;
    my $result = $self->result;
    if ($self->{details}) {
        return "$result ($self->{details})";
    }
    return $result;
}

# The DKIM2-Signature fields the message carried, parsed, in ascending i=
# order. Valid once the header block has been read. A host building an
# Authentication-Results field takes header.d and header.i from the top one.
sub signatures {
    my $self = shift;
    my $map = $self->{_dk2_headers} || {};
    return map { $map->{$_}{sig} } sort { $a <=> $b } keys %$map;
}

sub top_signature {
    my $self = shift;
    my @sigs = $self->signatures;
    return @sigs ? $sigs[-1] : undef;
}

# The bare reason for the result, with no result word wrapped around it.
# result_detail() is the display form ("temperror (...)"); callers that embed
# the reason in a report of their own -- an Authentication-Results comment, say
# -- want this one, or they end up saying the result twice.
sub details {
    my $self = shift;
    return $self->{details};
}

# provisionally_verified(): -07 section 13.1. After CLOSE, true when the
# highest i= DKIM2-Signature is correct and the highest m= Message-Instance's
# hashes match the message -- the initial assessment that lets a receiver
# accept a message, and the only kind of message a DSN may be sent for
# (section 16.1). A pass is; otherwise the top signature and the top
# instance are checked on their own, whatever went wrong lower down. A top
# signature with nd=, or one that does not cover the top instance, is not.
# The verdict (result, details, diagnostic) is left as it was.
sub provisionally_verified {
    my ($self) = @_;
    return $self->{_provisional} //= $self->_provisionally_verified ? 1 : 0;
}

sub _provisionally_verified {
    my ($self) = @_;
    return 1 if ($self->{result} // '') eq 'pass';
    return 0 if $self->{_stopped} && !$self->{result};
    my %dk2 = %{ $self->{_dk2_headers} || {} };
    my %mi  = %{ $self->{_mi_headers}  || {} };
    my ($max_i) = sort { $b <=> $a } keys %dk2;
    my ($top_m) = sort { $b <=> $a } keys %mi;
    return 0 unless $max_i && $top_m;
    my $sig = $dk2{$max_i}{sig};
    my $nd  = $sig->next_domain;
    return 0 if defined $nd && length $nd;
    return 0 unless ($sig->version // '') =~ /\A[0-9]+\z/ && $sig->version == $top_m;

    local @{$self}{qw(result details diagnostic)};
    my $sig_ok = eval {
        $self->_check_sig_field($max_i) && $self->_check_sig_time($max_i)
            && $self->_check_sig_keys($max_i) && $self->_check_sig_crypto($max_i);
    };
    die $@ if ref $@;
    return 0 unless $sig_ok;

    (my $value = $mi{$top_m}) =~ s/\A[^:]*:[ \t]*//;
    my $obj = eval { Mail::DKIM2::MessageInstance->parse($value) };
    die $@ if ref $@;
    return 0 unless $obj;

    my ($header_cb, $body_cb);
    if (my $hplan = $self->{_header_plan}) {
        $header_cb = sub { $hplan->header_hash($top_m, $_[0]) // '' };
    } else {
        my $msg = parse_mime(join('', @{$self->{headers}}) . "\r\n");
        $header_cb = sub { Mail::DKIM2::MessageInstance::h_digest($msg, $_[0], $self->{IgnorePrefixes}) };
    }
    if ($self->{HeadersOnly}) {
        $body_cb = undef;
    } elsif (my $plan = $self->{_body_plan}) {
        $plan->finish;
        $body_cb = sub { $plan->body_hash($top_m, $_[0]) // '' };
    } else {
        my $body = $self->{_buf} // '';
        $body_cb = sub { Mail::DKIM2::MessageInstance::body_digest_raw($body, $_[0]) };
    }
    my ($ok) = $obj->_check_hashes($top_m, $header_cb, $body_cb);
    return $ok ? 1 : 0;
}

# More about the reason, for a log, where there is more: the resolver's
# error behind a key that could not be fetched, the copy range behind a
# Recipe that does not undo. Never part of the -07 string in details().
sub diagnostic {
    my $self = shift;
    return $self->{diagnostic};
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Verifier - Verify the DKIM2-Signature chain on a message

=head1 SYNOPSIS

    use Mail::DKIM2::Verifier;

    my $verifier = Mail::DKIM2::Verifier->new->load($message);
    print $verifier->result, "\n";          # pass, fail, none, permerror, temperror
    print $verifier->result_detail, "\n";   # pass (i=1..3 verified)

    # Streaming, with CRLF line endings:
    my $v = Mail::DKIM2::Verifier->new(Resolver => $net_dns_resolver);
    $v->PRINT($chunk) for @chunks;
    $v->CLOSE;

    # For Authentication-Results:
    if (my $top = $v->top_signature) {
        printf "dkim2=%s header.d=%s header.i=%d\n",
            $v->result, $top->domain, $top->sequence;
    }

=head1 DESCRIPTION

Verifies every DKIM2-Signature on a message, not only the outermost: the
chain must be complete (C<i=1> to C<i=N> with no gaps), each signature must
verify over the headers that existed when it was made, consecutive hops must
satisfy the chain-of-custody rules of -07 section 14.4, and the
Message-Instance chain must undo cleanly back to the first instance, each
one matching the content it describes. Past a null body Recipe (the previous
body is gone) only the header history is checked. The outcome is a result and
a reason, never an exception; see C<result> below.

Extends L<Mail::DKIM2::HeaderParser>, which provides C<PRINT>, C<CLOSE>,
C<load> and the tie interface. The Message-Instances are checked first and
the signatures over them second, so no key is needed to refuse a message
whose instances do not describe it. A message with no DKIM2 field at all is
decided from its headers alone and its body is not kept.

This module implements draft-ietf-dkim-dkim2-spec-07; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONSTRUCTOR

=head2 new(%options)

All options are optional. The boolean ones and C<Resolver> also have a
snake_case method of the same name that gets or sets them after
construction; C<PubkeyCallback> has C<set_pubkey_callback>.

=over 4

=item Resolver

A L<Net::DNS::Resolver> (or anything with the same C<query> and
C<errorstring> methods) for the default public-key lookup. Created on
demand if not given. A milter host passes its own so its timeouts apply.

If it also has Net::DNS's C<bgsend>, C<bgbusy> and C<bgread>, every key
the signatures name is asked for at once, in the background, as soon as
the header fields are in, and the answers are read when the signatures
are checked: the lookups overlap each other, the body's arrival and the
hashing. An answer that settles nothing -- none within
C<$Mail::DKIM2::Verifier::PREFETCH_WAIT> seconds (1) of being sent, or
SERVFAIL, or truncated -- is asked again with C<query>, so the verdicts
are those of one C<query> at a time. At most
C<$Mail::DKIM2::Verifier::PREFETCH_MAX> keys (8) are prefetched per
message, the top signature's first; any other key is asked for with
C<query> when it is needed. Not with a C<PubkeyCallback>.

A subclass of L<Net::DNS::Resolver> that overrides C<send> (its own
transport, caching or metrics) but not C<bgsend> gets no prefetch:
Net::DNS's C<bgsend> would bypass that C<send>, and asks only the first
nameserver. Every key is then asked for with C<query>, and so through the
subclass's C<send>. A resolver that provides its own C<bgsend> is used for
the prefetch.

=item PubkeyCallback

A code reference that replaces the DNS lookup. Called as
C<< ($signature, $index, $verifier) >> for each item of each signature's
C<s=> tag; returns a L<Crypt::PK::RSA> or L<Crypt::PK::Ed25519> object,
undef for "no such key", or dies with a string to report a transient
failure. It can fall back to C<< $verifier->fetch_public_key($signature,
$index) >> for keys it does not know.

=item SkipTimestampCheck

Do not fail a signature for the age of its C<t=>. For test fixtures.

=item IgnorePrefixes

An arrayref of header-field-name prefixes an operator's own border adds
and strips, excluded from the header hash. Anything but undef or an
arrayref croaks. See L<Mail::DKIM2/Operator-local header fields>.

=item AllowUnsignedMI

Permit a Message-Instance with a higher C<m=> than any signature covers,
which -07 section 14.2 otherwise makes a permerror ("is not signed"). For an outbound path
that verifies the message it is about to sign, where the new instance
legitimately exists before its signature does. Never set it on inbound
mail.

=item NextDomainOK

An outbound signer's own C<d=>. A top signature carrying C<nd=> is then
accepted when C<nd=> equals it (case-insensitive), and refused with
"PERMERROR: not signing: top signature nd=X names another domain"
otherwise. Unset, a
top C<nd=> is the usual permerror.

=item MidProcess

The verifier is looking at a partial view of the chain, with higher
signatures stripped (as the validator does walking the chain top-down), so
the highest remaining signature is not the true top and the checks that
apply only to the top are suppressed. Implies C<AllowUnsignedMI>.

=item InstancesOnly

Check the shape of the chain and the Message-Instances, and stop: for a
caller that has had the signatures verified already. No key is fetched, an
instance no signature covers is allowed, and the result is C<pass>
(details C<"Message-Instance m=1..N intact">) when the instances match the
message, C<none> when there are none.

=item StreamBody

On (the default): hash every Message-Instance's body as the body arrives,
in one pass (L<Mail::DKIM2::BodyPlan>), and every header hash from the
fields as received (L<Mail::DKIM2::HeaderPlan>); the body is never held
and no previous version of the message is rebuilt. Off (C<0>): keep the
body and undo each instance in turn. The verdicts, and their words, are
the same.

=item HeadersOnly

The message has no body, as with the returned original in a DSN's
C<text/rfc822-headers> part (-07 section 16.3). Signatures and the
chain are checked as usual; of the Message-Instance content check, only
the top instance's header hash can be, so only that is.

=back

An option not listed here croaks.

=head1 METHODS

=head2 PRINT($bytes), CLOSE(), load($input)

Feed the message; see L<Mail::DKIM2::HeaderParser>.

=head2 result()

One of the -07 section 14.1 states, in lower case:

=over 4

=item C<pass>

Every signature verified, the chain is complete and consistent, the
Message-Instance chain undoes cleanly, and every From is Authentic.

=item C<fail>

A hash or signature was not correct: a signature did not verify, or a
Message-Instance does not match the content it describes.

=item C<none>

No DKIM2-Signature header fields. With no Message-Instance either; or,
under C<AllowUnsignedMI> or C<MidProcess>, with Message-Instances that
match the message (one that does not is the C<fail> or C<permerror> the
walk found). Otherwise a Message-Instance with no signature is "is not
signed", a C<permerror>.

=item C<permerror>

The message is malformed or not Validly Signed in a way no retry will fix:
a missing or malformed field or tag, a gap in the chain, a broken Chain of
Custody, a timestamp too old or too far ahead, an unusable or absent key, a
Recipe that is not valid JSON or does not undo, a From that is not
Authentic, and the local limits (too many fields, a repeated number, a key
too short, no algorithm this verifier implements).

=item C<temperror>

A public key could not be fetched for a transient reason. Retry later.

=back

Before C<CLOSE> this is C<none>.

=head2 details()

The reason, with no result word wrapped around it; undef when there is
none. For any result but C<pass> and C<none> it is the -07 human-readable
string, state included, e.g. C<"PERMERROR: DKIM2-Signature i=2 d= does not
match the rt= of i=1"> or C<"FAIL: Message-Instance m=1 body hash sha256
mismatch"> (sections 14.2 to 14.8). A check -07 has no string for keeps
its own words, with the C<PERMERROR: > prefix. For C<pass> it is
C<"i=1..N verified">, and for C<none> C<"no DKIM2-Signature headers
found">. Use this when embedding the reason in something that already
states the result, such as an Authentication-Results comment.

=head2 diagnostic()

More about the reason, for a log, when there is more; undef otherwise:
the resolver's error behind C<TEMPERROR: ... could not be fetched>, the
copy range behind a Recipe that does not undo. Never part of C<details>.
New in 0.23 (0.22 appended the resolver's error to the key-fetch reason).

=head2 provisionally_verified()

After C<CLOSE>: true when the message is Provisionally Verified (-07
section 13.1) -- the highest C<i=> DKIM2-Signature is correct and the
highest C<m=> Message-Instance matches the message -- whatever else went
wrong. A receiver may accept such a message and decide later; a DSN may
only be sent for one (section 16.1, L<Mail::DKIM2::DSN>). A C<pass> is
always Provisionally Verified; a top signature with C<nd=>, or one that does
not cover the top instance, never is. Leaves C<result>, C<details> and
C<diagnostic> as they were. New in 0.23.

=head2 result_detail()

C<result> and C<details> together, e.g. C<"pass (i=1..3 verified)">.

=head2 signatures()

The DKIM2-Signature headers the message carried, as
L<Mail::DKIM2::Signature> objects in ascending C<i=> order.

=head2 top_signature()

The highest-C<i=> signature, or undef. Its C<domain> and C<sequence> are
C<header.d> and C<header.i> for Authentication-Results.

=head2 fetch_public_key($signature, $index)

The default key source: a TXT lookup of
C<< <selector>._domainkey.<d=> >> through the C<Resolver> (the answer to
the background lookup sent at the end of the headers, if there was one; see
C<Resolver>). Each name is looked up once per message. Returns a key
object, undef when the answer positively says there is no such record
(NXDOMAIN, NOERROR or NODATA), and dies with a C<TEMPERROR:> message for
anything else, including a resolver error string it has never seen. The
verifier maps that die to C<temperror>: -07 section 13 makes a DNS
failure retryable, never a C<fail>, which would read as a forged
signature.

A record that is present but unusable dies with C<PERMERROR: E<lt>whyE<gt>>,
which the verifier reports as C<permerror> naming the selector (-07
section 14.5): C<has multiple records> (more than one TXT RR; several
strings in one RR are joined), C<has a syntax error> and C<has been
revoked> (see L<Mail::DKIM2::Common/parse_dkim_key_record>), or
C<algorithm mismatch> (a C<k=> that is not the signature algorithm's).

=head2 resolver([$resolver]), set_pubkey_callback(\&cb), skip_timestamp_check([$bool]), allow_unsigned_mi([$bool]), next_domain_ok([$domain]), mid_process([$bool]), headers_only([$bool]), instances_only([$bool]), stream_body([$bool])

Get or set the constructor options of the same names.

=head1 VERIFICATION PROCESS

=over 4

=item 1.

B<Shape.> At most 32 Message-Instance and 32 DKIM2-Signature fields, every
DKIM2-Signature parses with an C<i=> that is a positive integer (one that
does not is never skipped: "PERMERROR: DKIM2-Signature has a missing or
malformed i= tag"), every C<i=> and C<m=> a chain number (1*DIGIT, at
most three digits naming 1 to 100, and no more than 32; C<01> is 1), no
C<i=> or C<m=> twice, and no Message-Instance above
the highest signed C<m=>. Any of these is a C<permerror> decided from the headers alone,
before any key is fetched. A tag repeated within one signature, in any
case, is a syntax error found when that signature is checked.

=item 2.

B<Chain completeness.> C<i=1> to C<i=N> with no gaps; likewise C<m=1> to
the highest instance, or the highest a signature covers.

=item 3.

B<Content.> Each Message-Instance's tags and Recipe, by ascending C<m=>.
Then the top Message-Instance must match the message; its Recipe is applied
and the next instance down checked against the result, back to C<m=1>;
past an instance with a null body Recipe the walk continues over the
header history only. All of this comes before any signature is looked at,
so a message whose instances do not describe it is refused without a key
being fetched, and a hash that does not match is the error reported
whatever is wrong with the signatures.

=item 4.

B<Each signature.> Its tags (C<i=>, C<m=>, C<t=>, C<d=>, C<s=>, and either
C<nd=> or both C<mf=> and C<rt=>), its timestamp (no more than 14 days
before now, no more than a day after), then its signature: the signing input for C<i=K> is the canonicalized
Message-Instance headers up to the C<m=> it names, the DKIM2-Signature
headers below it, and itself with an empty C<s=> value, in that order
(-07 section 12.8). Every item in C<s=> whose algorithm is known and
whose key can be fetched is checked and must verify; an item whose key is absent is
skipped if another item verifies.

=item 5.

B<Chain of custody> (-07 section 7.1). After an C<nd=> hop, the next
C<d=> must be the C<nd=> domain. Otherwise an C<nd=> hop, or one with a
null C<mf=>, must have its C<d=> the same as or above a C<rt=> domain of
the hop before; any other hop its C<mf=> domain the same as or below one.
Every non-null C<mf=> must be the same as or below its own C<d=>. Domains
are compared as A-labels; a domain literal never matches.

=item 6.

B<From> (-07 section 11). The From at C<m=1> must be Authentic for
C<i=1>, and a From changed at C<m=k> for the lowest C<i=> whose C<m=> is
C<k> or more: one From field, one mailbox, its domain the same as or below
C<d=>.

=back

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
