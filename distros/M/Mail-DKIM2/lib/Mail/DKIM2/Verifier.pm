package Mail::DKIM2::Verifier;
use strict;
use warnings;

our $VERSION = '0.13';

use base 'Mail::DKIM2::HeaderParser';
use Crypt::Digest::SHA256 qw(sha256);
use MIME::Base64 qw(encode_base64 decode_base64);
use Carp;
use POSIX qw();

use Mail::DKIM2::Common qw(
    parse_mime
    dkim2_canonicalize_header
    decode_tag_json
    encode_tag_json
    build_signing_input
    extract_mi_version
    extract_domain
    relaxed_domain_match
    check_ignore_prefixes
    MAX_CHAIN_LENGTH
    chain_length_error
    duplicate_number_error
);
use Email::MIME;
use Mail::DKIM2::Signature;
use Mail::DKIM2::MessageInstance;

sub _extract_mi_hash_sets {
    my ($raw) = @_;
    $raw =~ s/^[^:]+://;        # strip "Message-Instance:" field name
    $raw =~ s/\r?\n[ \t]/ /g;   # unfold continuation lines
    return [] unless $raw =~ /\bh=([^;]*)/;
    return Mail::DKIM2::MessageInstance::parse_hash_sets($1);
}

sub known_options {
    return qw(SkipTimestampCheck AllowUnsignedMI MidProcess HeadersOnly
              PubkeyCallback Resolver IgnorePrefixes);
}

sub init {
    my $self = shift;
    $self->SUPER::init;
    $self->{_mi_headers}         = {};
    $self->{_dk2_headers}        = {};
    $self->{_chain_counts}       = {};
    $self->{result}              = undef;
    $self->{details}             = undef;
    # Options the constructor was given stay; the rest get their defaults.
    $self->{$_} //= 0 for qw(SkipTimestampCheck MidProcess AllowUnsignedMI HeadersOnly);
    check_ignore_prefixes($self->{IgnorePrefixes});
}

sub skip_timestamp_check {
    my ($self, $val) = @_;
    $self->{SkipTimestampCheck} = $val if defined $val;
    return $self->{SkipTimestampCheck};
}

# allow_unsigned_mi: permit a Message-Instance whose m= is higher than any
# DKIM2-Signature's m=, which spec-06 §11 otherwise makes a PERMERROR (see
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
# original in a DSN's text/rfc822-headers part (spec-06 §12.1.2). Signatures
# and the chain are checked as usual; of the Message-Instance content check,
# only the header hash of the top instance can be, so only that is.
sub headers_only {
    my ($self, $val) = @_;
    $self->{HeadersOnly} = $val if defined $val;
    return $self->{HeadersOnly};
}

sub handle_header {
    my ($self, $field_name, $contents, $line) = @_;

    my $lc_name = lc $field_name;
    if ($lc_name eq 'message-instance' || $lc_name eq 'dkim2-signature') {
        return if ++$self->{_chain_counts}{$lc_name} > MAX_CHAIN_LENGTH;
    }

    if ($lc_name eq 'message-instance') {
        eval {
            my $v = extract_mi_version($contents);
            if ($v) {
                push @{$self->{_numbers}{'message-instance'}}, $v;
                $self->{_mi_headers}{$v} = $line || "$field_name:$contents";
            }
            1;
        } or do {
            die $@ if ref $@;
            $self->{_mi_parse_error} = $@;
        };
    }
    elsif ($lc_name eq 'dkim2-signature') {
        eval {
            my $sig = Mail::DKIM2::Signature->parse($contents);
            if ($sig && $sig->sequence) {
                push @{$self->{_numbers}{'dkim2-signature'}}, $sig->sequence;
                $self->{_dk2_headers}{$sig->sequence + 0} = {
                    raw => $line || "$field_name:$contents",
                    sig => $sig,
                };
            }
            1;
        } or do {
            die $@ if ref $@;
            $self->{_dk2_parse_error} = $@;
        };
    }
}

# Verification happens in finish_body, unless the header fields alone already
# decide the result.
sub finish_header {
    my $self = shift;
    my $numbers = $self->{_numbers};
    my $error = chain_length_error($self->{_chain_counts})
        // duplicate_number_error('Message-Instance', 'm',
               @{$numbers->{'message-instance'} || []})
        // duplicate_number_error('DKIM2-Signature', 'i',
               @{$numbers->{'dkim2-signature'} || []});
    if ($error) {
        $self->{result}  = 'permerror';
        $self->{details} = $error;
        $self->stop;
        return;
    }

    # With no signature the verdict is already known -- 'none', or the
    # unsigned-instance PERMERROR -- and finish_body reaches it before it
    # looks at the body, so do not keep one. Most mail carries no DKIM2 at
    # all, and a verifier run on every message would otherwise hold a copy
    # of each.
    unless (%{$self->{_dk2_headers}}) {
        $self->finish_body;
        $self->stop;
    }
}

sub finish_body {
    my $self = shift;

    my %mi_map  = %{$self->{_mi_headers}};
    my %dk2_map = %{$self->{_dk2_headers}};

    # spec-06 §11: "As a special case, there MUST NOT be a Message-Instance
    # field with a higher m= value than occurs in any DKIM2-Signature field",
    # reported as "PERMERROR Message-Instance m=<x> is not signed".
    #
    # An unsigned Message-Instance records hashes that nothing vouches for, so
    # accepting one lets a hop assert an instance with no accountability --
    # which is the whole thing DKIM2 exists to prevent. This must run BEFORE
    # the no-signatures 'none' return below, or a message carrying only an MI
    # reads as "no DKIM2 here" instead of as malformed.
    #
    # Suppressed by allow_unsigned_mi (an outbound signer holds the new MI
    # before its signature exists) and by mid_process (a partial chain view
    # keeps every MI while higher signatures are stripped).
    unless ($self->{AllowUnsignedMI} || $self->{MidProcess}) {
        if (keys %mi_map) {
            my ($top_mi) = sort { $b <=> $a } keys %mi_map;
            my ($top_signed) = sort { $b <=> $a }
                               grep { defined }
                               map  { $_->{sig} ? $_->{sig}->version : undef }
                               values %dk2_map;
            if (!defined $top_signed || $top_mi > $top_signed) {
                $self->{result}  = 'permerror';
                $self->{details} = "PERMERROR Message-Instance m=$top_mi is not signed";
                return;
            }
        }
    }

    unless (keys %dk2_map) {
        $self->{result} = 'none';
        $self->{details} = 'no DKIM2-Signature headers found';
        return;
    }

    # spec-06 §7.3: reject a Message-Instance whose h= names the same
    # algorithm twice, before any DNS lookup or crypto work. Checked against
    # the LIST of hash-sets (via _extract_mi_hash_sets/parse_hash_sets), not
    # a hash keyed by algorithm, since a hash would let a later occurrence
    # silently overwrite an earlier one and hide the duplicate. Matching is
    # case-insensitive (parse_hash_sets already lowercases algorithm names).
    for my $v (sort keys %mi_map) {
        my $sets = _extract_mi_hash_sets($mi_map{$v});
        my %seen;
        for my $s (@$sets) {
            if ($seen{$s->[0]}++) {
                $self->{result}  = 'permerror';
                $self->{details} = "PERMERROR Message-Instance m=$v has a duplicate hash algorithm";
                return;
            }
        }
    }

    my $max_i = (sort { $b <=> $a } keys %dk2_map)[0];
    my $dk2_entry = $dk2_map{$max_i};
    my $signature = $dk2_entry->{sig};

    # Local policy (stricter than spec-06 §"Check the Chain of Custody"): the
    # highest-numbered DKIM2-Signature MUST NOT carry nd=. The only legitimate
    # nd= producer is reflector-brand-nd, which always emits the matching
    # higher-i= signature too, so nd= never appears on top.
    #
    # Only valid for a FINAL, whole-message verification: $max_i here is the
    # top of whatever chain view this Verifier was fed. During a partial/
    # mid-chain verify (mid_process set, e.g. by Validate.pm's per-level
    # sub-verify after stripping higher signatures) that "top" is not the
    # real top of the chain, so this rejection must be suppressed.
    if (!$self->{MidProcess}
        && defined $signature->next_domain && length $signature->next_domain) {
        $self->{result}  = 'permerror';
        $self->{details} = "DKIM2-Signature i=$max_i unexpected nd= tag";
        return;
    }

    # Validate chain completeness - check for gaps
    for my $i (1..$max_i) {
        unless ($dk2_map{$i}) {
            $self->{result} = 'fail';
            $self->{details} = "missing DKIM2-Signature i=$i";
            return;
        }
    }

    # Check MI completeness and coverage if there are MI headers
    if (keys %mi_map) {
        my $max_v = (sort { $b <=> $a } keys %mi_map)[0];
        for my $v (1..$max_v) {
            unless ($mi_map{$v}) {
                $self->{result} = 'fail';
                $self->{details} = "missing Message-Instance m=$v";
                return;
            }
        }
        # The other direction: a signature claiming to cover an instance that
        # is not present. The completeness loop above only walks up to the
        # topmost MI that EXISTS, so it cannot see this.
        #
        # The reverse case -- an MI above the top signature -- is spec-06 §11's
        # "is not signed" PERMERROR, checked at the top of finish_body, because
        # it must also fire when there are no signatures at all.
        my $top_sig = $dk2_map{$max_i}{sig};
        my $top_m   = $top_sig->version || 0;
        if ($top_m > $max_v) {
            $self->{result} = 'fail';
            $self->{details} =
                "top signature i=$max_i covers m=$top_m but no Message-Instance m=$top_m exists";
            return;
        }
    }

    # Verify ALL signatures in the chain, from i=1 to max_i
    for my $i (1..$max_i) {
        my $result = $self->_verify_signature($i);
        return unless $result;
    }

    # Check Chain of Custody between consecutive signatures
    if ($max_i > 1) {
        my $chain_result = $self->_verify_chain();
        return unless $chain_result;
    }

    # §10.8: Check donotmodify and donotexplode requests
    for my $i (1..$max_i) {
        my $sig   = $dk2_map{$i}{sig};
        my $flags = $sig->flags // [];

        if (grep { $_ eq 'donotmodify' } @$flags) {
            my $m = $sig->version || 0;
            if ($m >= 1 && $mi_map{$m} && $mi_map{$m + 1}) {
                # spec-06 §3.4/§7.3: an MI may carry several hash-sets. Only
                # compare hash-sets whose algorithm we implement; if the two
                # instances share none, we cannot tell whether the message
                # changed and fail closed rather than silently accept.
                my %by_alg_m  = map { $_->[0] => $_ } @{ _extract_mi_hash_sets($mi_map{$m}) };
                my %by_alg_m1 = map { $_->[0] => $_ } @{ _extract_mi_hash_sets($mi_map{$m + 1}) };
                my $impl = Mail::DKIM2::MessageInstance::hash_algs();
                my @common = grep { $by_alg_m{$_} && $by_alg_m1{$_} && $impl->{$_} }
                             keys %by_alg_m;

                unless (@common) {
                    $self->{result}  = 'permerror';
                    $self->{details} = "Message-Instance m=$m no supported hash algorithm";
                    return;
                }

                for my $alg (@common) {
                    my (undef, $hh_m,  $bh_m)  = @{ $by_alg_m{$alg}  };
                    my (undef, $hh_m1, $bh_m1) = @{ $by_alg_m1{$alg} };
                    if ($hh_m ne $hh_m1 || $bh_m ne $bh_m1) {
                        $self->{result}  = 'fail';
                        $self->{details} = 'Message modified despite donotmodify request at i=' . $i;
                        return;
                    }
                }
            }
        }

        if (grep { $_ eq 'donotexplode' } @$flags) {
            for my $j ($i + 1 .. $max_i) {
                my $later_flags = $dk2_map{$j}{sig}->flags // [];
                if (grep { $_ eq 'exploded' } @$later_flags) {
                    $self->{result}  = 'fail';
                    $self->{details} = 'Message exploded despite donotexplode request at i=' . $i;
                    return;
                }
            }
        }
    }

    # §10.7: the cryptographic chain proves the MI headers are authentic, but
    # NOT that the current body/headers still match them. Walk the MI chain:
    # verify the top instance against the current content, then undo each
    # instance and verify the reconstructed content against the next one down,
    # until m=1 or an instance that declares the previous state unrecoverable.
    #
    # MessageInstance::parse() dies (rather than returning an error) on a
    # malformed r= payload -- e.g. the §11.2 invalid-JSON PERMERROR -- so
    # this must run under eval or that die would propagate uncaught out of
    # finish_body() and crash the caller instead of yielding a clean
    # permerror result.
    my $mi_chain_ok = eval {
        $self->{HeadersOnly} ? $self->_verify_top_mi_headers() : $self->_verify_mi_chain()
    };
    if (my $err = $@) {
        die $err if ref $err;
        chomp $err;
        $self->{result}  = ($err =~ /^PERMERROR/) ? 'permerror' : 'fail';
        $self->{details} = $err;
        return;
    }
    return unless $mi_chain_ok;

    $self->{result} = 'pass';
    $self->{details} = "i=1..$max_i verified";
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
    unless (@usable) {
        $self->{result}  = 'permerror';
        $self->{details} = "Message-Instance m=$num no supported hash algorithm";
        return 0;
    }
    for my $alg (@usable) {
        my $want = $hashes->{$alg}[0];
        my $have = Mail::DKIM2::MessageInstance::h_digest($msg, $alg, $self->{IgnorePrefixes});
        next if $want eq $have;
        $self->{result}  = 'fail';
        $self->{details} = "Message-Instance m=$num header hash mismatch ($alg)";
        return 0;
    }
    return 1;
}

sub _verify_mi_chain {
    my ($self) = @_;

    my $raw = join('', @{$self->{headers}}) . "\r\n" . ($self->{_buf} // '');
    my $msg = parse_mime($raw);

    while (1) {
        my @mi = $msg->header_raw('Message-Instance');
        my %by_v = map { (extract_mi_version($_) // 0) => $_ } @mi;
        my $num = %by_v ? (sort { $b <=> $a } keys %by_v)[0] : 0;
        last unless $num;

        my ($ok, $err) = Mail::DKIM2::MessageInstance->verify($msg,
            IgnorePrefixes => $self->{IgnorePrefixes});
        unless ($ok) {
            # A malformed instance is a PERMERROR in its own words (§11.2
            # names the strings); a hash that does not match is a fail.
            if (($err // '') =~ /^PERMERROR/) {
                $self->{result}  = 'permerror';
                $self->{details} = $err;
                return 0;
            }
            $self->{result}  = 'fail';
            $self->{details} = "Message-Instance m=$num does not match content"
                             . ($err ? " ($err)" : '');
            return 0;
        }

        last if $num <= 1;

        # If this instance declares the previous state non-recreatable, the
        # chain cannot (and need not) be undone further — accept what verified.
        my $mi_obj = Mail::DKIM2::MessageInstance->parse($by_v{$num});
        last if $mi_obj->unrecoverable;

        my $prev = eval { Mail::DKIM2::MessageInstance->undo($msg) };
        die $@ if ref $@;
        if ($@ || !$prev) {
            $self->{result}  = 'fail';
            $self->{details} = "Message-Instance m=$num did not undo cleanly"
                             . ($@ ? ": $@" : '');
            return 0;
        }
        $msg = $prev;
    }

    return 1;
}

sub _verify_signature {
    my ($self, $i) = @_;

    my %mi_map  = %{$self->{_mi_headers}};
    my %dk2_map = %{$self->{_dk2_headers}};
    my $dk2_entry = $dk2_map{$i};
    my $signature = $dk2_entry->{sig};

    # §8: "there MUST be only one of each kind" of tag.
    if (my $dup = $signature->duplicate_tag) {
        $self->{result}  = 'permerror';
        $self->{details} = "DKIM2-Signature i=$i duplicate tag $dup not permitted (spec 8)";
        return 0;
    }

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

    # draft-06: every DKIM2-Signature MUST carry i=, m=, t=, d=, s=. Checked
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
        unless ($present) {
            $self->{result}  = 'permerror';
            $self->{details} = "DKIM2-Signature i=$i tag=$t missing";
            return 0;
        }
    }

    # spec-06 §8.9: reject a duplicate Selector, or the same algorithm 3+
    # times, within this signature's s= tag -- before any DNS lookup or
    # crypto work.
    if (my @dup_errors = $signature->check_duplicates) {
        $self->{result}  = 'permerror';
        $self->{details} = $dup_errors[0];
        return 0;
    }

    # draft-06 §8: a signature carries either nd= or both mf= and rt=, never
    # both forms. nd= together with mf=/rt= is a PERMERROR.
    my $nd_tag = $signature->get_tag('nd');
    my $mf_tag = $signature->get_tag('mf');
    my $rt_tag = $signature->get_tag('rt');
    if (defined $nd_tag && (defined $mf_tag || defined $rt_tag)) {
        $self->{result}  = 'permerror';
        $self->{details} = "DKIM2-Signature i=$i tag=nd was unexpected";
        return 0;
    }
    if (!defined $nd_tag && !(defined $mf_tag && defined $rt_tag)) {
        $self->{result}  = 'permerror';
        $self->{details} = "DKIM2-Signature i=$i tag=mf missing";
        return 0;
    }

    # §8.3 SHOULD: n= nonce must not exceed 64 characters
    my $nonce = $signature->get_tag('n');
    if (defined $nonce && length($nonce) > 64) {
        $self->{result}  = 'fail';
        $self->{details} = "n= nonce exceeds 64 characters at i=$i";
        return 0;
    }

    # §10.3 SHOULD: reject signatures more than 14 days old or in the future
    unless ($self->{SkipTimestampCheck}) {
        my $ts = $signature->timestamp;
        if (defined $ts && $ts > 0) {
            my $now = time();
            if ($ts > $now + 300) {
                $self->{result}  = 'fail';
                $self->{details} = "DKIM2-Signature i=$i timestamp is in the future";
                return 0;
            }
            if ($now > $ts + 14 * 24 * 3600) {
                $self->{result}  = 'fail';
                $self->{details} = "DKIM2-Signature i=$i has expired (age > 14 days)";
                return 0;
            }
        }
    }

    # Spec §7.5/§7.6: mf= and each rt= MUST be a bracketed RFC5321 path.
    my $mf_raw = $signature->mail_from;
    if (defined $mf_raw && length $mf_raw && $mf_raw !~ /^<.*>$/s) {
        $self->{result}  = 'fail';
        $self->{details} = "mf= is not a bracketed RFC5321 reverse-path at i=$i (spec 7.5)";
        return 0;
    }
    my $rt_raw = $signature->rcpt_to;
    if ($rt_raw) {
        for my $r (@$rt_raw) {
            next if defined $r && $r =~ /^<.*>$/s;
            $self->{result}  = 'fail';
            $self->{details} = "rt= entry is not a bracketed RFC5321 forward-path at i=$i (spec 7.6)";
            return 0;
        }
    }

    # Validate d= matches mf= domain (skip for null sender / DSN)
    my $mf = $signature->mail_from;
    my $sig_domain = $signature->domain;
    if ($mf && $mf ne '<>') {
        my $mf_domain = extract_domain($mf);
        unless ($mf_domain && relaxed_domain_match($mf_domain, $sig_domain)) {
            $self->{result} = 'fail';
            $self->{details} = "DKIM2-Signature i=$i MAIL FROM and d= do not match";
            return 0;
        }
    }

    # Verify all signature items we support
    my $sig_count = $signature->sig_count;
    unless ($sig_count) {
        $self->{result} = 'fail';
        $self->{details} = 'no signature items in s= tag';
        return 0;
    }

    my $verified_any = 0;
    for my $idx (0 .. $sig_count - 1) {
        my $sig_b64 = $signature->signature_value($idx);
        next unless $sig_b64;

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
        unless ($fetched) {
            die $@ if ref $@;
            # A transient DNS failure is a TEMPERROR per spec-06 §10 —
            # retryable, not a permanent "no verifiable signature items", and
            # emphatically not a 'fail', which reads as a forged signature.
            my $sel = $signature->selector($idx) // '?';
            # Drop croak's " at FILE line N." tail: this reason is reported in
            # Authentication-Results on mail we send out, and our source paths
            # are nobody else's business.
            (my $why = $@) =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*\z//;
            $why =~ s/\s+\z//;
            $self->{result}  = 'temperror';
            $self->{details} = "DKIM2-Signature i=$i public key $sel could not be fetched ($why)";
            return 0;
        }

        unless ($pubkey) {
            # Can't fetch key for this algorithm — skip it
            next;
        }

        my $alg = $signature->algorithm($idx) || 'unknown';

        # §3.2: RSA keys MUST be at least 1024 bits; reject shorter keys
        # (permerror) rather than trusting a weak signature.
        if ($alg !~ /^ed25519/ && $pubkey->can('size')) {
            my $bits = $pubkey->size * 8;
            if ($bits < 1024) {
                $self->{result}  = 'permerror';
                $self->{details} = "DKIM2-Signature i=$i RSA key too short ($bits bits < 1024, spec 3.2)";
                return 0;
            }
        }

        my $sig_raw = decode_base64($sig_b64);
        my $verified = eval {
            if ($alg =~ /^ed25519/) {
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
            $self->{result} = 'fail';
            $self->{details} = "signature verification error for sig item $idx ($alg): $@";
            return 0;
        }
        unless ($verified) {
            $self->{result} = 'fail';
            $self->{details} = "signature verification failed for $alg at i=$i";
            return 0;
        }

        $verified_any = 1;
    }

    unless ($verified_any) {
        $self->{result} = 'permerror';
        $self->{details} = "no verifiable signature items at i=$i";
        return 0;
    }

    return 1;
}

sub _verify_chain {
    my ($self) = @_;
    my %dk2_map = %{$self->{_dk2_headers}};
    my @dk2_is = sort { $a <=> $b } keys %dk2_map;

    for my $idx (1..$#dk2_is) {
        my $cur_i = $dk2_is[$idx];
        my $prev_i = $dk2_is[$idx - 1];
        my $cur_sig = $dk2_map{$cur_i}{sig};
        my $prev_sig = $dk2_map{$prev_i}{sig};

        # draft-06 §11.4: an nd= hop declares the domain that signs the next
        # signature; nd= MUST exactly match that signature's d=.
        my $prev_nd = $prev_sig->next_domain;
        if (defined $prev_nd && length $prev_nd) {
            my $cur_d = $cur_sig->domain // '';
            unless (lc($prev_nd) eq lc($cur_d)) {
                $self->{result} = 'fail';
                $self->{details} = "DKIM2-Signature i=$prev_i MAIL nd= does not match";
                return 0;
            }
            next;
        }

        my $prev_rt = $prev_sig->rcpt_to;
        unless ($prev_rt) {
            $self->{result} = 'fail';
            $self->{details} = "DKIM2-Signature i=$prev_i RCPT TO <> did not match";
            return 0;
        }
        my @prev_rts = ref($prev_rt) eq 'ARRAY' ? @$prev_rt : ($prev_rt);

        # draft-06 §9.3: an nd= hop after a real one is a Forwarder bridging
        # the gap between the domain it received the message at and the
        # domain it sends from, and it has to be made with a key for a
        # domain in the RCPT TO the message arrived with. So what has to
        # match the previous rt= here is the hop's d=, since it has no mf=.
        my $cur_nd = $cur_sig->next_domain;
        if (defined $cur_nd && length $cur_nd) {
            my $cur_d = $cur_sig->domain // '';
            unless (grep { relaxed_domain_match($cur_d, extract_domain($_)) } @prev_rts) {
                $self->{result} = 'fail';
                $self->{details} = "DKIM2-Signature i=$cur_i nd= hop d=$cur_d did not match RCPT TO";
                return 0;
            }
            next;
        }

        my $cur_mf = $cur_sig->mail_from;

        # Chain of Custody: mf of N must relaxed-domain-match an rt of N-1
        unless ($cur_mf) {
            $self->{result} = 'fail';
            $self->{details} = "DKIM2-Signature i=$cur_i MAIL FROM <> did not match";
            return 0;
        }

        my $cur_mf_domain = extract_domain($cur_mf);
        my $match = 0;
        for my $rt (@prev_rts) {
            my $rt_domain = extract_domain($rt);
            if (relaxed_domain_match($cur_mf_domain, $rt_domain)) {
                $match = 1;
                last;
            }
        }
        unless ($match) {
            $self->{result} = 'fail';
            $self->{details} = "DKIM2-Signature i=$cur_i MAIL FROM $cur_mf did not match";
            return 0;
        }
    }

    return 1;
}

# --- Public key lookup ---

# fetch_public_key($signature, $idx): the default key source, a TXT lookup of
# <selector>._domainkey.<d=> through the Resolver option (a Net::DNS::Resolver
# or anything with the same query/errorstring interface; one is made if none
# was given). Returns a Crypt::PK object, or undef when the answer positively
# says there is no such record. Anything else -- a timeout, SERVFAIL, REFUSED,
# a network error, or an errorstring this code has never seen -- dies with a
# TEMPERROR: spec-06 §10 makes a DNS failure retryable, never a permanent "no
# verifiable signature items", and emphatically never a 'fail', which reads as
# a forged signature. _verify_signature's eval maps the die to temperror.
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

    my $resolver = $self->{Resolver} //= do {
        require Net::DNS::Resolver;
        Net::DNS::Resolver->new;
    };
    my $fqdn = "$sel._domainkey.$dom";
    my $reply = $resolver->query($fqdn, 'TXT');
    unless ($reply) {
        my $err = $resolver->errorstring // '';
        return if $err =~ /^(?:NXDOMAIN|NOERROR|NODATA)\s*$/i;
        croak "TEMPERROR: DNS lookup for $fqdn failed: $err";
    }
    for my $rr ($reply->answer) {
        next unless $rr->type eq 'TXT';
        return Mail::DKIM2::Common::parse_dkim_pubkey(join('', $rr->txtdata));
    }
    return;
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
satisfy the chain-of-custody rules of spec-06 section 11.4, and the
Message-Instance chain must undo cleanly back to the first instance, each
one matching the content it describes. The outcome is a result and a reason,
never an exception; see C<result> below.

Extends L<Mail::DKIM2::HeaderParser>, which provides C<PRINT>, C<CLOSE>,
C<load> and the tie interface. A message with no DKIM2-Signature is decided
from its headers alone and its body is not kept.

This module implements draft-ietf-dkim-dkim2-spec-06; see L<Mail::DKIM2/STATUS>
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
which spec-06 section 11 otherwise makes a permerror. For an outbound path
that verifies the message it is about to sign, where the new instance
legitimately exists before its signature does. Never set it on inbound
mail.

=item MidProcess

The verifier is looking at a partial view of the chain, with higher
signatures stripped (as the validator does walking the chain top-down), so
the highest remaining signature is not the true top and the checks that
apply only to the top are suppressed. Implies C<AllowUnsignedMI>.

=item HeadersOnly

The message has no body, as with the returned original in a DSN's
C<text/rfc822-headers> part (spec-06 section 12.1.2). Signatures and the
chain are checked as usual; of the Message-Instance content check, only
the top instance's header hash can be, so only that is.

=back

An option not listed here croaks.

=head1 METHODS

=head2 PRINT($bytes), CLOSE(), load($input)

Feed the message; see L<Mail::DKIM2::HeaderParser>.

=head2 result()

One of:

=over 4

=item C<pass>

Every signature verified, the chain is complete and consistent, and the
Message-Instance chain undoes cleanly.

=item C<fail>

A signature did not verify, the chain has a gap or a chain-of-custody
mismatch, a Message-Instance does not match the content, or a Recipe did
not undo.

=item C<none>

No DKIM2-Signature headers.

=item C<permerror>

The message is malformed in a way no retry will fix: too many fields, a
repeated number, a duplicate tag, an unsigned Message-Instance, a
required tag missing, a Message-Instance whose hash sets do not parse, a
key too short.

=item C<temperror>

A public key could not be fetched for a transient reason. Retry later.

=back

Before C<CLOSE> this is C<none>.

=head2 details()

The reason, with no result word wrapped around it, e.g. C<"i=1..3
verified"> or C<"missing DKIM2-Signature i=2">; undef when there is none.
Use this when embedding the reason in something that already states the
result, such as an Authentication-Results comment.

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
C<< <selector>._domainkey.<d=> >> through the C<Resolver>. Returns a key
object, undef when the answer positively says there is no such record
(NXDOMAIN, NOERROR or NODATA), and dies with a C<TEMPERROR:> message for
anything else, including a resolver error string it has never seen. The
verifier maps that die to C<temperror>: spec-06 section 10 makes a DNS
failure retryable, never a C<fail>, which would read as a forged
signature.

=head2 resolver([$resolver]), set_pubkey_callback(\&cb), skip_timestamp_check([$bool]), allow_unsigned_mi([$bool]), mid_process([$bool]), headers_only([$bool])

Get or set the constructor options of the same names.

=head1 VERIFICATION PROCESS

=over 4

=item 1.

B<Shape.> At most 32 Message-Instance and 32 DKIM2-Signature fields, no
C<i=> or C<m=> twice, and no Message-Instance above the highest signed
C<m=>. Any of these is a C<permerror> decided from the headers alone,
before any key is fetched. A tag repeated within one signature is a
C<permerror> found when that signature is checked.

=item 2.

B<Chain completeness.> C<i=1> to C<i=N> with no gaps; likewise C<m=1> to
the highest instance.

=item 3.

B<Each signature.> The signing input for C<i=K> is the canonicalized
Message-Instance headers up to the C<m=> it names, the DKIM2-Signature
headers below it, and itself with an empty C<s=> value, in that order
(spec-06 section 8.5). Every item in C<s=> whose algorithm is known and
whose key can be fetched must verify; an item whose key is absent is
skipped if another item verifies.

=item 4.

B<Chain of custody.> For consecutive hops, the C<mf=> domain of C<i=K>
must be the same as or below a C<rt=> domain of C<i=K-1>; an C<nd=> hop
instead names the C<d=> of the hop that follows (spec-06 sections 9.3 and
11.4).

=item 5.

B<Flags.> A hop that changed the message after a C<donotmodify>, or
exploded it after a C<donotexplode>, is a C<fail>.

=item 6.

B<Content.> The top Message-Instance must match the message; its Recipe
is applied and the next instance down checked against the result, back to
C<m=1> or an instance that declares the previous state unrecoverable.

=back

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
