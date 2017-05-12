package FTDI;

use 5.008008;

use strict;
use warn;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.01';


use FTDI::D2XX;


1;
__END__

=head1 NAME

FTDI - Perl extensions for interface to FTDI Chips 

=head1 DESCRIPTION

This module is basis for a collection of perl modules to interface with
the USB interface ICs from FTDI. 

Starting point is the XS implementation of an interface to the D2XX library.

=head1 SYNOPSIS

  use FTDI; # is equivalent to

  use FTDI::D2XX;

=head1 AUTHOR

Matthias Voelker, E<lt>mvoelker@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Matthias Voelker
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
