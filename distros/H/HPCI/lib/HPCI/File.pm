package HPCI::File;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use YAML qw/LoadFile DumpFile/;
use Digest::MD5::File qw(file_md5_hex);

use Moose;

use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

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

=head1 ATTRIBUTES

=head2 file

The name of the file.

=cut

has 'file' => (
    is      => 'ro',
    isa     => File,
    coerce  => 1
);

=head2 abs_file

The absolute pathname of the file. Not fully used yet.

=cut

has 'abs_file' => (
    is       => 'ro',
    isa      => File,
    lazy     => 1,
    init_arg => undef,
    default  => sub { $_[0]->file->absolute },
);

use overload '""' => '_stringify';

sub _stringify {
    # "" . (shift->file);
    "" . (shift->abs_file);
}


=head2 sum

Boolean, indicates whether checksums are used for this file.  If they are,
the checksum is kept in a YAML file B<file>.sum.  This YAML file contains
an array of hashes.  Each hash has the keys 'type' and 'sum'. For each checksum
type requested (default is 'md5' at present, will expand to include 'sha1' in
the future) there is an entry in the array containing the checksum computed for
the corresponding method.

=cut

has 'sum' => (
    is      => 'ro',
    isa     => 'Bool',
    default => '',
);

has '_sum_file' => (
    is       => 'ro',
    isa      => File,
    lazy     => 1,
    init_arg => undef,
    coerce   => 1,
    default  => sub {
        my $self = shift;
        # return undef unless $self->sum;
        my $file = $self->file;
        my $dir  = $file->dir;
        my $base = $file->basename;
        return "$dir/$base.sum";
    },
);

=head2 sum_generate_in

A boolean value, default is false.

Specifies the action taken if the file is used for input and the
B<file>.sum checksum file is either not present or if it is older than B<file>.

When B<false> is specified, the stage is failed.

When B<TRUE> is specified, the checksum is computed and B<FILE>.sum is saved,
and then the stage is allowed to run normally.

The default is B<FALSE> to ensure that changes to input data files are
done deliberately - an accidental edit should be considered an error.

You would set the value to B<TRUE> when first receiving a newly downloaded
file from an outside source.  When a file is created as an 'out' file, the
sum is always created (if the B<sum> attribute is true), so the default of
B<FALSE> does not cause problems for later stages.

=cut

has 'sum_generate_in' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head2 sum_validate_in

This can be given a string ('timestamp', 'once', 'always') to indicate how
vigourously the checksum is validated.

The default is 'once'.

The setting 'timestamp' accepts the file as valid if the B<file>.sum files exists
and is newer than B<file>.  (If it is older, then B<sum_generate_in> controls
how it is handled.)

The setting 'once' loads the B<file>.sum data, and verifies the checksum(s)
explicitly the first time the file is used for input, but accepted as valid
after that point of the tiemstamps have not changed.  (This avoids recomputing
the checksum(s) for every stage that reuses the same file.

The setting 'always' validates the checksum(s) for every stage that uses the
file.

=cut

enum 'ValidateIn', [qw(timestamp once always)];

has 'sum_validate_in' => (
    is      => 'ro',
    isa     => 'ValidateIn',
    default => 'once',
);

has '_sum_info' => (
    is      => 'rw',
    isa     => 'Maybe[ArrayRef[HashRef]]',
);

has '_sum_status' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { return {} },
    init_arg => undef,
);

=head2 _shared

This is an internal attribute that specifies that the file is located
on a file system that is shared by all of the nodes in the cluster.
This value is over-ridden by subclasses of HPCI::File which provide
for files which are not on a shared file system.
Such subclasses must provide for get and put methods to copy files
between the local filer system and a repository that B<is> accessible
from all nodes (although not necessarily on the file system).
They will also define their own addition attributes
as needed to provide the details of accessing the 

=cut

has '_shared' => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    default  => 1,
);

has 'stage'  => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
    weak_ref => 1,
    handles  => {
        debug      => 'debug',
        info       => 'info',
        warn       => 'warn',
        error      => 'error',
        fatal      => 'fatal',

        _file_info => '_file_info',
    },
);

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

sub exists_base_file {
    my $self = shift;
    my $stat = $self->file->stat;
    return $stat && -e $stat;
}

sub exists_valid_sum {
    my $self = shift;  # the file for $self must exists
    $self->sum or return 1;  # if sum is turned off, it is valid by default
    my $file  = $self->file;
    my $fts   = file_timestamp( $file );
    my $sfile = $self->_sum_file;
    my $sts   = file_timestamp( $sfile );
    my $fi    = $self->_file_info->{"".$self->file} //= {};
    if ($sts && $sts <= $fts) {
        # sum file is up to date - determie whether we need to validate the value this time
        my $vi = $self->sum_validate_in;
        return 1 if $vi eq 'timestamp';
        return 1 if $vi eq 'once' && exists $fi->{sum_ts} && $fi->{sum_ts} == $sts;
        my $filesum = $fi->{sum} //= LoadFile($sfile);
        $fi->{sum_ts} = $sts;
        $self->_croak( "sum file ($sfile): multiple checksum types not supported yet" )
            if 1 != scalar @$filesum;
        my $type = $filesum->[0]{type};
        my $sum  = $filesum->[0]{sum};
        $self->_croak( "sum file ($sfile): checksum type other than MD5 ($type) not supported yet" )
            if $type ne 'MD5';
        my $actsum = file_md5_hex($self->file);
        if ($sum ne $actsum) {
            $self->error( "sum file ($sfile): computed checksum does not match" );
            return 0;
        }
        return 1;
    }
    else {
        # sum file missing or old - determine whether to (re)create it or abort
        if ($self->sum_generate_in) {
            my $filesum = $fi->{sum} = [];
            $filesum->[0]{type} = 'MD5';
            $filesum->[0]{sum}  = file_md5_hex($self->file);
            DumpFile( $sfile, $filesum );
            $fi->{sum_ts} = file_timestamp( $sfile );
            $self->warn( "sum file ($sfile): (re-)generated sum for input file" );
            return 1;
        }
        else {
            $self->error( "sum file ($sfile): missing or out of date" );
            return 0;
        }
    }
}

sub valid_in_file {
    my $self = shift;
    return $self->exists_base_file && $self->exists_valid_sum;
}

sub exists_out_file {
    my $self = shift;
    return $self->exists_base_file;
}

sub file_timestamp {
    my $file = shift;
    my $stat = $file->stat // return undef;
    -e $stat ? -M $stat : undef;
}

sub timestamp {
    file_timestamp( $_[0]->file );
}

# generate a sum file is desired
# but extend to copy when long-term storage is not working storage
sub accepted_for_out {
    my $self = shift;
    if ($self->sum) {
        my $info = {};
        my $sfile = $self->_sum_file;
        $info->{type} = 'MD5';
        $info->{sum}  = file_md5_hex($self->file);
        DumpFile( $sfile, [ $info ] );
        $self->info( "sum file ($sfile): generated sum for output file" );
    }
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
	return sub { $class->new( file => @_, @args ) };
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
