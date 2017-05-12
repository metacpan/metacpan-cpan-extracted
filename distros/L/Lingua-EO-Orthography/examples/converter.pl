#!perl

use 5.008_001;
use strict;
use warnings;
use utf8;

use Encode;
use Lingua::EO::Orthography;

my $converter = Lingua::EO::Orthography->new;
my $various   = q{C^i-momente, la songha h'orajxo ^sprucigas aplauwdon.};
#                 ==                 ==  ==   ==  ==             ==
#                  ^                  ^   ^    ^  ^               ^
#                  |                  |   |    |  |               |
# post-caret (circumflex)             |   |    |  |               |
# Zamenhof system --------------------+   |    |  |               |
# post-apostrophe ------------------------+    |  |               |
# X-system ------------------------------------+  |               |
# pre-caret (circumflex) -------------------------+               |
# extended H-system ----------------------------------------------+

my $orthographic = $converter->convert($various);

$converter->sources([qw(orthography)]);
$converter->target('postfix_x');
my $x_systematic = $converter->convert($orthographic);

my $utf8 = find_encoding('utf8');
print $utf8->encode("Various:      $various\n");
print $utf8->encode("Orthographic: $orthographic\n");
print $utf8->encode("X-systematic: $x_systematic\n");

__END__

=pod

=head1 NAME

converter.pl - An example of converting string with Lingua::EO::Orthography

=head1 DESCRIPTION

This is an example of converting string with
L<Lingua::EO::Orthography|Lingua::EO::Orthography>.

Please run this script on an UTF-8 available console,
or redirect STDOUT into a file and open it with an UTF-8 available editor.

Note: Such sentence means "In this moment, the dreamy chorus spurts applause."

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
