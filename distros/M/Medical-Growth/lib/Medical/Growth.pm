#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

package Medical::Growth;

our ($VERSION) = '1.00';

use Module::Runtime;
use Module::Pluggable
  search_path => 'Medical::Growth',
  require     => 0,
  only        => qr/^Medical::Growth::\w+$/,
  except      => 'Medical::Growth::Base';

sub measure_class_for {
    my $self = shift;
    my (%criteria) = @_ == 1 ? %{ $_[0] } : @_;
    return unless $criteria{system};
    my $class = $criteria{system};
    $class = "Medical::Growth::$class"
      unless $class =~ /^Medical::Growth::/;
    Module::Runtime::use_module($class)->measure_class_for(%criteria);
}

sub available_systems {
    shift->plugins;
}

1;

__END__

=head1 NAME

Medical::Growth - Basic tools for growth-dependent norms

=head1 SYNOPSIS

  use Medical::Growth;
  my(@systems) = Medical::Growth->available_systems;
  my $meas = Medical::Growth->measure_class_for(system => My::System,...)
  my $z_score = $meas->value_to_z($value, @criteria);

=head1 DESCRIPTION

F<Medical::Growth> is designed as a common resource for implementing
systems of growth-dependent norms.  It provides a set of basic tools
for operating on normally distributed data, as well as a common entry
point for users of L<Medical::Growth>-compatible systems.

If you're interested in using a F<Medical::Growth>-compatible
measurement system, read on.  If you're interested in building a
measurement system, you may also want to see L<Medical::Growth::Base>,
which contains some tools to facilitate the process.

=head2 USING MEASUREMENT SYSTEMS

In conceptual terms, a collection of methods that allows you to compare
a measured value to a set of norms is called a B<measurement system>.
For instance, the models for anthropometric values based on the NHANES
2000 survey, from which growth charts in common use in pediatrics were
created, is a measurement system.

In pragmatic terms, a measurement system is a collection of classes
that present a common set of ways to compare a measurement to norms.
Each specific comparison is done via a B<measurement class>, which
provides an interface for a specific set of norms.  To continue the
NHANES 2000 example, a measurement class would correspond to a single
growth chart, that is, the collection of norms to which you would
compare a specific value.  Thus, weight for age in boys 2-20 years old
would be a measurement class, while length for age in girls under 3
would be a separate measurement class.  In some cases, such as these,
a measurement class will need to know only one value (here, age) in
addition to the measurement to return the normalized score.  In
others, it may need several additional pieces of information.  Where
to draw the boundary between different measurement classes and a
single measurement class using multiple indices may be different for
different measurement systems, and reflects the best interface design
for common use.

F<Medical::Growth> provides two methods to simplify interactions with
measurement systems:

=head2 METHODS

=over 4

=item B<available_systems>

Returns a list of the names of measurement systems installed in the
F<Medical::Growth> hierarchy.

=item B<measure_class_for>(I<%criteria>)

Locate a measurement class that performs the function specified by
I<%criteria>, and return a handle that allows you to call methods from
the measurement class.  This is provided as a common entry point to
make finding measurement classes easier.  Although nothing stops you
from hard-coding the name of the measurement class directly, finding
it via L</measurement_class_for> may help keep your code more
readable, and may let you take advantage of shortcuts provided by the
measurement system.

Most of the work is done by the L</measurement_class_for> method in
each measurement system, since it requires detailed knowledge of how a
particular measurement system is implemented.  The F<Medical::Growth>
version of this method uses the value in I<%criteria> associated with
the key C<system> to identify the measurement system you want.  This
value can be the full name of a measurement system's top-level class,
as returned by L<available_systems>, or it may be an abbreviated name
without the leading C<Medical::Growth::>.  The top-level class for the
measurement system is loaded, if necessary, and its
L</measurement_class_for> method is called, with I<%criteria> as
arguments. It is up to the measurement system's
L</measurement_class_for> to interpret the rest of I<%criteria> and
return the appropriate handle.

If the C<system> element is missing from I<%criteria> or the class
cannot be loaded, an exception is thrown.

=back

=head2 EXPORT

None.

=head1 DIAGNOSTICS

Any message produced by an included package.

=over 4

=item B<No measure_class_for() method found> (F)

L<Medical::Growth::measure_class_for> found a measurement system
matching the C<system> specified and loaded its top-level module, but
that module didn't provide a system-specific C<measure_class_for> to
pick a measurement class.

=back

=head1 BUGS AND CAVEATS

Are there, for certain, but have yet to be cataloged.

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Charles Bailey.

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=head1 ACKNOWLEDGMENT

The code incorporated into this package was originally written with
United States federal funding as part of research work done by the
author at the Children's Hospital of Philadelphia.

=cut
