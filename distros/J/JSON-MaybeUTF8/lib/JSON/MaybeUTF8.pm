package JSON::MaybeUTF8;
# ABSTRACT: Simple wrapper for explicit JSON Unicode text/UTF-8 byte functions

use strict;
use warnings;

our $VERSION = '1.002';

=head1 NAME

JSON::MaybeUTF8 - provide explicit text/UTF-8 JSON functions

=head1 SYNOPSIS

 use JSON::MaybeUTF8 qw(:v1);
 binmode STDOUT, ':encoding(UTF-8)';
 binmode STDERR, ':raw';
 (*STDOUT)->print(encode_json_text({ text => '...' }));
 (*STDERR)->print(encode_json_utf8({ text => '...' }));

=head1 DESCRIPTION

Combines L<JSON::MaybeXS> with L<Unicode::UTF8> to provide
4 functions that handle the combinations of JSON and UTF-8
encoding/decoding.

The idea is to make the UTF-8-or-not behaviour more explicit
in code that deals with multiple transport layers such as
database, cache and I/O.

This is a trivial wrapper around two other modules.

=cut

use feature qw(state);

use JSON::MaybeXS;
use Unicode::UTF8 qw(encode_utf8 decode_utf8);

use Exporter qw(import export_to_level);

=head2 BOM removal

The C<< $JSON::Maybe::UTF8::REMOVE_BOM >> flag is B<set by default> due
to L<https://github.com/rurban/Cpanel-JSON-XS/issues/125>. If you would
prefer to disable this, add C<< $JSON::Maybe::UTF8::REMOVE_BOM = 0; >>
in your code.

Note that this only affects things when L<Cpanel::JSON::XS> is used (preferred by L<JSON::MaybeXS>
if it can be loaded).

=cut

our $REMOVE_BOM = 1;

our @EXPORT_OK = qw(
    decode_json_utf8
    encode_json_utf8
    decode_json_text
    encode_json_text
);
our %EXPORT_TAGS = (
    v1 => [ @EXPORT_OK ],
);

=head2 decode_json_utf8

Given a UTF-8-encoded JSON byte string, returns a Perl data
structure. May optionally remove the UTF-8 L<BOM|https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8>
if it exists.

=cut

sub decode_json_utf8 {
    state $json = JSON::MaybeXS->new;
    die 'bad json state' if $json->get_utf8;
    return $json->decode_utf8($_[0]) unless $REMOVE_BOM;
    (my $txt = decode_utf8(shift)) =~ s{^\x{feff}}{};
    return $json->decode($txt);
}

=head2 encode_json_utf8

Given a Perl data structure, returns a UTF-8-encoded JSON
byte string.

=cut

sub encode_json_utf8 {
    state $json = JSON::MaybeXS->new;
    die 'bad json state' if $json->get_utf8;
    encode_utf8($json->encode(shift))
}

=head2 decode_json_text

Given a JSON string composed of Unicode characters (in
Perl's internal encoding), returns a Perl data structure.

=cut

sub decode_json_text {
    state $json = JSON::MaybeXS->new;
    die 'bad json state' if $json->get_utf8;
    my $txt = shift;
    $txt =~ s{^\x{feff}}{} if $REMOVE_BOM;
    $json->decode($txt);
}

=head2 encode_json_text

Given a Perl data structure, returns a JSON string composed
of Unicode characters (in Perl's internal encoding).

=cut

sub encode_json_text {
    state $json = JSON::MaybeXS->new;
    die 'bad json state' if $json->get_utf8;
    $json->encode(shift)
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2017. Licensed under the same terms as Perl itself.

