package Gcode::Interpreter;

use strict;
use warnings;

use Exporter;
use vars qw($VERSION @ISA);

$VERSION     = 1.0.1;
@ISA         = qw(Exporter);

use Gcode::Interpreter::Ultimaker;

sub new {
  my $class = shift(@_);

  my $machine_type = shift(@_);

  die "Unsupported machine type '$machine_type'\n" if($machine_type && $machine_type ne 'Ultimaker');

  return Gcode::Interpreter::Ultimaker->new(@_);
}

sub position {
  return [undef,undef,undef,undef];
}

sub stats {
  return {'duration' => undef, 'extruded' => undef};
}

sub process_line {
  return 0;
}

1;

__END__

=pod

=head1 NAME

Gcode::Interpreter - Simulate Gcode-reading machines such as 3D printers, CNC mills etc.

=head1 SYNOPSIS

  use Gcode::Interpreter;

  $interpreter = Gcode::Interpreter->new();

  $interpreter->parse_line('G1 X1.0 Y1.0 Z1.0 E1.0');

  $position_ref = $interpreter->position();

  $stats_ref = $interpreter->stats();

=head1 DESCRIPTION

This module is an umbrella class for those below it. That is, apart from
to provide a stub, this module really hands off the real work elsewhere.

At the moment, there is only one such sub-module, for the Ultimaker series
of 3D printers. It's possible that other printer types, CNC machines and
other Gcode-talkers could be added at a later date. If that happens, then
it is likely that the specifics of this module will change to become a
generic super-set of all the sub-modules.

For now, the constructor for this module returns a Gcode::Interpreter::Ultimaker
object, which then provides the real implementation of the methods described
below.

=head1 METHODS

=over 2

=item new
X<new>

The constructor currently just returns a Gcode::Interpreter::Ultimaker object.

Takes a string argument that is the name of the sub-object. At present, if it's
not 'Ultimaker' then the constructor die()s. If it's either missing or 'Ultimaker'
then a Gcode::Interpreter::Ultimaker object is returned.

=item position
X<position>

This is a stub method that just returns a reference to a list of four elements,
each of which is 'undef'.

=item stats
X<stats>

This is a stub method that just returns a reference to a hash with two keys,
'duration' and 'extruded', both of which have 'undef' values.

=item process_line
X<process_line>

This is a stb method that takes a string argument and always returns false.

=back

=head1 SEE ALSO

Gcode::Interpreter::Ultimaker

=cut

# This is for Vim users - please don't delete it
# vim: set filetype=perl expandtab tabstop=2 shiftwidth=2:
