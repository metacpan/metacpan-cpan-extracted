package HTTP::libsfparse;

use v5.20;
use warnings;

use Exporter   5.57 qw( import );
use XSLoader   ();

our $VERSION = 'v0.0.5';

# ABSTRACT: parse RFC 9651 HTTP Structured Fields using libsfparse

our @TYPES = qw(
    SFPARSE_TYPE_BOOLEAN
    SFPARSE_TYPE_INTEGER
    SFPARSE_TYPE_DECIMAL
    SFPARSE_TYPE_STRING
    SFPARSE_TYPE_TOKEN
    SFPARSE_TYPE_BYTESEQ
    SFPARSE_TYPE_INNER_LIST
    SFPARSE_TYPE_DATE
    SFPARSE_TYPE_DISPSTRING
);

our @INDEX = qw(
    SFP_TYPE
    SFP_VALUE
    SFP_PARAMS
    SFP_KEY
    SFP_ITEM
);

our @EXPORT_OK   = ( qw( parse_item parse_list parse_dictionary ), @TYPES, @INDEX );
our %EXPORT_TAGS = (
    all   => [@EXPORT_OK],
    types => [@TYPES],
    index => [@INDEX],
);

XSLoader::load( __PACKAGE__, $VERSION );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::libsfparse - parse RFC 9651 HTTP Structured Fields using libsfparse

=head1 SYNOPSIS

    use HTTP::libsfparse qw(
        parse_item parse_list parse_dictionary :types :index
    );

    # Every item is [ $type, $value, $params ], and the positions have
    # names, so none of this is counted out by hand.

    # Single item
    my $item = parse_item('text/html;q=0.8');
    $item->[SFP_TYPE] == SFPARSE_TYPE_TOKEN;     # true
    $item->[SFP_VALUE];                          # 'text/html'
    $item->[SFP_PARAMS][0][SFP_KEY];             # 'q'
    $item->[SFP_PARAMS][0][SFP_ITEM][SFP_VALUE]; # 0.8

    # Dictionary: RFC 9218 priority. A dictionary is a list of pairs.
    my $pri = parse_dictionary('u=5, i');
    $pri->[0][SFP_KEY];                          # 'u'
    $pri->[0][SFP_ITEM][SFP_VALUE];              # 5
    $pri->[1][SFP_ITEM][SFP_TYPE] == SFPARSE_TYPE_BOOLEAN;   # true

    # Pairs are easy to index when you do not mind losing duplicate keys
    my %pri = map { $_->[SFP_KEY] => $_->[SFP_ITEM] } @$pri;
    $pri{u}[SFP_VALUE];                          # 5

    # List, with an inner list and parameters
    my $list = parse_list('(1 2 3;b="foo"), bar, baz;f=:aGVsbG8=:');
    my $inner = $list->[0][SFP_VALUE];

    $list->[0][SFP_TYPE] == SFPARSE_TYPE_INNER_LIST;         # true
    $inner->[1][SFP_VALUE];                                  # 2
    $inner->[2][SFP_PARAMS][0][SFP_ITEM][SFP_VALUE];         # 'foo'
    $list->[2][SFP_PARAMS][0][SFP_ITEM][SFP_VALUE];          # 'hello'

    # Malformed input throws
    my $ok = eval { parse_list('a, b, "unterminated'); 1 };

=head1 DESCRIPTION

This module is an XS binding to L<libsfparse|https://github.com/ngtcp2/sfparse>, the C parser for HTTP
Structured Field Values (L<RFC 9651|https://www.rfc-editor.org/rfc/rfc9651>,
which obsoletes RFC 8941) written for the ngtcp2 and nghttp3 QUIC/HTTP3
stacks.

It uses a bundled copy of libsfparse, and not a version that may already be installed on your system.

You may prefer to use L<HTTP::StructuredField> instead.

=head2 Format of the Parsed Data

Every parsed item is an array reference of three elements:

    [ $type, $value, $params ]

      0   SFP_TYPE     one of the type constants below
      1   SFP_VALUE    the value itself
      2   SFP_PARAMS   an array reference of [ $key, $item ] pairs

The names in that second column are constants for the positions.

=head2 Types

C<$type> is one of the following constants, which are libsfparse's own
C<sfparse_type> enumerators and carry its values. Import them individually or
as C<:types>.

=over 4

=item C<SFPARSE_TYPE_BOOLEAN>

C<$value> is C<1> or C<0>.

=item C<SFPARSE_TYPE_INTEGER>

C<$value> is the integer. RFC 9651 limits these to 15 digits, so they are
always exact, including on a Perl built with 32 bit integers.

=item C<SFPARSE_TYPE_DECIMAL>

C<$value> is the number as a Perl floating point number. RFC 9651 allows at
most twelve digits before the decimal point and three after it, so every legal
decimal multiplied by a thousand is a whole number below C<2**53>: the
conversion is exact, and C<1.001> compares equal to the literal C<1.001>.

=item C<SFPARSE_TYPE_STRING>

C<$value> is the string with its C<\\> escapes removed. RFC 9651 strings only
hold printable ASCII.

=item C<SFPARSE_TYPE_TOKEN>

C<$value> is the token, for example C<text/html> or C<gzip>.

=item C<SFPARSE_TYPE_BYTESEQ>

C<$value> is the decoded byte string, not the Base64 text.

=item C<SFPARSE_TYPE_DATE>

C<$value> is the number of seconds since the Unix epoch, and may be negative.

=item C<SFPARSE_TYPE_DISPSTRING>

C<$value> is the percent-decoded display string, as a character string with
Perl's UTF-8 flag set. libsfparse has already validated the UTF-8.

=item C<SFPARSE_TYPE_INNER_LIST>

C<$value> is an array reference of items, each in this same form, each with
its own parameters. The inner list's own parameters are in C<$params> of the
inner list itself.

=back

=head2 Parameters

C<$params> is always present on items returned by the functions in this
module, and is an empty array reference when the item has no parameters. It
holds one C<[ $key, $item ]> pair per parameter, in field order, and each
C<$item> is itself in the form above (its own C<$params> is undef, since
parameters cannot nest).

A parameter with no explicit value is boolean true, as the RFC requires.

Keys are reported as they appear and are not deduplicated. which is what lets
a caller reject a field value that repeats one. RFC 9651 says the last
occurrence of a repeated key wins; collapsing them that way is one line:

    my %params = map { $_->[0] => $_->[1] } @$params;

=head2 Conformance

The distribution bundles the HTTP Working Group's
L<structured-field-tests|https://github.com/httpwg/structured-field-tests>
conformance suite and runs it as F<t/13-httpwg-suite.t>: 1607 cases, 873 of
them field values that must be rejected.

All of them pass. One passes by exemption rather than agreement: libsfparse
rejects a byte sequence carrying extra Base64 padding, which the suite marks
C<can_fail>, so either behaviour conforms.

=head2 Bytes, not Characters

HTTP field values are ASCII byte strings, and that is what these functions expect.
A string is accepted as long as it contains nothing above U+007E.

Display strings (C<%"...">) are the one place where RFC 9651 carries real
Unicode, and this module hands those back decoded, with the UTF-8 flag set.

This module has a hard size limit of 32KiB for byte strings.
Note that most web servers will default to much lower limits, usually 8KiB.

=head1 NAME

HTTP::libsfparse - parse RFC 9651 HTTP Structured Fields using libsfparse

=head1 VERSION

version v0.0.1

=head1 EXPORTS

=head2 parse_item

    my $item = parse_item($string);

Parses a field value consisting of a single item and returns one item.
Trailing content after the item is a parse error, as is an empty field value.

=head2 parse_list

    my $list = parse_list($string);

Parses a List and returns an array reference of items. An empty field value
yields an empty array reference, which is what RFC 9651 calls an empty list.

=head2 parse_dictionary

    my $dict = parse_dictionary($string);

Parses a Dictionary and returns an array reference of C<[ $key, $item ]>
pairs in field order. An empty field value yields an empty array reference.

As with parameters, keys are not deduplicated, so a field value that repeats
one reports it twice; see L</Parameters> for why, and for the one-liner that
collapses them the way RFC 9651 says to.

=head1 before:EXPORTS

Nothing is exported by default

=head1 KNOWN ISSUES

RFC 9651 specifies that integers can be up to 15 digits long, which
makes decoding them into integers problematic for 32-bit systems.
Numbers that are too large will be represented using L<Math::Int64>.

libsfparse also provides C<sfparse_unescape>, C<sfparse_base64decode> and
C<sfparse_pctdecode>. Those functions assume their input has already been
validated by the parser and that the output buffer is large enough; handed
arbitrary Perl strings they would read and write out of bounds. They are used
internally on parser-produced values only, and are not exported.

=head1 SEE ALSO

L<HTTP::StructuredField> provides an object-oriented interface.

L<RFC 9651|https://www.rfc-editor.org/rfc/rfc9651>, Structured Field Values
for HTTP.

L<RFC 9218|https://www.rfc-editor.org/rfc/rfc9218>, Extensible Prioritization
Scheme for HTTP, whose C<Priority> field is a dictionary.

L<libsfparse|https://github.com/ngtcp2/sfparse> and its
L<documentation|https://nghttp2.org/sfparse/>.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/perl-HTTP-StructuredField>
and may be cloned from L<https://github.com/robrwo/perl-HTTP-StructuredField.git>

=head1 SUPPORT

Only the latest release of this module will be supported.

This module requires Perl v5.20 or later.
Only Perl versions released in the past ten years will be supported.

=head2 Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/perl-HTTP-StructuredField/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see F<SECURITY.md> for instructions how to report security vulnerabilities.

=head1 AUTHOR

Robert Rothenberg <perl@rhizomnic.com>

This wrapper was written with the assistance of Claude Opus.

=head1 CONTRIBUTOR

Paul Johnson <paul@pjcj.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Robert Rothenberg.

This is free software, licensed under:

  The MIT (X11) License

The bundled copy of libsfparse in F<src/> is Copyright (c) 2023
Tatsuhiro Tsujikawa and other sfparse contributors.
It is distributed under the MIT license; see F<src/LICENSE.sfparse>.
It is included unmodified.

=cut
