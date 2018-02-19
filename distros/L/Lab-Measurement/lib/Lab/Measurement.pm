package Lab::Measurement;
#ABSTRACT: Log, describe and plot data on the fly
$Lab::Measurement::VERSION = '3.620';
use strict;
use warnings;
use Lab::Generic;

use Exporter 'import';
use Lab::XPRESS::hub qw(DataFile Sweep Frame Instrument Connection);
our @EXPORT = qw(DataFile Sweep Frame Instrument Connection);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Measurement - Log, describe and plot data on the fly

=head1 VERSION

version 3.620

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

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Lab::Measurement team; in detail:

  Copyright 2005-2006  Daniel Schroeer
            2011       Andreas K. Huettel
            2012       Alois Dirnaichner, Andreas K. Huettel, David Kalok, Hermann Kraus
            2013       Andreas K. Huettel
            2014       Christian Butschkow
            2016       Andreas K. Huettel, Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
