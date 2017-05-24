
package Lab::Measurement;
our $VERSION = '3.543';

use strict;
use warnings;
use Lab::Generic;

use Exporter 'import';
use Lab::XPRESS::hub qw(DataFile Sweep Frame Instrument Connection);
our @EXPORT = qw(DataFile Sweep Frame Instrument Connection);

1;

__END__

=encoding utf8

=head1 NAME

Lab::Measurement - Log, describe and plot data on the fly

=head1 SYNOPSIS

  use Lab::Measurement;
  

=head1 DESCRIPTION

This module distribution simplifies the task of running a measurement, writing 
the data to disk and keeping track of necessary meta information that usually 
later you don't find in your lab book anymore.

If your measurements don't come out nice, it's not because you were using the 
wrong software. 

The entire stack can be loaded by a simple 

  use Lab::Measurement;

command; further required modules will be imported on demand.

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS>

=item L<http://www.labmeasurement.de>

=back

=head1 AUTHOR/COPYRIGHT

 Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>)
 Copyright      2016 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
