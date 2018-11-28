package HPCI::Sub;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw(Dir);

# with 'HPCI::SuperSub';

=head1 NAME

    HPCI::Sub

=head1 SYNOPSIS

Role for methods and attributes common to subgroup and stage classes
(i.e. those subordinate to a group-like class).

=head1 ATTRIBUTES

=head2 cluster (internally provided)

The type of cluster that will be used to execute the subgroup
or stage.  This value is passed on by the $group->stage or
$group->subgroup method when it creates a new child.  Since it
also uses that value to select the type of stage object that is
created, it is somewhat redundant.

=cut

has 'cluster' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 group

The group or subgroup object that has this object as a child.

The group that this object belongs to is automatically provided to
initialize this attribute.  You don't need to initialize it explicitly,
and since its use is expected to be internal, you won't have much, if
any, need to use it either.

=cut

has 'group' => (
    is       => 'ro',
    isa      => 'Object',
    weak_ref => 1,
    required => 1,
    handles  => [
        qw(
            debug info warn error fatal

            _stages _subgroups _deps _pre_reqs _blocked _ready

            file_system_delay
            _register_subgroup
            _register_stage
            _execution_started
        )
    ],
);

sub _croak {
    my $self = shift;
    my $msg  = shift;
    $msg = "Stage(" . $self->name . "): $msg";
    $self->fatal($msg);
    confess $msg;
}

=head2 name

The name of this subgroup or stage.

All stages and subgroups must have names that are different from
each other, from all of their (grand)parent groups and from all
of the siblings of their (grand)parent groups.  Stages or subgroups
may have the same name only if they are at most cousins.

=cut

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

after BUILD => sub {
    my $self = shift;
    $self->group->_register_descendent($self);
};

=head2 base_dir (optional) move stuff from Role to here

The directory that will contain all generated output (unless
that output is specifically directed to some other location).
The default is the current directory.

=cut

    has 'base_dir' => (
        is => 'ro',
        isa     => 'Path::Class::Dir',
        coerce  => 1,
        default => sub {
            my $self = shift;
            Dir->new( '.' );
        },
    );

=head2 files

A hash that can contain lists of files.

Throughout this hash, there are filenames contained within hash elements
that describe the processing required for that file.  Whenever a filename
is needed, it can either be a string containing a pathname, or it can be
an HPCI::File object (or subclass), or it can be a HashRef.  Often, it
will be the string form, which will be converted to an object internally.

The top level of the hash has keys 'in' (for input), 'out' (for output),
'skip', 'skipstage', 'rename', and 'delete'.
(The same file might be listed under multiple keys.)

The values for these keys are:

=over 4

=item 'in'

a hashref with possible keys:

    'req' (for required input files)
    'opt' (for required output files)

The value for either of these can be either a filename or a list of filenames.

When a C<subgroup> or C<stage> containing any files/in entries is ready to
be executed, HPCI checks whether the listed files exist.  If one that is
C<req> does not exist, the stage or subgroup is aborted.  Any files that
do exist can get additional validation as specified in the associated
C<HPCI::File> subclass for the file - for example, checksum files can
be generated or verified.

=item 'out'

a hashref with possible keys:

    'req' (for required output files)
    'opt' (for required output files)

The value for either of these can be either a filename or a list of filenames.

When a C<subgroup> or C<stage> containing any files/out entries completes
execution, HPCI checks whether the listed files have been created or modified.
If one that is C<req> does not exist or has not been modified, the stage or
subgroup is aborted.  Any files that were created by this stage or subgroup
can get additional processing as specified in the associated C<HPCI::File>
subclass for the file - for example, checksum files can be generated.

=item 'skip' (or, deprecated, 'skipstage')

The traditional name 'skipstage' for this element has been deprecated
and has been replaced by the new name 'skip'.  The old name became
confusing when subgroups were added and could also contain a files
list that applied to the entire subgroup.  The 'skip' list defines
the contitions under which the stage or subgroup can be skipped.
This will be useful in a restart of an HPCI program that previously
completed some stages - the 'skip' elements allow HPCI to determine
whether this subgrou or stage completed successfully on the earlier
run and hance does not need to be re-executed.

It contains either:

=over 4

=item

an arrayref

=item

a hashref with the keys 'pre' (for pre-requisites) and 'lists'

=back

The arrayref (either the arrayref value of 'skip' or the arrayref value
for the 'lists' hash element) can contain either a list of files, or a hashref
with keys 'pre' and 'files'.

The 'pre' value (if present) at the top level is a list of files which are
pre-requisites for all of the lists.  If a list has its own 'pre' list, those
files are only pre-requities for the files in that list.

=item 'rename'

    a list of pairs of filenames

The file named as the first element in each pair (if it exists) is renamed to
the second filename in the pair.  It is not considered an error for the first
file in a pair to not exist - if you want to ensure that a file exists,
include it as an 'out'->'req' file as well.

=item 'delete'

can be either:

    a scalar filename
    a list of filenames

These will be removed if the stage completes successfully.  It is not
considered an error if any of these files does not exist - include them
in the 'out'->'req' files list if you wish to ensure that they do.

=back

The contents are used at various times:

=over 4

=item the stage/subgroup is ready to be executed

=over

=item

if a 'skip' key is present then checking is done to decide whether the
stage or subgroup needs to be executed or can be skipped (treating it
as a successful completion)

the main content of this key is a list of lists of filenames (the target
files) - if any of these lists has all of its files existing, then the stage
can be skipped

if there is a top level and/or a list level 'pre' list, then all of the files
in the pre list(s) must also exist and be older than the target files (the
files in the top level 'pre' list are checked against all of the target lists,
the files in a target level 'pre' list are only checked against that target).

C<skip> checking is always done by the parent process, in hopes of
avoiding the need to create the stage.

=item

all 'in'->'req' files must exist, if any is missing, the stage is aborted.
If the files exist, then the child stage will be set up (if needed) to
download those files from the long-term storage.

=item

all 'in'->'opt' are checked by the parent. If any exists, then the child stage
will be set up (if needed) to download them from the long-term storage.

=item

Any additional processing of 'in' files that are present (such as
validating or auto-generating checksums) is also done at this time, and may
also cause the stage or subgroup to be aborted.

=back

=item the stage or subgroup has completed execution

=over

=item

all 'out'->'req' files must exist and they must have been updated during the
execution of the stage (otherwise the stage is treated as failing)

=item

any 'out'->'opt' files which exists must have been updated during the execution
of the stage (otherwise the stage is treated as failing)

=item

any additional processing of 'out' files which have been updated (such
as generating a checksum) is also done

=item

clusters that require special treatment of files can take copying actions to
collect any 'out' files that have been updated and return them to the
original node

=item

if the stage completed successfully, any files lists as 'rename' are renamed
to their new name

=item

if the stage completed successfully, any files lists as 'delete' are removed

=back

=back

=cut

has 'files' => (
    is        => 'ro',
    isa       => 'Maybe[HashRef]',
    default   => undef,
);

has '_use_files' => (
    is        => 'ro',
    isa       => 'Maybe[HashRef]',
    lazy      => 1,
    init_arg  => undef,
    builder   => '_use_files_builder',
);

sub _use_files_builder {
    my $self      = shift;
    my $file      = $self->files // return undef;
    my $use_files = {};
    SIMPLE_FILES:
    for my $keys (  [qw(in req)],
                    [qw(in opt)],
                    [qw(out req)],
                    [qw(out opt)],
                    ['delete']
                ) {
        my $source = $file;
        $source = $source->{$_} or next SIMPLE_FILES for @$keys;
        my $prev_dest;
        my $dest = $use_files;
        for my $key (@$keys) {
            $prev_dest = $dest;
            $dest = $dest->{$key} //= {};
        }
        $prev_dest->{$keys->[-1]} = $self->_get_file_list($source);
    }
    my $skipinfo;
    if ($skipinfo = $file->{skipstage} ) {
        $self->warn(
            "'skipstage' element name for a files array is depracated, use 'skip' instead"
        );
    }
    if ($skipinfo //= $file->{skip}) {
        $use_files->{skip} = {};
        if (ref($skipinfo) eq 'HASH') {
            $self->_croak('skip hash element must be have keys "pre" and "lists"')
                unless exists $skipinfo->{pre} && exists $skipinfo->{lists};
            $use_files->{skip}{pre} = $self->_get_file_list( $skipinfo->{pre} );
            $skipinfo = $skipinfo->{lists};
            $self->_croak('skip->{lists} element must be an array')
                unless ref($skipinfo) eq 'ARRAY';
        }
        else {
            $self->_croak('skip files element must be either a hash or an array')
                unless ref($skipinfo) eq 'ARRAY';
            $use_files->{skip}{pre} = [];
        }
        my $dest_list = $use_files->{skip}{lists} = [ ];
        for my $l (@$skipinfo) {
            my $dest_hash = { };
            $self->_croak('skip list element must be either a hash or an array')
                unless ref($l) eq 'ARRAY' || ref($l) eq 'HASH';
            if (ref($l) eq 'HASH') {
                $dest_hash->{pre} = $self->_get_file_list( $l->{pre} );
                $l = $l->{post};
                $self->_croak('skip post element must be an array')
                    unless ref($l) eq 'ARRAY';
            }
            else {
                $dest_hash->{pre} = [];
            }
            $dest_hash->{post} = $self->_get_file_list( $l );
            push @$dest_list, $dest_hash;
        }
    }
    if ( my $renamelist = $file->{rename} ) {
        $self->_croak('rename files element an array')
            unless ref($renamelist) eq 'ARRAY';
        my $use_pairs = $use_files->{rename} = [];
        for my $pair (@$renamelist) {
            $self->_croak('rename files array element must be an array with two values')
                unless ref($pair) eq 'ARRAY' && scalar(@$pair) == 2;
            my ($from, $to) = @$pair;
            push @$use_pairs, [ $self->_get_file_obj($from), $to ];
        }
    }
    return $use_files;
};

sub _get_file_list {
    my $self   = shift;
    my $source = shift;
    $source = [ $source ] unless ref($source);
    $source = [ $source ] if blessed $source && $source->isa("HPCI::File");
    my $ref = ref($source);
    $self->_croak( "Element in files attribute is not an array, a pathname or HPCI::File class. Type is $ref, value is $source")
        unless $ref eq 'ARRAY';
    return [ map { $self->_get_file_obj($_) } @$source ];
}

sub _get_file_obj {
    my $self = shift;
    my $file = shift;
    return $self->_generate_file( ref($file) eq 'ARRAY' ? @$file : $file );
}

sub _generate_file {
    my $self = shift;
    my $file = shift;
    if (blessed $file && $file->isa("HPCI::File")) {
        return $file;
    }
    my $path = File::Spec->rel2abs("$file");
    # TODO: add search through storage_classes list here
    my $known = $self->_file_info->{$path} //= {};
    return ($known->{file_class} //= $self->file_class)->new(
        file  => $path,
        stage => $self,
        %{ $known->{params} // {} },
        @_
    );
}

sub lof {
    my $lof = shift;
    my $res = '[';
    $res .= " $_" for @$lof;
    $res .= ' ]';
    return $res;
}

sub _can_be_skipped {
    my $self = shift;
    my $skipinfo = $self->_use_files   // return 0;
    $skipinfo    = $skipinfo->{skip} // return 0;
    my $pre      = $skipinfo->{pre};;
    my $lol      = $skipinfo->{lists};
  LIST:
    for my $l (@$lol) {
        my $thispre = [@$pre, @{$l->{pre}}];
        $l = $l->{post};
        $self->debug( "Considering skip, pre: ", lof($thispre), ", list: ", lof( $l ) );
        unless (@$l) { # an empty list does not qualify for skipping
            $self->debug( "no skip: empty list element" );
            next LIST;
        }
        my $newest_pre;
        for my $f (@$thispre) {
            # if there is a pre list
            #     check that they all exist and
            #     get latest pre timestamp
            my $ts = $f->timestamp;
            unless (defined $ts) {
                $self->debug( "no skip: missing pre element: $f" );
                next LIST;
            }
            $newest_pre ||= $ts;
            $newest_pre = $ts if $ts < $newest_pre;
        }
        if ($self->_file_list_acceptable_for_skip( $newest_pre, $l )) {
            $self->debug( "skipping: file list acceptable" );
            return 1;
        }
        $self->debug( "no skip: file list not acceptable" );
    }
    return 0;
}

# check whether criteria are satisfied to skip executing the stage
sub _files_ready_to_start_stage {
    my $self = shift;
    return 1 unless my $files = $self->_use_files;
    my $retval = 1; # success unless missing file(s) found
    if (my $in = $files->{in}) {
        while ( my ($type, $fileval) = each %$in ) {
            for my $file (@$fileval) {
                unless ($file->valid_in_file || $type ne 'req') {
                # need to check exist on opt files in case
                #   the driver needs to take special action to
                #   make it available to the stage when it runs
                #
                # go through the entire list of files to give user
                # a full list of missing files rather than just the
                # first one we notice - let them fix everything for
                # the next run instead of needing separate extra
                # funs to be notified of each successive issue
                    $self->error("Required input file ($file) not present");
                    $self->_set_failure_info(
                        "Failed stage ("
                        . $self->name
                        . ") without execution because one or more required input files were not present"
                    );
                    $retval = 0;
                }
            }
        }
    }
    if ($retval and my $unshared = $files->{unshared}) {
        # our @HPCI::ScriptSource::pre_commands;
        # our @HPCI::ScriptSource::post_success_commands;
        if (my $in = $unshared->{in}) {
            while ( my ($type, $fileval) = each %$in ) {
                for my $file (@$fileval) {
                    my $exists = $self->_unshared_file_exists_for_in($file);
                    my $get = $self->_unshared_file_download_for_in($file);
                    push @HPCI::ScriptSource::pre_commands, "if $exists\n";
                    push @HPCI::ScriptSource::pre_commands, "then\n";
                    push @HPCI::ScriptSource::pre_commands, "    $get\n";
                    if ($type eq 'req') {
                        push @HPCI::ScriptSource::pre_commands, "else\n";
                        push @HPCI::ScriptSource::pre_commands, "    echo required in file not present: $file 1>&2\n";
                        push @HPCI::ScriptSource::pre_commands, "    exit 126\n";
                    }
                    push @HPCI::ScriptSource::pre_commands, "fi\n";
                }
            }
        }
        if (my $out = $unshared->{out}) {
            while ( my ($type, $fileval) = each %$out ) {
                for my $file (@$fileval) {
                    my $exists = $self->_unshared_file_exists_for_out($file);
                    my $put = $self->_unshared_file_upload_for_out($file);
                    push @HPCI::ScriptSource::post_success_commands, "if $exists\n";
                    push @HPCI::ScriptSource::post_success_commands, "then\n";
                    push @HPCI::ScriptSource::post_success_commands, "    $put\n";
                    if ($type eq 'req') {
                        push @HPCI::ScriptSource::post_success_commands, "else\n";
                        push @HPCI::ScriptSource::post_success_commands, "    echo required out file not present: $file 1>&2\n";
                        push @HPCI::ScriptSource::post_success_commands, "    exit 126\n";
                    }
                    push @HPCI::ScriptSource::post_success_commands, "fi\n";
                }
            }
        }
    }
    return $retval;
}

sub _default_file_info {
    my $self = shift;
    return $self->group->_file_info;
}


=head2 connect (optional)

This can contain an URL to be used by the driver for types of cluster
where it is necessary to connect to the cluster in some way.  It can
be omitted for local clusters that are directly accessible.

=cut

has 'connect' => (
    is       => 'ro',
    isa      => 'Str',
);

=head2 login, password (optional)

This can contain an identifier to be used by the driver for types of
cluster which require authorization.

=cut

has [ qw(login password) ] => (
    is       => 'ro',
    isa      => 'Str',
);

=head2 max_concurrent (optional)

The maximum number of stages to be running concurrently.  If 0
(which is the default), then there is no limit applied directly by
HPCI (although the underlying cluster-specific driver might apply
limits of its own).

=cut

has 'max_concurrent' => (
    is       => 'ro',
    isa      => 'Int',
    default  => 0,
);

=head2 file_class (internal)

The default storage class attribute for files that do not
have an explicit class given.  This is the name of a class.
The default is to use the value from the parent (sub-)group.

=cut

has 'file_class' => (
    is       => 'ro',
    isa      => 'Str',
	lazy     => 1,
	default  => sub {
        $_[0]->group->file_class
    },
);

# has 'storage_classes' => (
# 	is       => 'ro',
# 	isa      => 'HPCIListList',
# 	lazy     => 1,
# 	default  => sub { $_[0]->group->storage_classes },
# 	init_arg => undef,
# );

#### Internal attributes

=head1 METHODS

=head2 $group->add_file_params

Augment the file_params list with additional files.
Provide either a hashref or a list of value pairs,
in either case, the pairs are filename as the key,
and params as the value.

=cut

# sub add_file_params {
#     my $self = shift;
#     my $fi   = $self->_file_info;
#     my $args = $_[0];
#     $args    = { @_ } unless ref $args eq 'HASH';
#     while ( my ($k,$v) = each %$args ) {
#         $self->_croak( "file params value for $k must be a hash ref" )
#             unless (ref($v) eq 'HASH');
#         $k = File::Spec->rel2abs($k);
#         $fi->{$k}{params} = $v;
#     }
# }


=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros http://www.omgubuntu.co.uk/2016/03/vineyard-wine-configuration-tool-linuxLab

The Ontario Institute for Cancer Research

=cut

1;

