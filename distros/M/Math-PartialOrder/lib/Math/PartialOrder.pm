# -*- Mode: Perl -*-

#
# Copyright (c) 2001, Bryan Jurish.  All rights reserved.
#
# This package is free software.  You may redistribute it
# and/or modify it under the same terms as Perl itself.
#

###############################################################
#
#      File: Math::PartialOrder.pm
#    Author: Bryan Jurish <jurish@ling.uni-potsdam.de>
#
# Description: top-level default class for partial orders
#
###############################################################

package Math::PartialOrder;
require 5.6.0;
use Math::PartialOrder::Std;        # the default partial-order subclass
@ISA = qw(Math::PartialOrder::Std);
@EXPORT = qw();
@EXPORT_OK = @Math::PartialOrder::Base::EXPORT_OK;
%EXPORT_TAGS = %Math::PartialOrder::Base::EXPORT_TAGS;

our $VERSION = 0.01;

1;
__END__

#--------------------------------------------------------------------
# Documentation
#--------------------------------------------------------------------
=pod

=head1 NAME

Math::PartialOrder::Base - abstract base class for datatype hierarchies.

=head1 SYNOPSIS

  #
  # Pick your subclass (you only need 1)
  #
  use Math::PartialOrder::Std;        # ok for small hierarchies
  use Math::PartialOrder::Caching;    # caches *everything* in perl hashes
  use Math::PartialOrder::LRUCaching; # uses Tie::Cache for an LRU cache
  use Math::PartialOrder::CMasked;    # for large, static hierarchies
  use Math::PartialOrder::CEnum;      # ... also, but uses less runtime memory

  #
  # Populate your hierarchy
  #
  $h = Math::PartialOrder::Std->new({root=>'whatever'});  # make a new hierarchy

  $h->add('yup');  # 'yup' is a new child-type of 'whatever'
  $h->add('nope'); # ... and so is 'nope'

  $h->add(qw(maybe yup nope));    # 'maybe' inherits from 'yup' and 'nope'
  $h->add(qw(maybenot yup nope)); # ... and so does 'maybenot'

  $h->add(qw(whoknows maybe maybenot)); # 'whoknows' is all of the above

  #
  # Do stuff with it
  #
  @types = $h->types;              # get all the types in the hierarchy
  @yups = $h->descendants('yup');  # ... or just those that are 'yup's
  @kids = $h->children('yup');     # ... or those that are directly 'yup's

  @ancs = $h->ancestors('yup');    # get all ancestors of 'yup'
  @prts = $h->parents('nope');     # ... or just the direct parents

  @sorted = $h->subsort(@types);   # sort @types by inheritance

  #
  # Type Operations
  #
  @lubs = $h->lub(qw(maybe maybenot));  # @lubs = ('whoknows')
  @glbs = $h->glb(qw(yup nope));        # @glbs = ('whatever')

  $lub = $h->njoin(qw(maybe maybenot)); # $lub = 'whoknows'
  $lub = $h->njoin(qw(yup nope));       # ... non-CCPO produces a warning

  $glb = $h->nmeet(qw(yup nope));       # $glb = 'whatever'
  $glb = $h->nmeet(qw(maybe maybenot)); # ... non-CCPO produces a warning

  #
  # Persistence
  #
  use Math::PartialOrder::Loader;

  $h->save('h.gt');      # save to text file
  $h->load('h.gt');      # load from text file

  $h->store('h.bin');    # store binary image
  $h->retrieve('h.bin'); # retrieve binary image

  # ... and much, much (too much) more ....

=head1 REQUIREMENTS

=over 4

=item * Carp

=item * Exporter

=item * Bit::Vector

for the Masked, Enum, CEnum, and CMasked subclasses

=item * FileHandle

for storage/retrieval

=item * Storable

for binary storage/retrieval

=item * GraphViz

for visualization

=item * File::Temp

for online visualization

=back

=head1 DESCRIPTION

The Math::PartialOrder B<class> is just a wrapper for
Math::PartialOrder::Std.

The classes in the Math::PartialOrder B<distribution> all descend
from Math::PartialOrder::Base, and are capable of representing
any finite rooted partial order, although  the single-root
condition is not enforced by Math::PartialOrder::Base itself.

There are a bunch of subclasses of Math::PartialOrder::Base, and they
all do pretty much the same things -- see L<Math::PartialOrder::Base>
for details on what methods are available, their
calling conventions, and what it is exactly that they do.
A brief summary of each of the subclasses is given below.


=head2 Terminology

The Math::PartialOrder distribution was previously known (to some)
as QuD::Hierarchy, since it was designed for the representation
of "datatype hierarchies" or "conceptual hierarchies".  Since
I have very little desire to re-write B<all> of the documentation,
here are some handy synonyms:

   my terminology <-> order-theoretic terminology
      "hierarchy" <-> "partial order"
           "type" <-> "element"
           "root" <-> "bottom element"
         "parent" <-> "covered element"
          "child" <-> "covering element"
   "has ancestor" <-> "is greater than"
 "has descendant" <-> "is less than"

Formal definitions of the order-theoretic terms can be found
in Davey & Priestley (1990).  I hope that my terms are a bit
more intuitive to those familiar with datatype- and class-hierarchy
systems.


=head2 Non-Determinism

For present
purposes, a "non-deterministic" hierarchy is any partial order
which is not "consistently complete".  See Davey & Priestley (1990)
for a definition of CCPOs, or just call the
C<is_deterministic()> method on your hierarchy, and see
what it says.



=head2 Hierarchy Subclasses

The hierarchy subclasses distributed with the
Math::PartialOrder module are briefly described below.
See the individual manpages for details.

=over 4

=item * C<Math::PartialOrder::Std>

Math::PartialOrder::Std is a basic iterative hierarchy
implementation, suitable for use with small hierarchies.
It is the most transparent of all the hierarchy subclasses,
but also the least efficient.

Really, Math::PartialOrder is just an alias for
Math::PartialOrder::Std.

=item * C<Math::PartialOrder::Caching>

Math::PartialOrder::Caching is a hierarchy
implementation for datatype hierarchies which
caches the results of all inheritance- and type-operation lookups using
perl hashes, which improves performance for small- to mid-sized
hierarchies.  It inherits from C<Math::PartialOrder::Std>.


=item * C<Math::PartialOrder::LRUCaching>

Math::PartialOrder::LRUCaching is a Math::PartialOrder implementation for
datatype hierarchies inheriting from Math::PartialOrder::Std, which caches
the results of inheritance- and type-operation-lookups
in a C<Tie::Cache> object, which implements an LRU (least recently used)
cache.  This may improve performance for large hierarchies which
must repeatedly perform the same lookups, or for applications
using localized areas of large hierarchies.


=item * C<Math::PartialOrder::CMasked>

Math::PartialOrder::CMasked is a compiling Math::PartialOrder implementation for
static datatype hierarchies using
Steffen Beyer's Bit::Vector module for hierarchy operations and an internal
representation of immediate inheritance information as 'enum' strings.
It inherits directly from Math::PartialOrder::Base.

This subclass is suitable for mid- to large-sized
hierarchies (E<gt>= 3K types), assuming you don't need to
perform a lot of destructive operations on your hierarchies.
Space usage is on the order O(n^2).

=item * C<Math::PartialOrder::CEnum>

Math::PartialOrder::CEnum is a Math::PartialOrder implementation for
compiled datatype hierarchies using
the Bit::Vector module for hierarchy operations and an internal
representation of hierarchy information as 'enum' strings.

It differs from Math::PartialOrder::CMasked in that while
the CMasked subclass stores compiled hierarchy information
directly as Bit::Vector objects, the CEnum subclass stores
such information as 'enum' strings, which should greatly
reduce space requirements.  Only run-time memory usage
is reduced, however -- compilation still requires the
full O(n^2) as for the CMasked subclass.


=back



=head2 Hierarchy Persistence

The C<Math::PartialOrder::Loader> module adds methods to
the abstract base class C<Math::PartialOrder::Base> for storage and
retrieval of PartialOrder objects, as well as for
hierarchy-visualization.  Hierarchies
may be stored/retrieved as text files, or as binary
images.  Binary hierarchy images are compatible across
all currently implemented subclasses (but compiled information
might not cross-load correctly).  See
L<Math::PartialOrder::Loader> for details.



=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>jurish@ling.uni-potsdam.deE<gt>

=head1 COPYRIGHT

Copyright (c) 2001, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

B. A. Davey and H. A. Priestley,  I<Introduction to Lattices and Order>.
Cambridge University Press, Cambridge.  1990.

perl(1).
Math::PartialOrder::Base(3pm).
Math::PartialOrder::Loader(3pm).
Math::PartialOrder::Std(3pm).
Math::PartialOrder::Caching(3pm).
Math::PartialOrder::LRUCaching(3pm).
Math::PartialOrder::CMasked(3pm).
Math::PartialOrder::CEnum(3pm).
Data::Dumper(3pm).

=cut

#Math::PartialOrder::Masked(3pm).
#Math::PartialOrder::Enum(3pm).




