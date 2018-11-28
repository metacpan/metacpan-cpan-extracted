package HPCI::Subgroup;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use File::ShareDir;
use File::Path qw(make_path);
use File::Spec;
use Time::HiRes qw(usleep gettimeofday);
use Try::Tiny;
use DateTime;
use Module::Load;
use HPCI::File;

use Moose;
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

## no critic BoutrosLab::HangingComma
## no critic BoutrosLab::IndentationCheck
sub BUILD {
};

with
    'HPCI::Sub',
    'HPCI::Super',
    'HPCI::SuperSub',
;

=head1 NAME

    HPCI::Subgroup

=head1 SYNOPSIS

Treat a collection of stages and/or subgroups like a single stage.

=head1 DESCRIPTION

A subgroup is a collection of stages and/or subgroups.
It acts both as a group and as a stage:

=over 4

=item 1

It acts as a stage to the group or subgroup that contains it, except
that it is created using the parent group or subgroup's C<subgroup>
method instead of the C<stage> method.  The child subgroup's name
can be provided to the parent group or subgroup's C<add_deps>
method to specify order dependency between the subgroup (i.e.
all of its component stages and/or subgroups treated as a single
unit) and other components of the parent.

=item 2

It acts as a group to the stages and/or subgroups that it contains.
For example, it has C<stage>, C<subgroup>, and C<add_deps> methods.

=back

There are a number of purposes to using a subgroup.

=over 4

=item 1

The subgroup can be used for assigning a dependency.  A prerequisite
to a subgroup must complete before any of the components of the
subgroup can commence; a dependent to a subgroup cannot commence
until all of the components of the subgroup have completed.

=item 2

The subgroup can list file requirements that apply to the collection.
That can define the attributes of files used in multiple stages; can
specify B<in> files that must be present before the subgroup can start;
specify B<skip> conditions that will cause the entire subgroup to
be skipped; specify B<out>, B<delete>, or B<rename> files to be verified
or processed when the subgroup has completed.

=item 3

Allow different stages to use the "same" name.  The name must still
be different from the names of all stages (and subgroups) that can
be dependency targets.  That includes its parent (sub)group and all of
its other top level components, its grandparent (sub)group and all of its
top level components, and similarily for great**n grandparent groups and
all of their top level components.  So, it cannot have to same name as a
sibling, (great)*parent, or (great)*uncle, but it can have the same name
as cousins and more distantly connected components.

The full name used for a stage or subgroup is actually composed like a
pathname, using the group and parent subgroups and the final component
name all separated by slashes.  (e.g. GROUP/SUBGROUP/STAGE)

=back

When a subgroup is specified as a dependency,
none of its component stages or subgroups
execute until prerequisite components have completed;
and all of its component
stages and subgroups must have finished before any
dependent component will be allowed to execute.

A subgroup is creating using the subgroup method of either a
group or subgroup object.

=head1 ATTRIBUTES

The attributes for this class are pulled in from HPCI::Super
and HPCI::Sub. Super contains all the characteristics common to
container classes (Group and Subgroup), while Sub contains all
the characteristics common to contained classes (Subgroup and Stage).

=cut

=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros http://www.omgubuntu.co.uk/2016/03/vineyard-wine-configuration-tool-linuxLab

The Ontario Institute for Cancer Research

=cut

1;

