package FU::Util 1.2;

use v5.36;
use FU::XS;
use Carp 'confess';
use Exporter 'import';
use POSIX ();
use experimental 'builtin';

our @EXPORT_OK = qw/
    to_bool
    json_format json_parse
    utf8_decode uri_escape uri_unescape
    query_decode query_encode
    httpdate_format httpdate_parse
    gzip_lib gzip_compress brotli_compress
    fdpass_send fdpass_recv
/;

sub utf8_decode :prototype($) {
    return if !defined $_[0];
    confess 'Invalid UTF-8' if !utf8::decode($_[0]);
    confess 'Invalid control character' if $_[0] =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]/;
    $_[0]
}

sub uri_escape :prototype($) ($s) {
    utf8::encode($s);
    $s =~ s/([^A-Za-z0-9._~-])/sprintf '%%%02x', ord $1/eg;
    $s;
}

sub uri_unescape :prototype($) ($s) {
    return if !defined $s;
    utf8::encode($s);
    $s =~ tr/+/ /;
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    utf8_decode $s;
}

sub query_decode :prototype($) ($s) {
    my %o;
    for (split /&/, $s//'') {
        next if !length;
        my($k,$v) = map uri_unescape($_), split /=/, $_, 2;
        $v //= builtin::true;
        if (ref $o{$k}) { push $o{$k}->@*, $v }
        elsif (exists $o{$k}) { $o{$k} = [ $o{$k}, $v ] }
        else { $o{$k} = $v }
    }
    \%o
}

sub query_encode :prototype($) ($o) {
    return join '&', map {
        my($k, $v) = ($_, $o->{$_});
        $k = uri_escape $k;
        map {
            my $x = $_;
            $x = $x->TO_QUERY() if builtin::blessed($x) && $x->can('TO_QUERY');
            my $bool = to_bool($x);
            !defined $x || !($bool//1) ? ()
            : $bool ? $k
            : $k.'='.uri_escape($x)
        } ref $v eq 'ARRAY' ? @$v : ($v);
    } sort keys %$o;
}


my @httpmonths = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my %httpmonths = map +($httpmonths[$_], $_), 0..11;
my @httpdays = qw/Sun Mon Tue Wed Thu Fri Sat/;
my $httpdays = '(?:'.join('|', @httpdays).')';

sub httpdate_format :prototype($) ($time) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime $time;
    sprintf '%s, %02d %s %d %02d:%02d:%02d GMT',
        $httpdays[$wday], $mday, $httpmonths[$mon], $year+1900, $hour, $min, $sec;
}

sub httpdate_parse :prototype($) ($str) {
    return if $str !~ /^\s*$httpdays, ([0-9]{2}) ([A-Z][a-z]{2}) ([0-9]{4}) ([0-9]{2}):([0-9]{2}):([0-9]{2}) GMT\s*$/;
    my ($mday, $mon, $year, $hour, $min, $sec) = ($1, $httpmonths{$2}, $3, $4, $5, $6);
    return if !defined $mon;
    # mktime() interprets the broken down time as our local timezone,
    # which is utter garbage. But we can work around that by subtracting the
    # time offset between localtime and gmtime around the given date. Might be
    # off for a few hours around DST changes, but ugh.
    my $mktime = POSIX::mktime($sec, $min, $hour, $mday, $mon, $year-1900);
    $mktime + (POSIX::mktime(localtime $mktime) - POSIX::mktime(gmtime $mktime));
}


1;
__END__

=head1 NAME

FU::Util - Miscellaneous Utility Functions

=head1 SYNOPSIS

  use FU::Util qw/json_format/;

  my $data = json_format [1, 2, 3];

=head1 DESCRIPTION

A bunch of functions that are too small (or I'm too lazy) to split out into
separate modules. Some of these functions really ought to be part of Perl core.


=head1 Boolean Stuff

Perl has had a builtin boolean type since version 5.36 and FU uses that where
appropriate, but there's still a lot of older code out there using different
conventions. The following function should help when interacting with older
code and provide a gradual migration path to the new builtin booleans.

=over

=item to_bool($val)

Returns C<undef> if C<$val> is not likely to be a distinct boolean type,
otherwise it returns a normalized C<builtin::true> or C<builtin::false>.

This function recognizes the builtin booleans, C<\0>, C<\1>, L<boolean>,
L<Types::Serialiser> (which is used by L<JSON::XS>, L<JSON::SIMD>, L<CBOR::XS>
and others), L<JSON::PP> (also used by L<Cpanel::JSON::XS> and others),
L<JSON::Tiny> and L<Mojo::JSON>.

This function is ambiguous in contexts where a bare scalar reference is a valid
value for C<$val>, due to C<\0> and C<\1> being considered booleans.

=back

=head1 JSON Parsing & Formatting

This module comes with a custom C-based JSON parser and formatter. These
functions conform to L<RFC-8259|https://tools.ietf.org/html/rfc8259>,
non-standard extensions are not supported and never will be. It also happens to
be pretty fast, refer to L<FU::Benchmarks> for some numbers.

JSON booleans are parsed into C<builtin::true> and C<builtin::false>. In the
other direction, the C<to_bool()> function above is used to recognize which
values to represent as JSON boolean.

JSON numbers that are too large fit into a Perl integer are parsed into a
floating point value instead. This obviously loses precision, but is consistent
with C<JSON.parse()> in JavaScript land - except Perl does support the full
range of a 64bit integer. JSON numbers with a fraction or exponent are also
converted into floating point, which may lose precision as well.
L<Math::BigInt> and L<Math::BigFloat> are not currently supported. Attempting
to format a floating point C<NaN> or C<Inf> results in an error.

=over

=item json_parse($string, %options)

Parse a JSON string and return a Perl value. With the default options, this
function is roughly similar to:

  JSON::PP->new->allow_nonref->core_bools-decode($string);

Croaks on invalid JSON, but the error messages are not super useful.  This
function also throws an error on JSON objects with duplicate keys, which is
consistent with the default behavior of L<Cpanel::JSON::XS> but inconsistent
with other modules.

Supported C<%options>:

=over

=item allow_control

Boolean, set to true to allow (encoded) ASCII control characters in JSON
strings, such as C<\u0000>, C<\b>, C<\u007f>, etc.  These characters are
permitted per RFC-8259, but disallowed by this parser by default. See
C<utf8_decode()> below.

=item utf8

Boolean, interpret the input C<$string> as a UTF-8 encoded byte string instead
of a Perl Unicode string.

=item max_depth

Maximum permitted nesting depth of arrays and objects. Defaults to 512.

=item max_size

Throw an error if the JSON data is larger than the given size in bytes.
Defaults to 1 GiB.

=item offset

Takes a reference to a scalar that indicates from which byte offset in
C<$string> to start parsing. On success, the offset is updated to point to the
next non-whitespace character or C<undef> if the string has been fully
consumed.

This option can be used to parse a stream of JSON values:

  my $data = '{"obj":1}{"obj":2}';
  my $offset = 0;
  my $obj1 = json_parse($data, offset => \$offset);
  # $obj1 = {obj=>1};  $offset = 9;
  my $obj2 = json_parse($data, offset => \$offset);
  # $obj2 = {obj=>2};  $offset = undef;

=back


=item json_format($scalar, %options)

Format a Perl value as JSON. With the default options, this function behaves
roughly similar to:

  JSON::PP->new->allow_nonref->core_bools->convert_blessed->encode($scalar);

This function generates invalid JSON if you pass it a string with invalid
Unicode characters; I don't see how you'd ever accidentally end up with such a
string, anyway.

The following C<%options> are supported:

=over

=item canonical

Boolean, write hash keys in deterministic (sorted) order. This option currently
has no effect on tied hashes.

=item pretty

Boolean, format JSON with newlines and indentation for easier reading.  Beauty
is in the eye of the beholder, this option currently follows the convention
used by L<JSON::XS> and others: 3 space indent and one space around the C<:>
separating object keys and values. The exact format might change in later
versions.

=item utf8

Boolean, returns a UTF-8 encoded byte string instead of a Perl Unicode string.

=item html_safe

Boolean. When set, the encoded JSON is safe for (unescaped) inclusion into HTML
or XML content. This encodes C<< < >>, C<< > >> and C<< & >> as Unicode escapes.
Commonly used to embed data inside a HTML page:

  $html = '<script id="site_data" type="application/json">'
        . json_format($data, html_safe => 1)
        . '</script>';

This option does NOT make it safe to include the encoded JSON as an attribute
value. There is no way to do that without violating JSON specs, so you should
use entity escaping instead.

Some JSON modules escape the forward slash (C</>) character instead, but that
is I<only> sufficient for embedding inside a C<< <script> >> tag. In any other
context, you'll need the more thourough escaping provided by this C<html_safe>
option.

=item max_size

Maximum permitted size, in bytes, of the generated JSON string. Defaults to 1 GiB.

=item max_depth

Maximum permitted nesting depth of Perl values. Defaults to 512.

=back

=back

(Why the hell yet another JSON codec when CPAN is already full of them!? Well,
L<JSON::XS> is pretty cool but isn't going to be updated to support Perl's new
builtin booleans. L<JSON::PP> is slow and while L<Cpanel::JSON::XS> is
perfectly adequate, its codebase is way too large and messy for what I need -
it has too many unnecessary features and C<#ifdef>s to support ancient perls
and esoteric configurations. Still, if you need anything not provided by these
functions, L<JSON::PP> and L<Cpanel::JSON::XS> are perfectly fine alternatives.
L<JSON::SIMD> and L<JSON::Tiny> also look like good and maintained candidates.)


=head1 URI-Related Functions

While URIs are capable of encoding arbitrary binary data, the functions below
assume you're only dealing with text. This makes them more robust against weird
inputs, at the cost of flexibility.

=over

=item utf8_decode($bytes)

Convert a (perl-UTF-8 encoded) byte string into a sanitized perl Unicode
string. The conversion is performed in-place, so the C<$bytes> argument is
turned into a Unicode string. Returns the same string for convenience.

This function throws an error if the input is not valid UTF-8 or if it contains
ASCII control characters - that is, any character between C<0x00> and C<0x1f>
except for tab, newline and carriage return.

(This is a tiny wrapper around C<utf8::decode()> with some extra checks)

=item uri_escape($string)

Takes an Unicode string and returns a percent-encoded ASCII string, suitable
for use in a query parameter.

=item uri_unescape($string)

Takes an Unicode string potentially containing percent-encoding and returns a
decoded Unicode string. Also checks for ASCII control characters as per
C<utf8_decode()>.

=item query_decode($string)

Decode a query string or C<application/x-www-form-urlencoded> format (they're
the same thing). Returns a hashref with decoded key/value pairs. Values for
duplicated keys are collected into a single array value. Bare keys that do not
have a value are decoded as C<builtin::true>. Example:

    my $hash = query_decode 'bare&a=1&a=2&something=else';
    # $hash = {
    #   bare => builtin::true,
    #   a => [ 1, 2 ],
    #   something => 'else'
    # }

The input C<$string> is assumed to be a perl Unicode string. An error is thrown
if the resulting data decodes into invalid UTF-8 or contains control
characters, as per C<utf8_decode>.

=item query_encode($hashref)

The opposite of C<query_decode>. Takes a hashref of similar structure and
returns an ASCII-encoded query string. Keys with C<undef> or C<to_bool()> false
values are omitted in the output.

If a given value is a blessed object with a C<TO_QUERY()> method, that method
is called and it should return either C<undef>, a boolean or a string, which is
then encoded.

=back


=head1 HTTP Date Formatting

The HTTP date format is utter garbage, but with the right tools it doesn't
require I<too> much code to work with.

=over

=item httpdate_format($time)

Convert the given seconds-since-Unix-epoch C<$time> into a HTTP date string.

=item httpdate_parse($str)

Converts the given HTTP date string into a seconds-since-Unix-epoch integer.
This function is very strict about its input and only accepts "IMF-fixdate" as
per L<RFC7231|https://www.rfc-editor.org/rfc/rfc7231#section-7.1.1.1>, which is
what every sensible implementation written in the past decade uses.

This function plays fast and loose with timezone conversions, the parsed
timestamp I<might> be off by an hour or so for a few hours around a DST change.
This will not happen if your local timezone is UTC.

=back


=head1 Gzip Compression

Gzip compression can be done with a few different libraries. The canonical one
is I<zlib>, which is old and not well optimized for modern systems. There's
also I<zlib-ng>, a (much) more performant reimplementation that remains
API-compatible with I<zlib>. And there's I<libdeflate>, which offers a
different API that does not support streaming compression but is, in exchange,
even faster than I<zlib-ng>.

There are more implementations, of course, but this module only supports those
three and (attempts to) pick the best one that's available on your system.

=over

=item gzip_lib()

Returns an empty string if no supported gzip library was found on your system
(unlikely but possible), otherwise returns the selected implementation: either
C<"libdeflate">, C<"zlib-ng"> or C<"zlib">.

This function does not try very hard to differentiate between I<zlib> and
I<zlib-ng>, so it may report that I<zlib> is being used on systems where
C<libz.so> is, in fact, I<zlib-ng>.

=item gzip_compress($level, $data)

Returns a byte string with the gzip-compressed version of C<$data> at the given
gzip C<$level>, which is a number between 0 (no compression) and 12 (strongest
compression). Only I<libdeflate> supports levels higher than 9, for
I<zlib(-ng)> the level is capped at 9. 6 is typically used as a default.

Throws an error if no suitable library was found.

This function is B<NOT> safe to use from multiple threads!

=back

This module does not currently implement decompression. If you need that, or
streaming, or other functionality not provided here, there's
L<Compress::Raw::Zlib> and L<Compress::Zlib> in the core Perl distribution and
L<Gzip::Faster>, L<Gzip::Zopfli> and L<Gzip::Libdeflate> on CPAN.


=head1 Brotli Compression

Just a small wrapper around C<libbrotlienc.so>'s one-shot compression
interface.

=over

=item brotli_compress($level, $data)

Returns a byte string with the brotli-compressed version of C<$data> at the
given quality C<$level> (between 0 and 11).

Throws an error if C<libbrotlienc.so> could not be found or loaded.

=back


=head1 File Descriptor Passing

UNIX sockets (see L<IO::Socket::UNIX>) have the fancy property of letting you
send file descriptors over them, allowing you to pass, for example, a socket
from one process to another. This is a pretty low-level operation and not
something you'll often need, but two functions to use that feature are provided
here anyway because the L<FU> supervisor uses them:

=over

=item fdpass_send($send_fd, $pass_fd, $message)

Send a message and a file descriptor (C<$pass_fd>) over the given socket
(C<$send_fd>). C<$message> must not be empty, even if you don't intend to do
anything with it on receipt. Both C<$send_fd> and C<$pass_fd> must be numeric
file descriptors, as obtained by C<fileno()>.

=item ($fd, $message) = fdpass_recv($recv_fd, $max_message_len)

Read a file descriptor and message from the given C<$recv_fd>, which must be
the numeric file descriptor of a socket. This function can be used as a
replacement for C<sysread()>: the returned C<$fd> is undef if no file
descriptor was received. The returned C<$message> is undef on error or an empty
string on EOF.

Like regular socket I/O, a single C<fdpass_send()> message may be split across
multiple C<fdpass_recv()> calls; in that case the C<$fd> is only received on
the first call.

The C<O_CLOEXEC> flag is set on received file descriptors. Don't use this
function if the sender may include multiple file descriptors in a single
message, weird things can happen. Refer to L<this wonderful
discussion|https://gist.github.com/kentonv/bc7592af98c68ba2738f4436920868dc>
for more weirdness and edge cases.

=back

See also L<IO::FDPass> for a more portable solution, although that one does not
support passing along regular data.

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
