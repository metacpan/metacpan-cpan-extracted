#
# $Id: Hacker.pm,v 0.1 2006/03/25 12:20:27 dankogai Exp dankogai $
#
package Poem;
use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;

package Another;
sub Just{
    my $another = shift;
    my $perl_hacker = shift;
    my $just = (caller(1))[3] || (caller(0))[3];
    # warn $just;
    $just =~ s/.*:://o;
    "$just $another $perl_hacker";
}
sub Yet { Just(@_) }

package Hacker;
sub Perl{
    my $hacker = shift;
    my $perl = (caller(0))[3];
    $perl =~ s/.*:://o;
    "$perl $hacker";
}
*Porter::Perl = \&Hacker::Perl;
*Poet::Perl   = \&Hacker::Perl;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Just::Another::Perl::Hacker - make Just Another Perl Hacker work

=head1 SYNOPSIS

  use strict;   # Stricture OK!
  use warnings; # Don't worrry, does not warn!
  use Just::Another::Perl::Hacker;
  print Just Another Perl Hacker;

=head1 DESCRIPTION

Did you know the Magic Phrase C<Just Another Perl Hacker> is a
completely valid construct in perl?  Even under stricture and warnings
it parses fine.

But to make it B<really> work, you need this module.  Otherwise perl
complains like C<Can't locate object method "Perl" via package
"Hacker" (perhaps you forgot to load "Hacker"?) at -e line 1.> .

This module uses absolutely no source filter, XS, or other tricks. 
This module is a perfect example of the fact that it takes no tricks
to be a Just Another Perl Hacker!

Other magic phrases that are enabled are:

  Just Another Perl Porter
  Just Another Perl Poet
  Yet Another Perl Hacker
  Yet Another Perl Porter
  Yet Another Perl Poet

=head2 Why not L<Acme::Just::Another::Perl::Hacker> ?

Sorry.  I just couldn't resist.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Poem>, L<Acme::JAPH>, L<Lingua::Romana::Perligata>

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
