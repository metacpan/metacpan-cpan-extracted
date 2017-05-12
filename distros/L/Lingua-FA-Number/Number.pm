##################################################
# Lingua::FA::Number
#
# Ahmad Anvari, 2003
##################################################

package Lingua::FA::Number;

use strict;
use warnings;
use Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.00';

# Preloaded methods go here.


sub convert { 
  $_ = shift; 
  s/(\d)/"&#".(1728+ord($1)).";"/eg; # farsiaze digits
  return $_;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lingua::FA::Number - Converts English numbers to their Persian (Farsi) HTML/Unicode equivalent

=head1 SYNOPSIS

  use Lingua::FA::Number;
  print Lingua::FA::Number::convert ("1 2 3 4");

=head1 ABSTRACT

  This module converts the English numbers to their Persian (Farsi) HTML/Unicode equivalent

=head1 DESCRIPTION

  Converts all occurences of numbers in a string to their Persian (Farsi) HTML/unicode equivalents

  HTML portion is done for now.

=head2 EXPORT

None by default.

=head1 SEE ALSO

http://www.cpan.org/

=head1 AUTHOR

Ahmad Anvari <http://www.anvari.org/bio/>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ahmad Anvari

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
