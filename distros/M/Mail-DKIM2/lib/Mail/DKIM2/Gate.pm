package Mail::DKIM2::Gate;
use strict;
use warnings;

our $VERSION = '0.18';

use Email::MIME;
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
string (CRLF line endings) and returns a hashref. Options:
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
signatures are not verified again.

The upstream DKIM2-Signatures are verified with a Verifier that allows an
unsigned Message-Instance above the top signature (the one the caller is about
to sign), and the Message-Instance chain must match the content and undo
cleanly down to m=1, including the header history below a null body Recipe.

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
    my $own_walk = 0;
    if (!defined $verify_result) {
        if ($has_dk2) {
            my $v = Mail::DKIM2::Verifier->new(
                SkipTimestampCheck => $o{SkipTimestampCheck} ? 1 : 0,
                ($o{PubkeyCallback} ? (PubkeyCallback => $o{PubkeyCallback}) : ()),
                ($o{Resolver} ? (Resolver => $o{Resolver}) : ()),
                ($o{IgnorePrefixes} ? (IgnorePrefixes => $o{IgnorePrefixes}) : ()));
            $v->allow_unsigned_mi(1);
            $v->next_domain_ok($sd) if defined $sd && length $sd;
            $v->PRINT($message);
            $v->CLOSE();
            $verify_result = $v->result_detail();
            $own_walk = 1;
        } else {
            $verify_result = 'none';
        }
    }

    # Our own Verifier run that ended in 'pass' has already walked the whole
    # Message-Instance chain (Verifier::_verify_mi_chain, run in finish_body
    # only on that path; we never set HeadersOnly or mid_process).  That walk
    # is the same one chain_verifies does: same verify() per instance with
    # the same IgnorePrefixes, the same undo(), the same switch to a
    # header-only walk below a null-body Recipe, and the same up-front
    # _chain_error check (verify() makes it on the first iteration).
    # allow_unsigned_mi only suppresses the "MI m= not signed" PERMERROR
    # earlier in finish_body; it does not change the walk.  So a 'pass'
    # means chain_verifies would succeed, and walking again is wasted work.
    # Without signatures, with a caller-supplied VerifyResult, or on any
    # non-pass result the walk was not (fully) done, so run it here.
    my ($chain_ok, $chain_why) = (1, undef);
    unless ($own_walk && $verify_result =~ /^pass/) {
        ($chain_ok, $chain_why) = Mail::DKIM2::MessageInstance->chain_verifies($message,
            ($o{IgnorePrefixes} ? (IgnorePrefixes => $o{IgnorePrefixes}) : ()));
    }

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
    # covers instances 1..k (spec-06 §8.2), so the highest m= of any of them
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
