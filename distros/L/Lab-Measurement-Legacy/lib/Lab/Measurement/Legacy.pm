package Lab::Measurement::Legacy;
$Lab::Measurement::Legacy::VERSION = '3.904';
#DistZilla: +PodWeaver
#ABSTRACT: Log, describe and plot data on the fly (legacy code)

use v5.20;

use strict;
use warnings;
use Lab::Generic;
use Carp;

use Exporter 'import';
use Lab::XPRESS::hub qw(DataFile Sweep Frame Instrument Connection);
our @EXPORT = qw(DataFile Sweep Frame Instrument Connection);

carp <<"EOF";
\"use Lab::Measurement::Legacy;\" imports the legacy interface of Lab::Measurement.
Please consider porting your measurement scripts to the new, Moose-based code.
Documentation can be found at https://www.labmeasurement.de/
EOF
1;

__END__

=pod

=encoding UTF-8

=head1 SYNOPSIS

  use Lab::Measurement::Legacy;

However, by now you probably want to use the following instead:

  use Lab::Moose;

=head1 DESCRIPTION

The Lab::Measurement::Legacy module belongs to a deprecated legacy module
stack, frozen and not under development anymore. Please port your code to the new
API; its documentation can be found on the Lab::Measurement homepage.

=head1 SEE ALSO

=over 4

=item L<Lab::Measurement::Manual>

=item L<Lab::Measurement::Tutorial>

=item L<Lab::Measurement::Roadmap>

=item L<https://www.labmeasurement.de/>

=back

=cut
