package Mail::DKIM2::Gate;
use strict;
use warnings;

our $VERSION = '0.27';

use Email::MIME;
use Scalar::Util qw(blessed);
use Mail::DKIM2::HeaderParser;
use Mail::DKIM2::Common qw(extract_mi_version parse_mime valid_sequence chain_number_error);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Verifier;

=head1 NAME

Mail::DKIM2::Gate - decide whether a front end may sign a message

=head1 SYNOPSIS

    my $g = Mail::DKIM2::Gate->check($message,
        PubkeyCallback => $cb, SkipTimestampCheck => 0,
        AllowNullBodyRecipe => 0);
    unless ($g->{ok}) { warn "not signing: $g->{message}" }

=head1 DESCRIPTION

The gate shared by C<bin/dkim2sign>, C<bin/dkim2-milter> and the
authentication_milter handler
L<Mail::Milter::Authentication::Handler::DKIM2Sign>. Mail::DKIM2::Signer
checks only what it needs to sign -- it refuses a chain it cannot number (a
DKIM2-Signature with no usable C<i=>, an C<i=> or C<m=> above
C<MAX_CHAIN_LENGTH>, a duplicate) but does not verify the upstream
signatures or the Message-Instance chain. A front end that extends a DKIM2
chain should first make sure the chain is worth extending, which is what this
module decides.

=head2 check

C<< Mail::DKIM2::Gate->check($message, %opts) >> takes the whole message as a
string (CRLF line endings) or a filehandle (or an object with C<getline>),
and returns a hashref. A filehandle is read a piece at a time, its body
going straight into the Verifier, so the message is never held whole.
Options:
C<PubkeyCallback>, C<Resolver> and C<SkipTimestampCheck> are passed to the
Verifier, C<IgnorePrefixes> to both the Verifier and the Message-Instance
chain check (the caller's own header fields, hashed by neither end),
C<AllowNullBodyRecipe> permits an I<unsigned> Message-Instance whose body
Recipe is null (see L</Null body Recipes>),
C<SigningDomain> is the C<d=> the caller will sign with: when the top
upstream signature carries C<nd=> the gate passes only if it equals that
domain (case-insensitive) and refuses otherwise ("top signature nd=X names
another domain"); without it a top C<nd=> is refused as before.
C<VerifyResult> supplies an already-computed verifier result so the upstream
signatures are not verified again; the Message-Instance chain still is.

The upstream DKIM2-Signatures are verified with a Verifier that allows an
unsigned Message-Instance above the top signature (the one the caller is about
to sign), and the Message-Instance chain must match the content and undo
cleanly down to m=1, including the header history below a null body Recipe.
Every From the signed instances have had must be Authentic (-07 section
11); a From changed in an instance no upstream signature covers is not
checked here but by L<Mail::DKIM2::Signer>, against the C<d=> it signs with.

The result has C<ok> (true to sign), C<verify_result> (C<none> without a
DKIM2-Signature), C<has_chain>, C<top_null> (the top Message-Instance has a
null body Recipe), C<covered_m> (the highest C<m=> of any DKIM2-Signature
with a valid, positive-integer C<i=>, or 0: those instances, 1 to
C<covered_m>, are signed upstream; a signature without a valid C<i=> never
counts, and the Verifier reports it as a C<permerror>), C<top_signed> (the
top Message-Instance is among them), C<unsigned_null> (the C<m=> of the
highest Message-Instance above C<covered_m> with a null body Recipe -- the
top or one under it -- or 0) and, when refusing, C<reason>
(C<upstream-chain>, C<broken-mi-chain> or C<null-body-recipe>) and a
human-readable C<message>. C<top_signed>, C<covered_m> and C<unsigned_null>
are new in 0.16; C<top_null> is as in 0.15.

=head2 Null body Recipes

A null body Recipe (C<"b": null>) says the previous body cannot be recreated.
A DKIM2-Signature with C<m=k> covers Message-Instances 1 to I<k>, so every
instance above the highest C<m=> of the valid upstream signatures is
unsigned: whoever signs next is the first to vouch for it. The gate refuses
(C<null-body-recipe>) when any of those unsigned instances has a null body
Recipe -- the top one, or one with another unsigned instance added over it.
That is a null I<this> hop is introducing, typically a list manager that
rewrote the body and added an unsigned instance for the outbound signer to
sign. Signing it is the host's choice, made with C<AllowNullBodyRecipe>.

A null that already arrived signed (a list host's post, forwarded unchanged,
whether or not a later hop added an ordinary instance over it) was declared
and signed by the upstream domain; the gate extends it without the option.
Either way the upstream signatures must verify and the header history below
the null must check out.

=cut

# True for a filehandle, as HeaderParser::load tells one from a string.
sub _is_handle {
    my ($input) = @_;
    return 1 if ref $input eq 'GLOB' || ref \$input eq 'GLOB';
    return 0 unless blessed $input;
    my $can = eval { $input->can('getline') };
    die $@ if ref $@;
    return $can ? 1 : 0;
}

# True when the highest-i= DKIM2-Signature among @$sigs carries nd=. Uses the
# parsed signature, so FWS around "=" (allowed by the tag-list syntax) is seen.
sub _top_has_nd {
    my ($sigs) = @_;
    my ($best, $top_nd) = (-1, 0);
    for my $raw (@$sigs) {
        (my $v = $raw) =~ s/^\s+//;
        my $sig = eval { Mail::DKIM2::Signature->parse($v) };
        die $@ if ref $@;
        next unless $sig;
        my $i = $sig->sequence;
        next unless valid_sequence($i) && $i > $best;
        my $nd = $sig->next_domain;
        ($best, $top_nd) = ($i, (defined $nd && length $nd) ? 1 : 0);
    }
    return $top_nd;
}

sub check {
    my ($class, $message, %o) = @_;
    Mail::DKIM2::Common::_check_options("$class->check", \%o,
        qw(SigningDomain AllowNullBodyRecipe SkipTimestampCheck IgnorePrefixes
           PubkeyCallback Resolver VerifyResult));

    # A filehandle is read a piece at a time: the header fields here, the body
    # straight into the Verifier below, so the message is never held whole.
    my $fh = _is_handle($message) ? $message : undef;
    if ($fh) {
        my $head = '';
        Mail::DKIM2::HeaderParser::_read_handle($fh, sub { $head .= $_[0]; 1 }, 1);
        $message = $head;
    }
    my $msg = parse_mime($message);
    my @sigs = $msg->header_raw('DKIM2-Signature');
    my @mis  = $msg->header_raw('Message-Instance');
    my $has_dk2 = @sigs ? 1 : 0;

    # nd= bridge: a top signature with nd= may be extended only by the domain
    # it names. A caller-supplied VerifyResult came from a plain verifier that
    # refuses any top nd=, so recompute it when we know our own d=.
    my $sd = $o{SigningDomain};
    my $verify_result = $o{VerifyResult};
    $verify_result = undef
        if defined $sd && length $sd && $has_dk2 && _top_has_nd(\@sigs);
    # One Verifier, the body streamed through it. It walks the
    # Message-Instance chain before it looks at a signature, so with no
    # signature, or with the signatures verified already (VerifyResult), it
    # is run for the walk alone; with neither signature nor instance there is
    # nothing to walk. A walk that fails under the signatures is an
    # upstream-chain refusal below; on its own it is broken-mi-chain.
    my ($chain_ok, $chain_why) = (1, undef);
    my $instances_only = defined $verify_result || !$has_dk2;
    if ($has_dk2 || @mis) {
        my $v = Mail::DKIM2::Verifier->new(
            SkipTimestampCheck => $o{SkipTimestampCheck} ? 1 : 0,
            InstancesOnly      => $instances_only ? 1 : 0,
            ($o{PubkeyCallback} ? (PubkeyCallback => $o{PubkeyCallback}) : ()),
            ($o{Resolver} ? (Resolver => $o{Resolver}) : ()),
            ($o{IgnorePrefixes} ? (IgnorePrefixes => $o{IgnorePrefixes}) : ()));
        $v->allow_unsigned_mi(1);
        $v->next_domain_ok($sd) if defined $sd && length $sd;
        $v->PRINT($message);
        Mail::DKIM2::HeaderParser::_read_handle($fh,
            sub { $v->PRINT($_[0]); !$v->stopped }) if $fh;
        $v->CLOSE();
        if ($instances_only) {
            ($chain_ok, $chain_why) = (0, $v->details)
                unless $v->result =~ /\A(?:pass|none)\z/;
        } else {
            $verify_result = $v->result_detail();
        }
    }
    $verify_result //= 'none';

    my %by_v;
    for my $val (@mis) {
        (my $x = $val) =~ s/^\s+//;
        $by_v{extract_mi_version($x) // 0} = $x;
    }
    my ($top) = sort { $b <=> $a } keys %by_v;
    my %null = map { $_ => 1 } grep {
        my $v = $_;
        my $null = $v && eval { Mail::DKIM2::MessageInstance->parse($by_v{$v})->unrecoverable };
        die $@ if ref $@;
        $null;
    } keys %by_v;
    my $top_null = ($top && $null{$top}) ? 1 : 0;
    # How far up the upstream signatures reach: a DKIM2-Signature with m=k
    # covers instances 1..k (-07 §10.2), so the highest m= of any of them
    # is the top covered instance, and every instance above it is unsigned --
    # this hop will be the first to vouch for it. Only a signature with a
    # valid i= counts: one the Verifier cannot key is a PERMERROR there (so
    # the upstream-chain check below refuses anyway), and is never coverage
    # here even if a caller-supplied VerifyResult said "pass".
    my $covered = 0;
    for my $raw (@sigs) {
        (my $v = $raw) =~ s/^\s+//;
        my $sig = eval { Mail::DKIM2::Signature->parse($v) };
        die $@ if ref $@;
        next unless $sig;
        next unless valid_sequence($sig->sequence);
        my $m = $sig->version // next;
        next if chain_number_error('DKIM2-Signature', 'm', $m);
        $covered = 0 + $m if $m > $covered;
    }
    my $top_signed = ($top && $top <= $covered) ? 1 : 0;
    # The highest unsigned instance with a null body Recipe, the top's own or
    # one under another unsigned instance: a null nobody upstream signed.
    my ($unsigned_null) = sort { $b <=> $a } grep { $_ > $covered } keys %null;
    $unsigned_null //= 0;

    my %r = (ok => 0, verify_result => $verify_result,
             has_chain => $has_dk2, top_null => $top_null,
             top_signed => $top_signed, covered_m => $covered,
             unsigned_null => $unsigned_null);
    if ($has_dk2 && $verify_result !~ /^pass/) {
        @r{qw(reason message)} = ('upstream-chain',
            "upstream DKIM2 chain result=$verify_result");
    } elsif (!$chain_ok) {
        @r{qw(reason message)} = ('broken-mi-chain',
            "Message-Instance chain does not undo cleanly: $chain_why");
    } elsif ($unsigned_null && !$o{AllowNullBodyRecipe}) {
        my $where = $unsigned_null == $top ? 'top ' : '';
        @r{qw(reason message)} = ('null-body-recipe',
            "unsigned ${where}Message-Instance m=$unsigned_null has a null body "
            . 'Recipe (AllowNullBodyRecipe not set)');
    } else {
        $r{ok} = 1;
    }
    return \%r;
}

1;
