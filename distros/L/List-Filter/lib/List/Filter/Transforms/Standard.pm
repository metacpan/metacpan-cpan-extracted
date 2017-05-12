package List::Filter::Transforms::Standard;

=head1 NAME

List::Filter::Transforms::Standard - standard List::Filter transform methods

=head1 SYNOPSIS

   # This module is not intended to be used directly
   # See: L<List::Filter::Dispatcher>

=head1 DESCRIPTION

This module defines the standard List::Filter transform methods,
such as "sequential", which simply performs in order each
find-and-replace specified inside the transform.

This is the "transform" analog of L<List::Filter::Filters::Standard>.

=head2 METHODS

=over

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;

our $VERSION = '0.01';

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
                  sequential
               );

=item new

Instantiates a new List::Filter::Transform::Internal object.

Takes an optional hashref as an argument, with named fields
identical to the names of the object attributes.

With no arguments, the newly created transform will be empty.

=cut

# Note:
# This "new" is inherited from Class::Base
# It calls the "init" routine automatically.

=item init

Initialize object attributes and then lock them down to prevent
accidental creation of new ones.

Note: there is no leading underscore on name "init", though it's
arguably an "internal" routine (i.e. not likely to be of use to
client code).

=cut

# init is inherited also, though oddly enough it comes
# from the Dispatcher -- because in the present plugin architecture,
# the following methods are exported to the Dispatcher object (via Exporter).

=back

=head2 List::Filter transform methods

The methods that apply a list of transforms.  Each List::Filter
transfrom specifies one of these methods to use by default.

They all have identical interfaces: they take two input
arguments, a List::Filter transform and a reference to a list of
strings to be modified. These methods all return an array
reference of strings that have been modified by the transform method.

=over


=item sequential

Inputs:
(1) a List::Filter::Transform object
       (which contains a list of substitutions to be performed)
(2) an arrayref of strings to be transformed
(3) an options hash reference:

   Supported option(s):
   override_modifiers

Return: an arrayref of the modified strings.

Note: invalid regular expression modifiers are silently ignored.

=cut

sub sequential {
  my $self       = shift;   # Note: this will be the *dispatcher* object
  my $transform  = shift;
  my $items      = shift;
  my $opt        = shift;

  # making a working copy of the items
  my @work       = @{ $items };

  use List::Filter::Transform::Internal;
  my $lftu = List::Filter::Transform::Internal->new(
                                           override_modifiers => $opt->{ override_modifiers },
                                           );

  # accumulate changes in @work from each s/// of the transform, on
  # each given item (through the magic of perl aliases)
  foreach my $item (@work) {

    # Munge the pieces in the array of transform terms to build up a s///
    my $global_mods = $opt->{ override_modifiers };
    my $terms       = $transform->terms;
    foreach my $term (@{ $terms }) {

      $item = $lftu->substitute( $item, $term );   # method of a utility object, $lftu

    } # end foreach $term
  } # end foreach $item

  # return array of transformed strings
  return \@work;
} # end sub sequential

1;

=back

=head1 MOTIVATION

The motivation for this module's existence is simple parallelism: this
is the "transform" analog of L<List::Filter::Filters::Standard>.  The
case is perhaps not as strong for the existance of this module, since
the "sequential" method is all that's really likely to be needed, but
one of the goals of this project is "pathological extensibility",
so I've tried to hold the door open to the possibility that there's
a reason for something besides "sequential" application of a transform.

=head1 SEE ALSO

L<List::Filter>

=head1 TODO

Write additional methods:

=over

=item reverse

like sequential, but in reverse order

=item shuffle

apply in random order

=item length_sorted

apply regexps in order of length of the regexp
(doing it in order of length of matches would be better, but more
difficult).

=item no_chained_changes

like sequential, but verifies that later matches don't match
something in the replace field of an earlier substitution.  That
often (though not always) indicates a bug

=back

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
