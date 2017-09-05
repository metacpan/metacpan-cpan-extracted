use strict;
use warnings;

package Devel::JSON;

our $VERSION = '1.001';

# Just to allow to be loaded with -d:JSON
sub DB::DB {}

use JSON::MaybeXS ();

our @JSON_options;

# 2.05: _get_locale_encoding appeared in encoding.pm
# 2.73: includes my patch for locale encoding on Win32
use Encode 2.05 ();
use encoding ();
my $locale_enc = encoding::_get_locale_encoding;

if (defined($locale_enc) && $locale_enc =~ /UTF/i) { # Native JSON encoding
    binmode(STDOUT, ":encoding($locale_enc)")
} else {
    @JSON_options = (ascii => 1)
}


sub import
{
    shift;
    unshift @JSON_options, map { s/^-// ? ($_ => 0) : ($_ => 1) } @_
}


use Filter::Simple sub {
    # As getting proper source encoding can be tricky on the command line
    # let's convert bytes to the locale encoding: DWIM
    $_ = Encode::decode($locale_enc, $_, Encode::FB_CROAK)
	if defined($locale_enc) && !utf8::is_utf8($_);

    $_ = 'print JSON::MaybeXS->new(pretty => 1, canonical => 1, allow_nonref => 1, @Devel::JSON::JSON_options)->encode(scalar do {use utf8;'. $_ . '})'
};

1;
__END__

=encoding UTF-8

=head1 NAME

Devel::JSON - Easy JSON output for one-liners

=head1 SYNOPSIS

    $ perl -d:JSON -e '[ 1..3 ]'
    [
        1,
        2,
        3
    ]

    $ perl -d:JSON -e '{b => 2, c => 4}'
    {
        "b": 2,
        "c": 4
    }

Default output encoding is UTF-x if this is the charset of the locale:

    $ perl -d:JSON -e "qq<\N{SNOWMAN}>"
    "☃"

Force ASCII output:

    $ perl -d:JSON=ascii -e "qq<\N{SNOWMAN}>"
    "\u2603"

Booleans:

    $ perl -d:JSON -MJSON::PP -e 'JSON::PP::true'
    true

=head1 DESCRIPTION

If you use this module from the command-line, the last value of your one-liner
(C<-e>) code will be serialized as JSON data. The expression is evaluated in
scalar context.

The output will be either UTF-x (UTF-8, UTF-16...) or just ASCII, depending on
your locale (check C<LC_CTYPE> on Unix or GNU).

As a convenience (because you may want to deal with non-ASCII content in your
C<-e> source), your code is converted from bytes using the current locale.

The following L<JSON> options are enabled by default:

=over 4

=item C<pretty>

=item C<canonical>

=item C<allow_nonref>

=back

You can enable more options by giving import arguments (a '-' prefix
disables the option):

    # Force ASCII output
    $ perl -d:JSON=ascii -e '[1..3]'

    # Disable pretty (note '-' before the name)
    $ perl -d:JSON=-pretty -e '[1..3]'

    # Non-ASCII in -e
    $ perl -d:JSON=ascii -e '"Mengué"'
    "Mengu\u00e9"

=head1 SEE ALSO

L<JSON>, L<JSON::MaybeXS>, L<json-to> (L<App::JSON::to>).

=head1 AUTHOR

Olivier Mengué, L<mailto:dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2017 Olivier Mengué.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
