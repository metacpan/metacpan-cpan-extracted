package Lab::Measurement;
$Lab::Measurement::VERSION = '3.931';
#ABSTRACT: Temporary blocker module, errors out when used

use v5.20;

use strict;
use warnings;
use Carp;

croak <<"EOF";

\"use Lab::Measurement;\" previously imported the legacy interface of Lab::Measurement.
This interface was deprecated in 2018 and has now, six years later, been removed.

Please consider porting your measurement scripts to the current, Moose-based API.
Documentation on how to do this can be found at https://www.labmeasurement.de/

If you absolutely cannot port your scripts, then your only alternative is an archived
version of the old code (without support or any further development) available on CPAN
as Lab::Measurement::Legacy. You will need \"use Lab::Measurement::Legacy;\" then.

EOF

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Measurement - Temporary blocker module, errors out when used

=head1 VERSION

version 3.931

=head1 SYNOPSIS

  use Lab::Measurement;

=head1 DESCRIPTION

This module used to load the legacy API interface of Lab::Measurement, which has now
been removed from the package. Now the module just prints an error message and exits, 
to make clear that the script code is not compatible with the current
library version.

Please consider porting your measurement scripts to the current, Moose-based code.
Documentation can be found at L<https://www.labmeasurement.de/>.
Your script should then contain, at least for the moment, at its start

  use Lab::Moose;

With the release of Lab::Measurement 4.000, this error will be removed and
the Lab::Measurement module will be changed to automatically import the new
API.

=head1 EMERGENCY

If you absolutely cannot port your scripts, then you can find an archived version
of the old code without support or any further development on CPAN as 
L<Lab::Measurement::Legacy>. Install it and modify your script to start with

  use Lab::Measurement::Legacy;

=head1 SEE ALSO

=over 4

=item L<Lab::Measurement::Manual>

=item L<Lab::Measurement::Tutorial>

=item L<Lab::Measurement::Roadmap>

=item L<https://www.labmeasurement.de/>

=item L<Lab::Measurement::Legacy>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by the Lab::Measurement team; in detail:

  Copyright 2005-2006  Daniel Schroeer
            2011       Andreas K. Huettel
            2012       Alois Dirnaichner, Andreas K. Huettel, David Kalok, Hermann Kraus
            2013       Andreas K. Huettel
            2014       Christian Butschkow
            2016       Andreas K. Huettel, Simon Reinhardt
            2017-2018  Andreas K. Huettel
            2019       Simon Reinhardt
            2023-2024  Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
