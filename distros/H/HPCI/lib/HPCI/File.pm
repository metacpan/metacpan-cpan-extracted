package HPCI::File;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;

use Moose;

use MooseX::Types::Path::Class qw(Dir File);

=head1 NAME

    HPCI::File;

=head1 SYNOPSIS

An object that describes a file to be used by a stage.  It includes
the path to the file, whether the file must be maintained on a
separate long-term storage that is different from the access path
used by the stage program (and if so, how to copy the file between
the long-term storage and the working storage, and whether copying
can be done by the parent program or must be done by the stage).

The stage attribute C<files> contains descriptive info about file
management for the stage - most of it component sections include a
file.  That file can be either specified as a string, or with an
object that is HPCI::File or a sub-class thereof.  A bare string
will normally be converted to an HPCI::File object, but the C<stage>
can contain a C<fileclass> attribute string that over-rides that
default, and additionally, the files attribute can contain a
C<fileclass> component that over-rides either of those defaults for
the one stage.

=cut

has 'file' => (
    is      => 'ro',
    isa     => File,
    coerce  => 1
);

use overload '""' => '_stringify';

sub _stringify {
    "" . (shift->file);
}

=pod

=head1 Storage management

HPCI has two types of storage that it can deal with.

Long-term storage is storage that is reliably preserved over time.
The data in long-term storage is accessible to all nodes on the
cluster.

Working storage is storage that is directly-accessible to a node.
It can be a private disk that is not accessible to other nodes,
or it can be a shared file system that is available to other nodes.

Some types of cluster can have their nodes rebuilt at intervals,
losing the data on their local disks.

Some types of cluster have no shared file system, or have size
limitations on their shared file system.

There are three scenarios:

=over 4

=item fully-shared

When there is a reliable, fully-shared file system that has no
limitations to prevent it being used for the data, then files
can be on that file system.  The same path will refer to the
long-term and working locations.

=item partially-shared

When there is a fully-shared file system that is not reliable for
long-term storage, it might be used as working storage.  That
allows the parent process to carry out operations on the files for
the stage, and allow skipping the download of files that B<are>
still present when the storage has not been cleared.

=item node-private

When it is necessary to use storage that is only accessible by the
individual node for working storage, the the stage program must
carry out all upload and download operations, as well as any
validation checks that require data access to the file.

=back

This class has two methods that specify the storage scenario that it
provides.

=head2 method has_long_term

The method C<has_long_term> specifies whether this file uses a separate
long-term storage facility that is distinct from the working storage
that will be used by the stage for direct reading and/or writing.

=head2 method has_shared_storage

The method C<has_shared_storage> specifies whether the working storage location
used by the stage is also accessible to the parent program and/or other stages.

=head2 Settings to indicate storage scenario

                         has_long_term   has_shared_storage
                       +---------------+--------------------+
    fully-shared       |     false     |       true         |
                       +---------------+--------------------+
    partially-shared   |     true      |       true         |
                       +---------------+--------------------+
    node-private       |     true      |       false        +
                       +---------------+--------------------+

Subclasses of this class will over-ride these methods to specify
alternative values appropriate to the particular subclass.

Note that setting both methods to return false is not a workable
process - that would imply that there is no storage type that
allows passing data between stages.

=cut

sub has_long_term {
    0;    # over-ridden in sub-classes as appropriate
}

sub has_shared_working_storage {
    1;
}

sub exists {
    my $self = shift;
    my $stat = $self->file->stat;
    $stat && -e $stat
}

# sub exists_script {
    # return "-e $_[0]";
# }

sub timestamp {
    my $self = shift;
    my $stat = $self->file->stat // return undef;
    -e $stat ? -M $stat : undef;
}

# do nothing for the normal case
# but over-ride to copy when long-term storage is not working storage
sub accepted_for_out {
    1;
}

sub delete {
    $_[0]->file->remove;
}

sub rename {
    my $self   = shift;
    my $target = shift;
    $self->file->move_to( $target );
}

package HPCI::File::Classes;

use MooseX::Role::Parameterized;
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

sub generator {
	my ($class,@args) = @_;
	return sub { $class->new( file => $_[0], @args ) };
}

subtype 'HPCIFileGen',
    as 'CodeRef';

coerce 'HPCIFileGen',
    from 'Str',      via { _create_HPCIFileGen(  $_ ) },
    from 'ArrayRef', via { _create_HPCIFileGen( @$_ ) };

sub _create_HPCIFileGenHash {
    my $key = shift;
    return { $key => _create_HPCIFileGen( @_ ) };
}

subtype 'HPCIFileList',
    as 'ArrayRef[HPCIFileGenHash]';

coerce 'HPCIFileList',
    from 'ArrayRef[ArrayRef[Str]]', via { _create_HPCIFileGenHash( @$_ ) for @$_ };

has 'storage_classes' => (
    is      => 'ro',
    isa     => 'HPCIFileList',
    default => sub { [ ] },
    coerce  => 1,
);


1;
