#!perl

use 5.008_001;
use strict;
use warnings;
use utf8;

use Encode;
use Lingua::EO::Orthography;

my $converter = Lingua::EO::Orthography->new;

my $x_systematic = q{NEC, kio estas japana kompanio, }
                 . q{ankaux havas superkomptilo. }
                 . q{Bonvole konsultu detalon en Vikipedio: }
                 . q{http://en.wikipedia.org/wiki/NEC_SX_architecture};
#                                                     ==
#                                                      ^
#                                                      |
# This is NOT a X-system!! ----------------------------+

# my $orthographic = $converter->convert($various);
# We cannot convert correctly this string at once,
# because "SX" will be converted!

my @words = split m{(\s+)}, $x_systematic;
WORD:
foreach my $word (@words) {
    next WORD
        if $word =~ m{
            (?:
                :// |       # URI
                @           # mail address
            )
        }xms;
    $word = $converter->convert($word);
}
my $orthographic = join q{}, @words;

my $utf8 = find_encoding('utf8');
print $utf8->encode("X-systematic: $x_systematic\n");
print $utf8->encode("Orthographic: $orthographic\n");

__END__

=pod

=head1 NAME

ignore_addresses.pl - An example of correctly converting string which has an address

=head1 DESCRIPTION

This is an example of correctly converting string which has an address.

Please run this script on an UTF-8 available console,
or redirect STDOUT into a file and open it with an UTF-8 available editor.

=head1 AUTHOR

=over 4

=item MORIYA Masaki, alias Gardejo

C<< <moriya at cpan dot org> >>,
L<http://gardejo.org/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 MORIYA Masaki, alias Gardejo

This script is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.

The full text of the license can be found in the F<LICENSE> file
included with this distribution.

=cut
