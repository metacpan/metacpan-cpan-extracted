package Mail::DKIM2::Address;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.33';

use Encode ();

use Exporter 'import';
our @EXPORT_OK = qw(
    extract_domain
    to_rfc5321_path
    domain_of
    to_alabel
    from_domain
    from_mailbox
    from_authentic
    from_refusal_note
    relaxed_domain_match
    parent_from_matcher
    from_pair_error
);

# Extract the domain from an email address (handles <user@domain> and
# user@domain). Deprecated: domain_of is the one the library uses -- it
# lowercases, drops a trailing dot and knows a domain literal.
sub extract_domain {
    my ($addr) = @_;
    return unless $addr;
    $addr =~ s/^.*<//;
    $addr =~ s/>.*$//;
    return unless $addr =~ /\@(.+)$/;
    return $1;
}

# Wrap an address as an RFC5321 reverse-/forward-path for mf=/rt= (-09
# sections 10.5, 10.6): angle brackets MUST be present. Empty/undef -> "<>"; an
# already-bracketed value (incl. "<>") is returned unchanged.
sub to_rfc5321_path {
    my ($addr) = @_;
    return '<>' unless defined $addr && length $addr;
    return $addr if $addr =~ /^<.*>$/s;
    return "<$addr>";
}

# domain_of($addr): the domain of an address or path, as ($domain,
# $is_literal), or the empty list when there is none (no "@", or "<>").
# The text between the last "@" and the closing ">" (or the end),
# lowercased, with one trailing dot taken off: Postfix hands on
# "<A@Example.COM.>" as it was given. A domain literal ("[192.0.2.1]") is
# returned with $is_literal true; it never matches anything (-09 section
# 7.2).
sub domain_of {
    my ($addr) = @_;
    return unless defined $addr;
    my $at = rindex($addr, '@');
    return if $at < 0;
    my $dom = substr($addr, $at + 1);
    $dom =~ s/>.*\z//s;
    $dom =~ s/\A\s+|\s+\z//g;
    $dom =~ tr/A-Z/a-z/;    # ASCII only: the octets may be UTF-8
    $dom =~ s/\.\z//;
    return unless length $dom;
    return ($dom, $dom =~ /\A\[/ ? 1 : 0);
}

# to_alabel($domain): $domain with each label that is not ASCII lowercased
# and written as its A-label, "xn--" and the RFC 3492 Punycode of the label
# (-09 section 18). ASCII labels are left as they are. The input is UTF-8
# octets, as a header field or a decoded mf=/rt= carries it (a character
# string is taken as it is); a label that is not valid UTF-8 is left alone.
# This is the label mapping only, not UTS 46.
sub to_alabel {
    my ($domain) = @_;
    return $domain unless defined $domain && $domain =~ /[^\x00-\x7F]/;
    require URI::_punycode;
    return join '.', map {
        my $label = $_;
        if ($label =~ /[^\x00-\x7F]/) {
            my $chars = utf8::is_utf8($label) ? $label
                : eval { Encode::decode('UTF-8', $label, Encode::FB_CROAK() | Encode::LEAVE_SRC()) };
            die $@ if ref $@;
            $label = 'xn--' . URI::_punycode::encode_punycode(lc $chars) if defined $chars;
        }
        $label;
    } split /\./, $domain, -1;
}

# from_domain(@values): the domain a From header field is Authentic for
# (-09 section 11), from the values of every From field in one version of
# the header (each as header_raw gives it, folded or not): the lowercased
# A-label domain of its one mailbox, or undef when there is none -- no From
# field or more than one, a field that is not exactly one mailbox (a list
# of them, a group), no "@", or a domain literal. Lenient otherwise: the
# display name, quoted or RFC 2047 encoded, and comments are skipped; the
# mailbox is "Name <addr>" or a bare addr-spec ("Name addr", display text
# with no angle brackets, is not one).
sub from_domain {
    my ($state, $dom) = from_mailbox(@_);
    return $state eq 'ok' ? $dom : undef;
}

# The longest From field value read for its mailbox, in octets with the
# line breaks of folding and the white space around it left out; a longer
# one is not one mailbox. Every implementation in the interop repository
# has this limit.
our $MAX_FROM_LENGTH = 2048;

sub _from_length {
    my ($v) = @_;
    utf8::encode($v) if utf8::is_utf8($v);
    $v =~ tr/\r\n//d;
    $v =~ s/\A[ \t]+//;
    $v =~ s/[ \t]+\z//;
    return length $v;
}

# from_mailbox(@values): from_domain's reading of the From field(s), with the
# reason when there is no domain (-09 section 14.8 names them): ('ok',
# $domain); ('multiple') for more than one mailbox -- two From fields, or a
# list of addresses; ('literal') for a domain literal; ('none') for no From
# field, or a value that is not one mailbox (a group, no "@", bad syntax,
# or longer than $MAX_FROM_LENGTH).
sub from_mailbox {
    my (@values) = @_;
    return 'multiple' if @values > 1;
    return 'none' unless @values == 1 && defined $values[0];
    return 'none' if _from_length($values[0]) > $MAX_FROM_LENGTH;
    (my $v = $values[0]) =~ s/\r?\n(?=[ \t])//g;
    # One pass: comments dropped, quoted strings kept whole, and the
    # structure outside them ($skel) and the angle brackets found.
    my ($out, $skel, $depth, $inq, $inlit, @lt, @gt) = ('', '', 0, 0, 0);
    for (my $i = 0; $i < length $v; $i++) {
        my $c = substr($v, $i, 1);
        # A domain literal's ":"s (IPv6) are not a group: "[...]" is kept
        # whole, out of the structure.
        if ($inlit) {
            if ($c eq '\\') { $out .= substr($v, $i++, 2); next }
            $inlit = 0 if $c eq ']';
            $out .= $c;
            next;
        }
        if ($inq) {
            if ($c eq '\\') { $out .= substr($v, $i++, 2); next }
            $inq = 0 if $c eq '"';
            $out .= $c;
            next;
        }
        if ($depth) {
            if    ($c eq '\\') { $i++ }
            elsif ($c eq '(')  { $depth++ }
            elsif ($c eq ')')  { $depth-- }
            next;
        }
        if ($c eq '(') { $depth = 1; $out .= ' '; next }
        if ($c eq '"') { $inq = 1; $out .= $c; next }
        if ($c eq '[') { $inlit = 1; $out .= $c; next }
        push @lt, length $out if $c eq '<';
        push @gt, length $out if $c eq '>';
        $skel .= $c;
        $out  .= $c;
    }
    return 'none' if $inq || $depth || $inlit;
    # A "," is a second mailbox; a ":" or ";" a group (or an obsolete route).
    return 'multiple' if $skel =~ /,/;
    return 'none' if $skel =~ /[:;]/;
    my $addr = $out;
    if (@lt || @gt) {
        return 'none' unless @lt == 1 && @gt == 1 && $lt[0] < $gt[0]
                          && substr($out, $gt[0] + 1) !~ /\S/;
        $addr = substr($out, $lt[0] + 1, $gt[0] - $lt[0] - 1);
    }
    $addr =~ s/\A\s+|\s+\z//g;
    # White space (or a comment) between two parts of the address: "Name
    # a@b", display text with no angle brackets, is not one mailbox.
    return 'none' if ($addr =~ s/"(?:[^"\\]|\\.)*"/""/gr) =~ /\s/;
    return 'none' unless index($addr, '@') > 0;
    my ($dom, $literal) = domain_of($addr);
    return 'none' if !$dom || $dom =~ /\s/;
    return 'literal' if $literal;
    return ('ok', to_alabel($dom) =~ tr/A-Z/a-z/r);
}

# from_authentic($d, @values): true if the From field(s) of one version of
# the header, as from_domain takes them, are Authentic for signing domain
# $d: from_domain gives a domain and it relaxed-matches $d (-09 section 11).
sub from_authentic {
    my ($d, @values) = @_;
    my $dom = from_domain(@values);
    return defined $dom && relaxed_domain_match($dom, $d) ? 1 : 0;
}

# from_refusal_note($d, @values): for the log of a signer's From refusal,
# the From domain against the signing domain $d, with what to do about it
# (final review I3): a DKIM2 list rewrites From to its posting address, and
# a milter signing with a domain that is not that one's, or above it,
# refuses every post.
sub from_refusal_note {
    my ($d, @values) = @_;
    my $from = from_domain(@values);
    unless (defined $from) {
        if (@values == 1 && defined $values[0]) {
            (my $text = $values[0]) =~ s/[\r\n]+/ /g;
            $text =~ s/\A\s+|\s+\z//g;
            $from = '(not one mailbox: ' . substr($text, 0, 100) . ')';
        } else {
            $from = '(' . scalar(@values) . ' From fields)';
        }
    }
    return "From domain $from is not d=" . ($d // '(none)') . " or below it: a DKIM2 "
         . "list's posting address must be in the domain this milter signs with";
}

# relaxed_domain_match($p1, $p2): the relaxed domain match of -09 section
# 7.2. Both are compared as A-labels, without regard to case, and without
# one trailing dot. A domain literal on either side never matches. Otherwise
# labels come off the LEFT of $p1 only, until it equals $p2 (a match) or
# has no dot left (no match): so $p1 may be $p2 or below it, never above.
sub relaxed_domain_match {
    my ($p1, $p2) = @_;
    return 0 unless defined $p1 && defined $p2 && length $p1 && length $p2;
    ($p1, $p2) = map { my $d = to_alabel($_) =~ tr/A-Z/a-z/r; $d =~ s/\.\z//; $d } $p1, $p2;
    return 0 if $p1 =~ /\A\[/ || $p2 =~ /\A\[/;
    while (1) {
        return 1 if $p1 eq $p2;
        $p1 =~ s/\A[^.]*\.// or return 0;
    }
}

# parent_from_matcher(@domains): a Signer ParentFromCallback (-09 contract
# E3.4) that is true for a From domain in @domains, each compared as the
# callback gets it: an A-label, lowercased, without one trailing dot.
sub parent_from_matcher {
    my %ok = map { (to_alabel($_) =~ tr/A-Z/a-z/r) =~ s/\.\z//r => 1 }
             grep { defined && length } @_;
    return sub { $ok{ $_[0] // '' } ? 1 : 0 };
}

# from_pair_error($d, $policy, @from): -09 section 14.8 for one signing
# domain $d and the From field values it must make Authentic (contract
# E3.1), for the Verifier and the Signer alike: undef when Authentic, else
# [$state, $text] -- 'fail', 'permerror' or 'temperror', and the text after
# "DKIM2-Signature i=<x> ". $policy->($domain) gives that domain's Domain
# Policy Record as domain_policy does, or 'temperror'; it is called only
# when d= is below the From domain.
sub from_pair_error {
    my ($d, $policy, @from) = @_;
    my ($state, $dom) = from_mailbox(@from);
    return ['fail', 'From has more than one address'] if $state eq 'multiple';
    return ['fail', 'From uses a domain literal']     if $state eq 'literal';
    return ['fail', 'matching From is not authentic']
        unless $state eq 'ok' && defined $d && length $d;
    return undef if relaxed_domain_match($dom, $d);
    return ['fail', 'matching From is not authentic'] unless relaxed_domain_match($d, $dom);
    my $p = $policy->($dom);
    return undef if $p eq 'open';
    return ['fail', "From $dom forbids subdomain signing"] if $p eq 'strict';
    return ['permerror', "multiple records for $dom policy"] if $p eq 'multiple';
    return ['temperror', "policy for $dom unavailable"];
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Address - Envelope paths, domains and the From header field for DKIM2

=head1 SYNOPSIS

    use Mail::DKIM2::Address qw(domain_of relaxed_domain_match from_authentic);

    my ($domain) = domain_of('<bounce@lists.example.com>');       # lists.example.com
    relaxed_domain_match('lists.example.com', 'example.com');     # true
    from_authentic('example.com', 'Alice <alice@example.com>');   # true

=head1 DESCRIPTION

Addresses as DKIM2 reads them: the domain of an RFC 5321 path, A-labels
(-09 section 18), the relaxed domain match (section 7.2), and whether a
From header field is Authentic for a signing domain (sections 11 and
14.8). Nothing is exported by default; L<Mail::DKIM2::Common> exports
these too, as it did before they moved here in 0.31.

See L<Mail::DKIM2/CONVENTIONS> for the conventions every module follows.

=head1 FUNCTIONS

=head2 extract_domain($address)

The domain of C<user@domain> or C<< <user@domain> >>, or undef, exactly as
written. B<Deprecated> in 0.31 and to be removed: use
L</domain_of($address)>, which lowercases the domain, drops a trailing dot
and reports a domain literal.

=head2 to_rfc5321_path($address)

Wraps an address in angle brackets if it has none; undef or empty becomes
C<< <> >>. The form C<mf=> and C<rt=> carry.

=head2 domain_of($address)

The domain of an address or RFC 5321 path, as C<($domain, $is_literal)>:
the text between the last C<@> and the closing C<< > >>, lowercased, with
one trailing dot removed (C<< <A@Example.COM.> >> gives C<example.com>).
C<$is_literal> is true for a domain literal such as C<[192.0.2.1]>. The
empty list when there is no domain, as for C<< <> >>. New in 0.23.

=head2 to_alabel($domain)

The domain with each non-ASCII label lowercased and written as its A-label
(C<xn--> and the RFC 3492 Punycode), as -09 section 18 has mf=, rt= and
From domains compared: C<b\x{fc}cher.example>, as UTF-8 octets, gives
C<xn--bcher-kva.example>. ASCII labels are unchanged; a label that is not
valid UTF-8 is left as it is. No UTS 46 mapping. New in 0.23.

=head2 from_domain(@values)

The domain a From header field is Authentic for (-09 section 11), given the
values of every From field in one version of the header: the lowercased
A-label domain of its one mailbox, or undef when there is no From field,
more than one, a field holding other than exactly one mailbox (a list, a
group), or a domain literal. Display names (quoted or RFC 2047) and
comments are skipped; C<< Name <addr> >> and a bare C<addr> both work. New in
0.23.

=head2 from_mailbox(@values)

C<from_domain>'s reading with the reason when there is no domain, as -09
section 14.8 names them (new in 0.29): C<('ok', $domain)>; C<('multiple')>
for more than one mailbox (two From fields, or a list of addresses);
C<('literal')> for a domain literal; C<('none')> for no From field or a
value that is not one mailbox (a group, no C<@>, bad syntax, or, from
0.33, longer than C<$Mail::DKIM2::Address::MAX_FROM_LENGTH>, 2048 octets
without the line breaks of folding and the white space round the value).

=head2 from_authentic($d, @values)

True if C<from_domain(@values)> gives a domain and it relaxed-matches the
signing domain C<$d>: the "downwards" match only, with no DNS lookup, which
is what the signers use (-09 section 12.4 permits a subdomain C<d=> too,
when the From domain's Domain Policy Record allows it; the Verifier checks
that). New in 0.23.

=head2 from_refusal_note($d, @values)

For the log of a signer that refused a From not Authentic for C<$d>: a line
naming the From domain (as L</from_domain> finds it, or what is wrong with
the field) and C<$d>, and saying that a DKIM2 list's posting address must be
in the domain the milter signs with. Both milters log it. New in 0.23.

=head2 relaxed_domain_match($p1, $p2)

The relaxed domain match of -09 section 7.2: true if C<$p1> is C<$p2> or a
subdomain of it. Labels come off the left of C<$p1> only. Both are compared
as A-labels (C<to_alabel>), without regard to case and without a trailing
dot. A domain literal on either side never matches (new in 0.23).

=head2 from_pair_error($d, $policy, @from_values)

-09 section 14.8 for one signing domain and the From field values it must
make Authentic (new in 0.29; the Verifier and the Signer share it): undef
when Authentic, else C<[$state, $text]>, the state C<fail>, C<permerror> or
C<temperror> and the text that follows C<< DKIM2-Signature i=<x> >>.
C<< $policy->($domain) >> returns that domain's Domain Policy Record as
L</domain_policy> does, or C<temperror>; it is called only when C<$d> is
below the From domain.

=head2 parent_from_matcher(@domains)

A L<Mail::DKIM2::Signer> C<ParentFromCallback> that is true for a From
domain in C<@domains>, each compared as the callback receives it: an
A-label (so C<bücher.example> matches C<xn--bcher-kva.example>), lowercased,
without one trailing dot. The milters and C<dkim2sign> build theirs with it.
New in 0.30.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
