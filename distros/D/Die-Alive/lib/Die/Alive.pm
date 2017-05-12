#############################################################################
## Name:        Alive.pm
## Purpose:     Die::Alive
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-02-27
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Die::Alive ;
use 5.006 ;

use strict qw(vars);

use vars qw($VERSION) ;

$VERSION = '0.01' ;

sub BEGIN { *CORE::GLOBAL::die = \&DIE_2_WARN ;}

sub DIE_2_WARN {
  if ( $^S ) { CORE::die(@_) ;}
  else { warn(@_) ;}
}

#######
# END #
#######

1;


__END__

=head1 NAME

Die::Alive - Make die() to not exit the Perl interpreter, but keep the die() behavior inside eval.

=head1 DESCRIPTION

This module when loaded will make the function die() to not exit the Perl interpreter,
but it will keep the die() behavior inside eval, making it to go out of an eval block.

=head1 USAGE

  use Die::Alive ;

  die("This die() won't exit!") ;
  print "And here we continue the app...\n" ;
  
  eval {
    die("Calling die() inside eval!");
    print "And this print won't be executed.\n" ;
  } ;
  
  print "ERROR: $@\n" ;

=head1 SEE ALSO

L<No::Die>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

