package Mail::DKIM2::Common;
use 5.20.0;
use strict;
use warnings;

our $VERSION = '0.34';

use Email::MIME;
use Email::MIME::ContentType ();

# Everything that lived here before 0.31 and now has a module of its own is
# imported, so Mail::DKIM2::Common::fold_header(...) and
# "use Mail::DKIM2::Common qw(fold_header)" go on working.
use Mail::DKIM2::Address qw(
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
use Mail::DKIM2::Canon qw(
    check_ignore_prefixes
    should_skip
    field_name
    header_values
    dkim2_canonicalize_header
    dkim2_canonicalize_sig_header
    build_signing_input
);
use Mail::DKIM2::Fold qw(
    fold_header
);
use Mail::DKIM2::Key qw(
    signature_algorithm
    signature_algorithm_for_key
    load_private_key
    load_private_key_data
    parse_dkim_pubkey
    parse_dkim_key_record
    key_records
    domain_policy
    query_domain_policy
    policy_from_source
);
use Mail::DKIM2::RecipeJSON qw(
    encode_tag_json
    decode_tag_json
);

# Every eval in the library rethrows a reference: the library only ever dies
# with strings, so an object is the host's, typically a milter or MTA
# signalling a timeout, and swallowing it would let the caller run on past
# its deadline (Mail::DKIM2's CONVENTIONS).

use Exporter 'import';
our @EXPORT_OK = qw(
    should_skip
    split_any_all
    combine_sets
    parse_mime
    check_ignore_prefixes
    dkim2_canonicalize_header
    dkim2_canonicalize_sig_header
    field_name
    header_values
    encode_tag_json
    decode_tag_json
    fold_header
    build_signing_input
    extract_mi_version
    mi_version_tag
    strip_mi_versions
    extract_domain
    domain_of
    to_alabel
    from_domain
    from_mailbox
    from_authentic
    from_refusal_note
    to_rfc5321_path
    relaxed_domain_match
    parse_dkim_pubkey
    parse_dkim_key_record
    key_records
    domain_policy
    load_private_key
    load_private_key_data
    signature_algorithm
    signature_algorithm_for_key
    DKIM2_DRAFT
    DKIM2_REPO
    DKIM2_DATE
    MAX_CHAIN_LENGTH
    MAX_CHAIN_NUMBER
    MAX_SIGNATURE_ITEMS
    FUTURE_LIMIT
    EXPIRY
    chain_length_error
    valid_sequence
    UNKEYABLE_SIGNATURE_ERROR
    MI_MISSING_M_ERROR
    unkeyable_signature_error
    chain_number_error
    duplicate_number_error
    parent_from_matcher
    from_pair_error
    query_domain_policy
    policy_from_source
);

# Provenance emitted in X-DKIM2-Info headers by the milter, the reflector, and
# the mailman/sympa handlers. This is the single source of truth for the Perl
# implementation. DKIM2_DRAFT is the spec revision implemented; DKIM2_DATE is
# the date this implementation's DKIM2 behaviour last changed (a software
# version stamp, not the draft's date) -- bump it on any change to what we
# emit, not only on a spec bump. See ../spec/draft-gondwana-dkim2-debug-header.
use constant DKIM2_DRAFT => 'ietf-dkim-dkim2-spec-09';
use constant DKIM2_REPO  => 'github.com/dkim2wg/interop';
use constant DKIM2_DATE  => '2026-11-03';

# -09 section 14.3: a DKIM2-Signature whose t= is more than a day after
# delivery is "from the future", and one made more than 14 days before it
# has "expired". Seconds.
use constant FUTURE_LIMIT => 86400;
use constant EXPIRY       => 14 * 86400;

# Local policy, not the draft's: a message carrying more Message-Instance or
# DKIM2-Signature fields than this is a PERMERROR, found before any key is
# fetched, signature checked or recipe applied. Every hop costs a verifier a
# DNS lookup, a signature check and an undo of the whole message, and the
# sender chooses how many hops there are.
use constant MAX_CHAIN_LENGTH => 32;

# The largest number a DKIM2-Signature i= or m=, or a Message-Instance m=, may
# be written as: at most two ASCII digits naming 1..99. Anything else is
# malformed before it is ever compared with MAX_CHAIN_LENGTH, and is never
# converted to a number big enough to be a loop bound.
use constant MAX_CHAIN_NUMBER => 99;

# Local policy, not the draft's: the most items one DKIM2-Signature's s= may
# carry. The draft sets no limit (-08 dropped it), and every item may cost a key lookup and a
# signature check, so a crafted s= of thousands of selectors would cost
# thousands of each (the -08 contract, D3). The same limit as the key
# prefetch's; refused before any key is fetched.
use constant MAX_SIGNATURE_ITEMS => 8;

# The PERMERROR for a message over MAX_CHAIN_LENGTH, or undef. Takes an
# Email::MIME, or a hashref of field counts keyed by lower-cased name for a
# caller counting as it parses.
sub chain_length_error {
    my ($msg) = @_;
    for my $field ('Message-Instance', 'DKIM2-Signature') {
        my $count = ref($msg) eq 'HASH'
                  ? ($msg->{lc $field} // 0)
                  : scalar(my @values = $msg->header_raw($field));
        return "PERMERROR: more than " . MAX_CHAIN_LENGTH . " $field fields"
            if $count > MAX_CHAIN_LENGTH;
    }
    return;
}

# A DKIM2-Signature's i= must be a positive integer (ASCII digits) for the
# signature to be placed in the chain and keyed. One that is not -- no i=,
# i=, i=0, i=abc, or a header that does not parse -- is a PERMERROR, never
# silently skipped: a signer gate that counts which instances are signed by
# m= must not be fooled by a junk signature naming an m=.
# The -07 C6 forms: a missing i= is "i= tag=i missing" (there is no number
# to name the field by); one that is not a positive integer is named as
# written, "i=<value> syntax error" (unkeyable_signature_error).
use constant UNKEYABLE_SIGNATURE_ERROR =>
    'PERMERROR: DKIM2-Signature i= tag=i missing';

# The same for a Message-Instance with no m= tag: nothing to name it by.
use constant MI_MISSING_M_ERROR =>
    'PERMERROR: Message-Instance m= tag=m missing';

# The PERMERROR for a DKIM2-Signature header value that no verifier can
# key: UNKEYABLE_SIGNATURE_ERROR without an i= tag, else "PERMERROR:
# DKIM2-Signature i=<as written> syntax error".
sub unkeyable_signature_error {
    my ($contents) = @_;
    my $i = _raw_tag($contents, 'i');
    return defined $i ? "PERMERROR: DKIM2-Signature i=$i syntax error"
                      : UNKEYABLE_SIGNATURE_ERROR;
}

# The raw value of a tag in a header value (whitespace removed), or undef.
sub _raw_tag {
    my ($header, $tag) = @_;
    return unless defined $header;
    for my $part (split /;/, $header) {
        next unless $part =~ /\A\s*\Q$tag\E\s*=(.*)\z/si;    # tag names are case insignificant
        (my $v = $1) =~ s/\s//g;
        return $v;
    }
    return;
}

sub valid_sequence {
    my ($i) = @_;
    return (defined $i && $i =~ /\A[0-9]+\z/ && $i > 0) ? 1 : 0;
}

# The PERMERROR for an i= or m= value that is not a chain number, or undef
# (also undef for a missing value, which is left to the callers). A value must
# be 1*DIGIT in ASCII -- "4294967297x" is malformed, never its digit prefix --
# with at most two digits naming 1..MAX_CHAIN_NUMBER, so "01" is 1; and since
# each number names one hop, no more than MAX_CHAIN_LENGTH.
# Checking this before anything walks 1..max keeps a value like
# 99999999999999999999 from being used as a loop bound.
#
# The field is named by its own number as written (a DKIM2-Signature by its
# i=, a Message-Instance by its m=, -07 C6): $ident, defaulting to $n. So a
# signature's bad m= is "DKIM2-Signature i=2 syntax error", and an
# out-of-range one "DKIM2-Signature i=2 m=101 exceeds ...".
sub chain_number_error {
    my ($field, $tag, $n, $ident) = @_;
    return unless defined $n;
    my $id_tag = $field eq 'Message-Instance' ? 'm' : 'i';
    my $who = "$field $id_tag=" . ($ident // $n);
    return "PERMERROR: $who syntax error"
        unless $n =~ /\A[0-9]+\z/ && $n =~ /[1-9]/;
    $who .= " $tag=$n" if $tag ne $id_tag;
    return "PERMERROR: $who exceeds the maximum chain number of "
        . MAX_CHAIN_NUMBER if length($n) > 2 || $n > MAX_CHAIN_NUMBER;
    return "PERMERROR: $who exceeds the maximum chain length of "
        . MAX_CHAIN_LENGTH if $n > MAX_CHAIN_LENGTH;
    return;
}

# The PERMERROR for the lowest number that appears twice among a field's
# m= or i= values, or undef. Each number names one hop, so a second field
# with the same number is never a valid chain, and taking either one would
# let the other go unchecked.
sub duplicate_number_error {
    my ($field, $tag, @numbers) = @_;
    my %count;
    $count{$_ + 0}++ for grep { defined } @numbers;
    # The lowest number given twice (interop contract C9), not the first met.
    my ($n) = sort { $a <=> $b } grep { $count{$_} > 1 } keys %count;
    return defined $n ? "PERMERROR: $field $tag=$n is duplicated" : undef;
}

# The groups of an h= or s= value (-09 sections 9.3, 10.9): any-of groups
# split by "|", each an all-of list split by ",", as [[item, ...], ...] with
# each item's text untrimmed (its own parser trims the FWS around it). Undef
# when a member is empty -- a leading, trailing or doubled "|" or "," -- which
# is a syntax error (the -08 contract, D2).
sub split_any_all {
    my ($value) = @_;
    my @groups;
    for my $group (split /\|/, $value, -1) {
        my @items = split /,/, $group, -1;
        return if !@items || grep { /\A[ \t\r\n]*\z/ } @items;
        push @groups, \@items;
    }
    return \@groups;
}

# combine_sets(\@groups, $none_passed) -> ($state, $text): the result of an
# h= or s= value from its members' own (-09 sections 14.6, 14.7). @groups is
# [[[$state, $text], ...], ...] -- the "|" groups of "," lists, in the
# order the value gives them -- with each $state one of pass, fail,
# temperror, permerror and $text the member's own error. An all-of list
# passes if every member does; is a temperror if every member that does not
# is one; else fails if any member fails; else is a permerror. The any-of
# groups pass if one does; else are a temperror if one is; else fail if one
# does; else are a permerror. The text (contract D3/D4): with one group, the
# first member whose state is the result's; with several, $none_passed for a
# fail, else the first member anywhere whose state is the result's.
sub combine_sets {
    my ($groups, $none_passed) = @_;
    my @all;
    for my $g (@$groups) {
        my @bad = grep { $_->[0] ne 'pass' } @$g;
        push @all, !@bad                                    ? 'pass'
                 : !grep({ $_->[0] ne 'temperror' } @bad)   ? 'temperror'
                 : grep({ $_->[0] eq 'fail' } @bad)         ? 'fail'
                 :                                            'permerror';
    }
    my %have = map { $_ => 1 } @all;
    my ($state) = grep { $have{$_} } qw(pass temperror fail permerror);
    return ('pass') if $state eq 'pass';
    return ($state, $none_passed) if @$groups > 1 && $state eq 'fail';
    my @members = @$groups == 1 ? @{ $groups->[0] } : map { @$_ } @$groups;
    my ($first) = grep { $_->[0] eq $state } @members;
    return ($state, $first->[1]);
}

# Parse a message with Email::MIME for the Message-Instance code's purposes:
# raw header fields and the raw body. DKIM2 never reads MIME
# parameters, so a sender's broken Content-Type -- `text/plain; Windows-1252`
# and worse, as 2003 spam and some list software emit -- must not stop a
# message from being verified. Email::MIME::ContentType croaks on such a
# parameter by default; relax that for the duration of the parse only (it is
# a package variable, and the host application's own parsing keeps its
# setting). Found 2026-10-04 replaying the SpamAssassin corpus through a list.
sub parse_mime {
    my ($raw) = @_;
    local $Email::MIME::ContentType::STRICT_PARAMS = 0;
    local $SIG{__WARN__} = sub { };   # the relaxed parser warns instead
    return Email::MIME->new($raw);
}

# The raw m= value of a Message-Instance header value (whitespace removed,
# as MessageInstance->parse does), or undef if it has no m= tag.
sub mi_version_tag {
    my ($header) = @_;
    $header = $header->[0] if ref($header) eq 'ARRAY';
    $header = $$header if ref($header);
    return unless defined $header;
    for my $part (split /;/, $header) {
        next unless $part =~ /\A\s*m\s*=(.*)\z/s;    # tag-names are case-sensitive (-09 §8)
        (my $v = $1) =~ s/\s//g;
        return $v;
    }
    return;
}

# The m= number of a Message-Instance header value, or undef when it has no
# m= or the m= is not all ASCII digits (never a digit prefix). Numeric, so
# "01" and "001" are 1. Callers check chain_number_error(mi_version_tag(...))
# before using it as a bound.
sub extract_mi_version {
    my $v = mi_version_tag(@_);
    return unless defined $v && $v =~ /\A[0-9]+\z/;
    return length($v) <= 15 ? 0 + $v : $v;
}

# Strip Message-Instance headers with the given version numbers from a raw message string.
# The message must use CRLF line endings.  Returns the modified message string.
sub strip_mi_versions {
    my ($message, @versions) = @_;
    return $message unless @versions;
    my %to_strip = map { $_ => 1 } @versions;

    my $EOL = "\015\012";
    my $sep_pos = index($message, $EOL . $EOL);
    return $message if $sep_pos < 0;

    my $hdrs_raw = substr($message, 0, $sep_pos);
    my $rest     = substr($message, $sep_pos);   # includes blank line + body

    # Parse folded headers into whole-header strings
    my @entries;
    my $cur = '';
    for my $line (split /\015\012/, $hdrs_raw, -1) {
        if ($line =~ /^[ \t]/ && $cur ne '') {
            $cur .= $EOL . $line;
        } else {
            push @entries, $cur if $cur ne '';
            $cur = $line;
        }
    }
    push @entries, $cur if $cur ne '';

    # Keep all headers except Message-Instance ones with versions in %to_strip
    my @kept;
    for my $entry (@entries) {
        if ($entry =~ /^Message-Instance:/i) {
            my ($val) = $entry =~ /^[^:]+:\s*(.*)/s;
            if (defined $val) {
                $val =~ s/\015?\012[ \t]+/ /g;   # unfold for version extraction
                my $ver = extract_mi_version($val);
                next if defined $ver && $to_strip{$ver};
            }
        }
        push @kept, $entry;
    }

    return join($EOL, @kept) . $rest;
}

1;

__END__

=encoding utf8

=head1 NAME

Mail::DKIM2::Common - Constants, chain numbering and the any/all groups shared by the DKIM2 modules

=head1 SYNOPSIS

    use Mail::DKIM2::Common qw(DKIM2_DRAFT MAX_CHAIN_LENGTH chain_number_error);

    # Everything that was here before 0.31 can still be imported from here:
    use Mail::DKIM2::Common qw(fold_header load_private_key relaxed_domain_match);

=head1 DESCRIPTION

What the other modules share and none of them owns: the protocol's
constants and this implementation's limits, the numbering of
Message-Instance and DKIM2-Signature fields (and the PERMERROR strings for
fields that cannot be numbered), and the "any of these groups, all of each"
combination that C<h=> and C<s=> both use. Nothing is exported by default.

Until 0.31 this module also held the functions that are now in

=over 4

=item L<Mail::DKIM2::Canon>

header canonicalization, the fields that are not hashed, the signing input;

=item L<Mail::DKIM2::Fold>

C<fold_header>;

=item L<Mail::DKIM2::Address>

envelope paths, domains, the relaxed domain match, the Authentic From check;

=item L<Mail::DKIM2::Key>

private keys, key records, Domain Policy Records, signing algorithms;

=item L<Mail::DKIM2::RecipeJSON>

the base64 JSON of an C<r=> tag.

=back

Every one of them is still importable from here, and callable as
C<Mail::DKIM2::Common::NAME>, so existing callers need no change; they are
documented where they now live.

This module implements draft-ietf-dkim-dkim2-spec-09; see L<Mail::DKIM2/STATUS>
for what that means for the wire format and the API, and
L<Mail::DKIM2/CONVENTIONS> for the option, input and error conventions every
module here follows.

=head1 CONSTANTS

=head2 DKIM2_DRAFT, DKIM2_REPO, DKIM2_DATE

The spec revision implemented (C<ietf-dkim-dkim2-spec-09>), where the
code lives, and the date this implementation's DKIM2 behaviour last
changed. Emitted in X-DKIM2-Info debug headers
(draft-gondwana-dkim2-debug-header).

=head2 MAX_CHAIN_LENGTH

32: a message carrying more Message-Instance or DKIM2-Signature fields
than this, or an C<i=> or C<m=> naming a larger number, is a PERMERROR,
found before any key is fetched. Local policy, not spec.

=head2 MAX_CHAIN_NUMBER

99: the largest number an C<i=> or C<m=> may be written as (at most
two digits). See L</chain_number_error($field, $tag, $n)>.

=head2 MAX_SIGNATURE_ITEMS

8: the most items one DKIM2-Signature's C<s=> may carry. Local policy:
-08 sets no limit, and each item may cost a key lookup and a signature
check. The Verifier refuses a field with more, before fetching any key,
as "has more than 8 signatures". New in 0.28.

=head1 CHAIN NUMBERS

=head2 mi_version_tag($header_value)

The raw C<m=> value of a Message-Instance value with whitespace removed,
or undef when there is none. Pass it to
L</chain_number_error($field, $tag, $n)> before trusting it.

=head2 extract_mi_version($header_value)

The C<m=> number of a Message-Instance value, as a number (so C<01> is
1), or undef when there is no C<m=> or it is not all ASCII digits.
Accepts a string, a scalar ref, or an arrayref (first element).

=head2 strip_mi_versions($message, @m)

Removes the Message-Instance fields with the given C<m=> numbers from a
CRLF message string and returns the result.

=head2 valid_sequence($i)

True when C<$i> (a DKIM2-Signature C<i=> value) is a positive integer
written in ASCII digits. A signature whose C<i=> is not is one no verifier
can place in the chain or key: L<Mail::DKIM2::Verifier> reports it as
L</UNKEYABLE_SIGNATURE_ERROR>.

=head2 chain_number_error($field, $tag, $n, $ident)

The PERMERROR string for an C<i=> or C<m=> value that is not a chain
number, or undef (also for an undefined C<$n>, which is left to the
caller). The field is named by its own number as written, C<$ident>
(default C<$n>): a DKIM2-Signature by C<i=>, a Message-Instance by C<m=>.
A value that is not 1*DIGIT in ASCII, or is zero, is
C<"PERMERROR: $field i=$ident syntax error"> (C<m=> for a
Message-Instance; -09 section 14.2). More than two digits or above
L</MAX_CHAIN_NUMBER> is C<"PERMERROR: DKIM2-Signature i=$ident exceeds the
maximum chain number of 99">, with C<" m=$n"> after C<$ident> for a
signature's C<m=>. Above L</MAX_CHAIN_LENGTH>, likewise C<"... exceeds the
maximum chain length of 32">: every C<i=> and C<m=> names one hop, so none
can be larger than the chain. C<01> and C<001> are 1.

=head2 duplicate_number_error($field, $tag, @numbers)

The PERMERROR string for the first number that appears twice, or undef.

=head2 chain_length_error($msg_or_counts)

The PERMERROR string for a message over L</MAX_CHAIN_LENGTH>, or undef.
Takes an L<Email::MIME> or a hashref of field counts keyed by lowercased
name.

=head2 UNKEYABLE_SIGNATURE_ERROR

The PERMERROR string for a DKIM2-Signature with no C<i=> tag, or one that
does not parse: C<"PERMERROR: DKIM2-Signature i= tag=i missing">.

=head2 MI_MISSING_M_ERROR

The PERMERROR string for a Message-Instance with no C<m=> tag:
C<"PERMERROR: Message-Instance m= tag=m missing">. New in 0.25.

=head2 unkeyable_signature_error($value)

The PERMERROR string for a DKIM2-Signature header value whose C<i=> is
missing (L</UNKEYABLE_SIGNATURE_ERROR>) or not a positive integer
(C<"PERMERROR: DKIM2-Signature i=E<lt>as writtenE<gt> syntax error">). New
in 0.23.

=head1 GROUPS

=head2 split_any_all($value)

The groups of an C<h=> or C<s=> value (-09 sections 9.3 and 10.9): an
arrayref of C<|>-separated groups, each an arrayref of its C<,>-separated
members, untrimmed. Undef if any member is empty (a leading, trailing or
doubled C<|> or C<,>), which is a syntax error.

=head2 combine_sets(\@groups, $none_passed)

The overall C<($state, $text)> of an C<h=> or C<s=> value from its
members' results (-09 sections 14.6 and 14.7). C<@groups> holds one
arrayref per C<|> group, of C<[$state, $text]> per member, C<$state> being
C<pass>, C<fail>, C<temperror> or C<permerror>. A group passes if every
member does; is a temperror if every member that does not pass is one; else
fails if any member fails; else is a permerror. The value passes if any
group does; else is a temperror, fail or permerror if any group is, in that
order. C<$text> is the first member's (in value order) with the overall
state, or C<$none_passed> when several groups give a fail. A pass has no
text.

=head1 PARSING

=head2 parse_mime($raw)

Parse C<$raw> into an L<Email::MIME> for the library's own use (raw header
fields, raw body), with L<Email::MIME::ContentType>'s parameter check relaxed
for the duration of the parse. DKIM2 never reads a MIME parameter, so a
sender's broken C<Content-Type> must not stop a message from being verified or
make every verification warn. The package variable is restored afterwards.

=head1 AUTHOR

Bron Gondwana E<lt>brong@fastmailteam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025-2026 Fastmail Pty Ltd.  This is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
