package HPCI::Stage;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use HPCI::File;
use File::Spec;

use List::Util qw(first);
use Scalar::Util 'blessed';

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;
use MooseX::Types::Path::Class qw(Dir File);

# available for roles to wrap around, does nothing by default
sub BUILD {
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %parms = ( @_ );

    # support historical boolean parms for a while
    if (delete $parms{abort_group_on_failure}) {
        $parms{failure_action} = 'abort_group';
    }

    if (delete $parms{abort_deps_on_failure}) {
        $parms{failure_action} = 'abort_deps';
    }

    if (delete $parms{ignore_failure}) {
        $parms{failure_action} = 'ignore';
    }

    return $class->$orig(%parms);
};


=head1 NAME

    HPCI::Stage;

=head1 SYNOPSIS

Role for building a cluster-specific driver for a stage.
A stage is the object that describes a single job to be executed
within the context of a group.  It will be a member of a group
object, which will be responsible for ensuring that the stage is
executed after any prerequisite stages, and before any dependent
stages.  Most of the activity of a stage will be cluster-specific.

This role defines the generic, cluster-agnostic interface for a
stage, hiding the details of the specific cluster implementation.
A driver which consumes this role must provide methods for this
interface, translating it into the specific implementation that
best fits the specific type of cluster that it supports.  The driver
can also provide method for accessing facilities provided by its
cluster type that don't fit into the generic interface (but, of
course, any program that uses these methods will be less able to
move to using a different type of cluster)

A (internally defined) cluster stage is defined with:


    package HPCD::$cluster::Stage;
    use Moose;

    # define the required attributes/methods here

    with 'HPCI::Stage';

    # define the additional attributes/methods here


=head1 DESCRIPTION

This role provides the generic interface for a stage object,
which can be used to control a single stage.  A stage is the
unit of job execution that a grroup can schedule and assigne
to a node within a cluster.

A cluster-specific stage object definition can consume this
role to ensure that it provides the interface needed by a
HPCI using that type of cluster to run a group of stages.

New objects of the cluster-specific type are not created by
the user code - instead the user works through a HPCI
group object to ensure that any stage objects that it includes
within the group are of a cluster-specific compatible form to
the cluster-specific group object, and to allow the group to
register the stage so that it can be managed.

In fact, user code will generally not need to access the
stage object itself at all.  References to it will usually
be made by passing its name to methods of the group object,
rather than handled directly.

=head1 ATTRIBUTES

=head2 cluster (internally provided)

The type of cluster that will be used to execute the group
of stages.  This value is passed on by the $group->stage
method when it creates a new stage.  Since it also uses that
value to select the type of stage object that is created,
it is somewhat redundant.

=cut

sub _build_valid_resources {
    my $self = shift;
    return {
        $self->can('_build_cluster_specific_valid_resources')
            ? $self->_build_cluster_specific_valid_resources
            : ()
    };
}

class_has '_valid_resources' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_valid_resources',
);

sub _build_default_resources {
    my $self = shift;
    my $res = {
        $self->can('_build_cluster_specific_default_resources')
            ? $self->_build_cluster_specific_default_resources
            : ( )
    };
    $res->{_default_subs_}{h_time} = '_default_h_time';
    $res->{_default_subs_}{s_time} = '_default_s_time';

    return $res;
}

class_has '_default_resources' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_default_resources',
);

sub _default_h_time {
    my $self = shift;
    my $vals = shift;
    my $soft = $vals->{s_time};
    return unless defined $soft;
    # if soft time was provided, but no hard time, give an hour extra for hard
    return $self->_secs_to_time( $self->_time_to_secs($soft) + 60*60 );
}

sub _secs_to_time {
    my $self = shift;
    my $base = my $origbase = shift;
    my $res  = '';
    return '0' unless $base;
    my @units = ( [ 60, '' ], [ 60, 'm' ], [ 24, 'h' ], [ 99, 'd' ], );
    for my $unitpair (@units) {
        my ( $size, $name ) = @$unitpair;
        return "$base$name$res" if $base < $size;
        my $rem = $base % $size;
        $base = int( $base / $size );
        $res  = "$rem$name$res";
        }
    $self->_croak("Run time of more than 100 days seems insane ($origbase)");
    }

sub _time_to_secs {
    my $self      = shift;
    my $time      = shift;
    my $res       = 0;
    my %name2secs = (
        d => 24 * 60 * 60,
        h => 60 * 60,
        m => 60,
        s => 1,
        );
    while ($time =~ m/\G\s*(\d+)\s*(\w?)/g) {
        my ($num, $let) = ($1, $2);
        my $mult = 1;
        if ($let) {
            $mult = $name2secs{ lc($let) }
                // $self->_croak("Unknown code ($let) in time string ($time)");
            }
        $res += $num * $mult;
        }
    return $res;
    }

sub _default_s_time {
    my $self = shift;
    my $vals = shift;
    # return $vals->{h_time}; # same as h_time or undef if no h_time provided
    return undef;
}

sub _build_default_retry_resources {
    my $self = shift;
    return $self->can("_build_cluster_specific_default_retry_resources")
        ? { $self->_build_cluster_specific_default_retry_resources }
        : { };
}

class_has '_default_retry_resources' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_default_retry_resources',
);

has 'cluster' => (
    is      => 'ro',
    isa     => 'Str',
);

=head2 name

The name of this stage within the group.  The name must be unique
within the group, most group interactions use the name rather than
a reference to the stage object to refer to the stage.

=cut

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 command

The command to be executed on the cluster.  This command will quite
possibly be wrapped in a cluster-specific manner to pass the command
and environment info to the target cluster node.

The command can either be provided as an explicit parameter when
the stage is created, or by using one of the B<set_*_cmd> methods
described below after the stage object is created.

This is the only time that you need the stage object itself rather
than just referring to it by its name.  However, even here, unless
you need to separate the creation of the stage object from the
point where you specify the command you can do something like:

    my $group = HPCI->group( ...);

    ...

    $group->stage( name => 'thisstage', ... )
        ->set_perl_cmd(
            $program,
            f    => undef,       # a       flag argument:  -f
            flag => undef,       # another flag argument:  --flag
            v    => $value,      # a       value argument: -v $value
            val  => $value,      # another value argument: --val $value
            l    => [ qw(a b c}] # a       list argment:   -l a -l b -l c
            list => [ qw(a b c}] # another list argment:   --list a --list b --list c
            '--' => [ f1 f2 ]    # non-keyed argument(s):  f1 f2
        );
    # set the command to: perl $program -f --flag -v $value --val $value \
    #    -l a -l b -l c --list a --list b --list c f1 f2

As an alternative to the command attribute, you can specify the code
attribute described below.
It is required that one of these be provided before the group tries to
execute this stage.-, and only one of them can be provided (no9t both)

=cut

has 'command' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => '_has_command',
    trigger   => sub { shift->_only_one( '_has_code' ) },
);

=head2 code

The code attribute is an alternate to the command attribute described
above.  Its value is a code reference, which will be called directly
to carry out the activity of the Stage.  You can use this for a stage
activity that is simple enough to code as a perl routine that it does
not make sense to go through the overhead of creating a new job on a
cluster node to do this activity.  You may not specify B<both> B<code>
and B<command> for the same stage; but you must specify one of them
before the stage is ready to execute.

The code in the reference is called with no arguments when the stage
is ready to be executed.  The return value is treated as a boolean to
indicate whether the stage succeeded: a false value for success, or a
true value for failure (with the value usually being a text message
describing the cause of the failure).  This mimics the exit_status
that is returned from a separately executed program (except for being
able to provide a more easily understood failure code than a simple
integer) - however, it does mean that some common purposes for this
attribute will need some wrapping code.  For example, any B<code> that
is just providing a system call (e.g. unlink, link, rename) will need to
invert the boolean result, and expand the failure result to provide the
errno value, such as:

    stage(
        ...
        code => sub {
             unlink $tmpfile ? 0 : $!
        },
        ...
    )

=cut

has 'code' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_code',
    trigger   => sub { shift->_only_one( '_has_command' ) },
);

sub _only_one {
    my $self      = shift;
    my $has_other = shift;
    $self->_croak( "Exactly one of 'code' or 'command' attributes must be specified, not both" )
        if $self->$has_other;
}

sub assert_command_filled {
    my $self     = shift;
    $self->_croak(
            "Trying to submit stage ("
            . $self->name
            . "), but neither command nor code have been set"
        )
        unless $self->_has_command || $self->_has_code;
}

has 'stage_dir_name' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self   = shift;
        return $self->name;
    },
);

has 'stage_dir' => (
    is      => 'ro',
    isa     => Dir,
    coerce  => 1,
    lazy    => 1,
    default => sub {
        my $self   = shift;
        my $target;
        if ($self->_has_dir) {
            $target = $self->dir;
        }
        else {
            $target = $self->group->group_dir->subdir( $self->stage_dir_name );
        }
        HPCI::_trigger_mkdir($self,$target);
        return $target;
    },
    trigger => \&HPCI::_trigger_mkdir,
);

has 'dir' => (
    is        => 'ro',
    isa       => Dir,
    coerce    => 1,
    predicate => '_has_dir'
);

=head2 resources_required

A hash that maps resource names to the amount of that resource
that is needed.

TODO: Describe the generic resource names, the value types that can
be used, and the non-default cluster-specific names that can be
used instead.

=cut

has 'resources_required' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub { return {} },
);

has '_use_resources_required' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    builder => '_init_use_resources_required',
);

sub _init_use_resources_required {
    my $self = shift;
    $self->res_hash_map( $self->resources_required,
        $self->_default_resources,
    );
}

=head2 retry_resources_required

A hash that maps resource names to a list of amounts of that resource
that might be required.

If the cluster-specific interface detects that a runs fails because
not enough of a particular resource was requested, then the next
larger amount in the retry_resources_required list for that resource
type is used and the stage is retried.

At present, this is only used for SGE clusters, and only for the
B<mem> (or SGE-specific B<h_vmem>) resource.  SGE provides a
default value of:

    retry_resources_required => { h_vmem => [qw(2G 4G 8G 16G 32G)] }

When you are first running a job and don't know how much memory
it will require, you can specify a low value.  When it completes,
you can check the log to see how much memory it ended up needing,
and use that as the starting parameter for future runs.  That initial
run will have possible had to run part way through, fail, and then
retry a number of times.  The alternative of providing a large
memory allocation the first time takes resources from your cluster
(and especially if you never get around to changing the initial
setting - people are more likely to remember to make such a change
when it will save them time by avoiding retries than when it just
happens to reserve more space than is actually used).

=cut

has 'retry_resources_required' => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef[Str]]',
    default => sub { return {} },
);

has '_use_retry_resources_required' => (
    is      => 'ro',
    isa     => 'HashRef[ArrayRef[Str]]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->res_hash_map( $self->retry_resources_required,
            $self->_default_retry_resources,
        );
        # need to provide converter support here
        # e.g. turn a time from '2d3h' to (2*24+3)*60*60 (seconds)
    },
);

sub res_hash_map {
    my $self       = shift;
    my $provided   = shift;
    my $default    = shift;
    my $determined = {};
    my $map = $self->_valid_resources;
    for my $cluster_res (keys %$map) {
        my $common_res = $map->{$cluster_res} || $cluster_res;
        if (my $use_res = $provided->{$cluster_res}
            // $provided->{$common_res}
            // $default->{$cluster_res}
            // $default->{$common_res})
        {
            $determined->{$cluster_res} = $use_res;
        }
    }
    my $initters = $default->{_default_subs_} // {};
    for my $key (keys %$initters) {
        unless (defined $determined->{$key}) {
           my $func = $initters->{$key};
           my $res = $self->$func($determined);
           $determined->{$key} = $res if defined $res;
        }
    }
    return $determined;
}

=head2 native_args_string

The native program mechanism used by the driver to submit a stage
for execution can have many arguments.  Some of those will be provided
automatically from the generic HPCI attributes, but there may be extra
capabilities that do not match the standard HPCI definition.

Using these extra capabilities can lead to non-portable programs, unless
you are careful.  HPCI provides two ways to be careful but also
allows you to be careless.

If you (carelessly) provide this attribute directly, then it will be used
for any type of cluster that your program is run on - using such
cluster-specific parameters can have dangerous or obscure effects when
applied to a different cluster type.

You can be careful, by providing this attribute only within an
attribute set included in the cluster_specific attribute.
The alternate way to be careful is to provide this attribute indirectly,
using the cluster-specific name which the driver specifies as the
native_args_string_name attribute.

The value provided to native_args_string will be passed to the native
submissions mechanism when-ever that makes sense.  A driver that uses a
submission mechanism that does not provide for any non-standard HPCI
capabilities may choose to ignore this attribute.

So, for example, if you wished to provide extra args for the qsub command
when running on an SGE cluster you could code that as either:

    $group->stage(
        name => 'stage_name',
        ...
        cluster_specific => {
            SGE => { native_args_string => '-q myqueue -m beas' },
            ... # put args strings for other cluster types here
        },
        ...
    );

or as:

    $group->stage(
        name => 'stage_name',
        ...
        extra_sge_args_string => '-q myqueue -m beas',
        ... # put args strings for other cluster types here
            # using the appropriate cluster-specific attribute name
        ...
    );

=head2 native_args_string_name

This attribute is one way in which a driver can help you to use native
arguments in a portable way.  Drivers that actually use the native_args_string
attribute will specify a value for this attribute internally - it is never
provided directly as a Stage attribute.  If this attribute is provided by the
driver, then only the value of the attribute it names will be used for the
source text of native_args_string.

=head2 _native_args_string_parsing_info

This internal attribute is provided by the driver.  It specifies how the
native_args_string is parsed, controlling how it is separated into
parameters and values, which parameters are normally provided by altenate
HPCI mechanisms, how the parameters and values are displayed in the log
(if it is different from how they are inserted into the command line for
execution), etc.

Only people writing drivers need to worry about this attribute.

=head2 native_args* support not implemented yet

The attributes related to native_args_string processing are not yet ready for
use; they are being implemented by copying and generalizing the code from the
SGE and Slurm drivers, that is still in progress.

=cut

has 'native_args_string' => (
    is       => 'ro',
    isa      => 'Str',
    default  => ''
);

has 'native_args_string_name' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    init_arg => undef,
    default  => undef    # driver can over-ride this setting
);

has 'native_args_string_parsing_info' => (
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => undef,
    builder  => 'default_args_string_parsing_info'
);

# driver can over-ride this method to provide a non-empty list
# of parsing info
sub default_args_string_parsing_info {
    return {}
}


=head2 group

The group that this stage belongs to is automatically provided to
the stage creation.  You don't need to initialize it, and since
you usually will not be working with Stage objects directly, you
won't have much need to use it either.

=cut

has 'group' => (
    is       => 'ro',
    isa      => 'Object',
    weak_ref => 1,
    required => 1,
    handles  => {
        debug       => 'debug',
        info        => 'info',
        warn        => 'warn',
        error       => 'error',
        fatal       => 'fatal',

        file_params => 'file_params',
        _file_info  => '_file_info',
    },
);

sub _croak {
    my $self = shift;
    my $msg  = shift;
    $msg = "Stage(" . $self->name . "): $msg";
    $self->fatal($msg);
    confess $msg;
}

=head2 storage_class (internal)

The name of key to use to select a storage class from the storage_classes
attribute for files that do no have an explicit class given.

Defaults to the value of the group's C<storage_class> attribute, (which
defaults to C<'default'>) - this value is provided automatically by the
group's stage method if no explicit storage_class value is provided for
the stage.

=cut

has 'storage_class' => (
    is       => 'ro',
    isa      => 'HPCIFileGen',
	lazy     => 1,
	default  => sub {
        $_[0]->group->storage_class
    },
    required => 1,
);

# has 'storage_classes' => (
# 	is       => 'ro',
# 	isa      => 'HPCIListList',
# 	lazy     => 1,
# 	default  => sub { $_[0]->group->storage_classes },
# 	init_arg => undef,
# );

=head2 files

A hash that can contain lists of files.

Throughout this hash, there are filenames contained within hash elements
that describe the processing required for that file.  Whenever a filename
is needed, it can either be a string containing a pathname, or it can be
an HPCI::File object (or subclass), or ot can be a HashRef.  Often, it
will be the string form, which will be converted to an object internally.

The top level of the hash has keys 'in' (for input), 'out' (for output),
'skipstage', 'rename', and 'delete'.
(The same file might be listed under multiple keys.)

The values for these keys are:

=over 4

=item 'in'

a hashref with possible keys:

    'req' (for required input files)
    'opt' (for required output files)

The value for either of these can be either a filename or a list of filenames.

=item 'out'

a hashref with possible keys:

    'req' (for required output files)
    'opt' (for required output files)

The value for either of these can be either a filename or a list of filenames.

=item 'skipstage'

either:

=over 4

=item

an arrayref

=item

a hashref with the keys 'pre' (for pre-requisites) and 'lists'

=back

The arrayref (either the arrayref value of 'skipstage' or the arrayref value
for the 'lists' hash element) can contain either a list of files, or a hashref
with keys 'pre' and 'files'.

The 'pre' value (if present) at the top level is a list of files which are
pre-requisites for all of the lists.  If a list has its own 'pre' list, those
files are only pre-requities for the files in that list.

=item 'rename'

    a list of pairs of filenames

The file named as the first element in each pair (if it exists) is renamed to
the second filename in the pair.  It is not considered an error for the first
file in a pair does not exist - if you want to ensure that a file exists,
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

=item the stage is ready to be executed

=over

=item

if a 'skipstage' key is present then checking is done to decide whether the
stage needs to be executed or can be skipped (treating it as a successful
completion)

the main content of this key is a list of lists of filenames (the target
files) - if any of these lists has all of its files existing, then the stage
can be skipped

if there is a top level and/or a list level 'pre' list, then all of the files
in the pre list(s) must also exist and be older than the target files (the
files in the top level 'pre' list are checked against all of the target lists,
the files in a target level 'pre' list are only checked against that target).

C<skipstage> checking is always done by the parent process, in hopes of
avoiding the need to create the stage.

=item

all 'in'->'req' files must exist, if any is missing, the stage is aborted.
If the files exist, then the child stage will be set up (if needed) to
download those files from the long-term storage.

=item

all 'in'->'opt' are checked by the parent. If any exists, then the child stage
will be set up (if needed) to download them from the long-term storage.

=back

=item the stage has completed execution

=over

=item

all 'out'->'req' files must exists and they must have been updated during the
execution of the stage (otherwise the stage is treated as failing)

=item

any 'out'->'opt' files which exist must have been updated during the execution
of the stage (otherwise the stage is treated as failing)

=item

clusters that require special treatment of files can take copying actions to
collect any 'out' files that have been updated

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
    if ( my $skipinfo = $file->{skipstage} ) {
        $use_files->{skipstage} = {};
        if (ref($skipinfo) eq 'HASH') {
            $self->_croak('skipstage hash element must be have keys "pre" and "lists"')
                unless exists $skipinfo->{pre} && exists $skipinfo->{lists};
            $use_files->{skipstage}{pre} = $self->_get_file_list( $skipinfo->{pre} );
            $skipinfo = $skipinfo->{lists};
            $self->_croak('skipstage->{lists} element must be an array')
                unless ref($skipinfo) eq 'ARRAY';
        }
        else {
            $self->_croak('skipstage files element must be either a hash or an array')
                unless ref($skipinfo) eq 'ARRAY';
            $use_files->{skipstage}{pre} = [];
        }
        my $dest_list = $use_files->{skipstage}{lists} = [ ];
        for my $l (@$skipinfo) {
            my $dest_hash = { };
            $self->_croak('skipstage list element must be either a hash or an array')
                unless ref($l) eq 'ARRAY' || ref($l) eq 'HASH';
            if (ref($l) eq 'HASH') {
                $dest_hash->{pre} = $self->_get_file_list( $l->{pre} );
                $l = $l->{post};
                $self->_croak('skipstage post element must be an array')
                    unless ref($l) eq 'ARRAY';
            }
            else {
                $dest_hash->{pre} = [];
            }
            $dest_hash->{post} = $self->_get_file_list( $l );
            push @$dest_list, $dest_hash;
        }
    }
    # TODO: handle rename
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
    return $known->{file} //= $self->storage_class->(
        $path,
        stage => $self,
        %{ $known->{params} // {} },
        @_
    );
}

=head2 state, is_ready, is_blocked, is_pass, is_fail

These states are mostly for internal use during execution.  (There
are actually more states than are listed here but they are only
meaningful during execution when the calling program doesn't have
access to the state, and they are subject to change without notice.)

However, before execute is called, a stage can be either B<ready>
or B<blocked> (depending upon whether any other stage has been
noted as a pre-requisite).

After execution completes, a stage will be in either B<pass> or B<fail> state
(and the B<is_complete> attribute will always be true).  This is probably
the only significant setting to check from user code.

The state attribute is a string value, but it can be tested using
the is_STATE methods, each of which returns true if the stage is
in the specified state.

=cut

enum 'StageState', [qw(ready blocked running retry pass fail)];

has 'state' => (
    is       => 'ro',
    isa      => 'StageState',
    writer   => '_set_state',
    default  => 'ready',
    init_arg => undef,
);

sub is_ready {
    my $self = shift;
    return $self->state eq 'ready';
}

sub is_blocked {
    my $self = shift;
    return $self->state eq 'blocked';
}

sub is_running {
    my $self = shift;
    return $self->state eq 'running';
}

sub is_retry {
    my $self = shift;
    return $self->state eq 'retry';
}

sub is_pass {
    my $self = shift;
    return $self->state eq 'pass';
}

sub is_fail {
    my $self = shift;
    return $self->state eq 'fail';
}

sub is_complete {
    my $self = shift;
    return $self->is_pass || $self->is_fail;
}

=head2 verify_completion_state

If the user wishes to verify whether a stage completed successfully,
failed, or should be retried, this attribute can be given a coderef
to code that checks the result.

The code will be called with the arguments:

  $coderef->( $stats, $stdout, $stderr, $state )
    $stats  is a hashref containing the accounting info and status of the job
    $stdout is the pathname of the stdout file
    $stderr is the pathname of the stderr file
    $state  is the state determined by HPCI
                   (only pass/fail - retry has not been decided yet)

The code can use these (and knowledge provided by the user about the stage
operation) to test whether the stage succeeded.

To select a specific state, the return value from the code should be a string, one of:

    pass
    fail
    retry

If your function does not wish to select a state, it can return undef, and the
same state that would be been chosen without the call to this function will be
used unchanged.

If the value returned is 'fail', other standard HPCI mechanisms may still apply
that might change the choice to 'retry'.

If the value returned is 'retry', it will either retry the stage or be
changed to fail state, depending upon whether the limit for the choose_retries
attribute has been reached.

This code attribute could be used for:

- running a program that always gives an error status, but you might wish to
  treat it as successful

- running a program that can give a zero status but not actually succeed (but
  perhaps a retry will succeed)

An example might look like:

    $group->stage(
        ....
        verify_completion_status => sub {
            my( $stats, $stdout, $stderr, $state ) = @_;
            # retry if output file is zero length
            return 'retry' if $state eq 'pass' && ! -s $my_output_file;
            # otherwise, normal processing
            return;
            },
        ...
        );

=cut

has 'verify_completion_state' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_verify_completion_state',
);

after '_analyse_completion_state' => sub {
    my $self  = shift;
    my $run   = shift;

    if ($self->is_pass && (my $files = $self->_use_files) ) {
        my $script_time = $self->_file_timestamp_for_out( $self->script_file );
        if ( my $outfiles = $files->{out}) {
            my $fs_delay = $self->group->file_system_delay;
          FILE:
            while ( my ($type, $fileval) = each %$outfiles ) {
                for my $file ( @$fileval ) {
                    while ($fs_delay && ! $file->exists_out_file) {
                        my $sleep_time = ($fs_delay > 5) ? 5 : $fs_delay;
                        $fs_delay -= $sleep_time;
                        sleep $sleep_time;
                    }
                    my $timestamp;
                    if ($file->exists_out_file) {
                        if ( ($timestamp = $file->timestamp)
                                <= $script_time) {
                            $file->accepted_for_out;
                            next FILE;
                        }
                    }
                    else {
                        next FILE if $type eq 'opt';
                    }
                    # a req file was not found
                    $self->_set_state('fail');
                    $run->stats->{failure_detected} = "required output file ($file) not updated";
                    $self->error(
                        "Stage (",
                        $self->name,
                        ") status changed to failed because required output file ",
                        $file,
                        " was not updated"
                    );
                    if ($timestamp) {
                        $self->error(
                            "mod time: (",
                            $timestamp,
                            ") for file($file) should be more recent (less) than script time (",
                            $script_time,
                            ")"
                        );
                        # my $script_file = $self->script_file;
                        # $self->error(
                            # "ls:\n",
                            # `ls --full-time $script_file $file`
                        # );
                        # $self->error(
                            # "-M:\n\t\t",
                            # -M "$script_file", "\t$script_file", "\n\t\t",
                            # -M "$file","\t$file", 
                        # );
                    }
                    else {
                        $self->error( "file ($file) does not exist" );
                    }
                }
            }
        }
    }
    if ($self->_has_verify_completion_state) {
        my $code   = $self->verify_completion_state->(
            $run->stats,
            $run->_stdout,
            $run->_stderr,
            $self->state
        );
        if ($code eq 'retry') {
            $code = 'fail';
            $run->_analysis_chose_retry(1);
        }
        $self->_set_state( $code ) if $code eq 'pass' || $code eq 'fail';
    }
};

sub lof {
    my $lof = shift;
    my $res = '[';
    $res .= " $_" for @$lof;
    $res .= ' ]';
    return $res;
}

# check whether criteria are satisfied to skip executing the stage
sub _can_be_skipped {
    my $self = shift;
    my $skipinfo = $self->_use_files   // return 0;
    $skipinfo    = $skipinfo->{skipstage} // return 0;
    my $pre      = $skipinfo->{pre};;
    my $lol      = $skipinfo->{lists};
  LIST:
    for my $l (@$lol) {
        my $thispre = [@$pre, @{$l->{pre}}];
        $l = $l->{post};
        $self->debug( "Considering skipstage, pre: ", lof($thispre), ", list: ", lof( $l ) );
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
                # for my $file ($self->_scalar_list($fileval)) {
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

# sub _files_acceptable_for_completed_stage {
#     my $self = shift;
#     my $run  = shift;
#     return 1 unless $self->_use_files;
#     my $out = $self->files->{out} or return 1;
#     my $retval = 1; # success unless non-updated file found
#     my $before = $self->_file_timestamp_for_out( $run->dir );
#     while ( my ($type, $fileval) = each %$out ) {
#         for my $file ($self->_scalar_list($fileval)) {
#             # need to check exist on opt files in case
#             #   the driver needs to take special action to
#             #   collect the result from the completed stage
#             #
#             # go through the entire list of files to give user
#             # a full list of invalid files rather than just the
#             # first one we notice - let them fix everything for
#             # the next run instead of needing separate extra
#             # runs to be notified of each successive issue
#             my $error_text;
#             if ( ! $self->_file_exists_for_out($file)
#                     && $type eq 'req') {
#                 ++$error_text;
#                 $self->error( "Required output file ($file) is not present" );
#             }
#             elsif ($self->_file_timestamp_for_out($file) < $before) {
#                 # file was not updated
#                 my $msg = "output file ($file) was not changed";
#                 if ($type eq 'req') {
#                     ++$error_text;
#                     $self->error( "Required $msg" );
#                 }
#                 else {
#                     $self->warn( "Optional $msg" );
#                 }
#             }
#             if ($error_text) {
#                 $self->_set_failure_info(
#                     "Failed stage (",
#                     $self->name,
#                     ") after 'successful' execution because one or more required output files were not updated"
#                 );
#                 $retval = 0;
#             }
#         }
#     }
#     return $retval;
# }

sub _files_actions_after_success {
    my $self = shift;
    my $run  = shift;
    return 1 unless $self->_use_files;
    # TODO: update after _use_files is set up to support rename
    if (my $pairs = $self->files->{rename}) {
        for my $pair (@$pairs) {
            if (ref($pair) ne 'ARRAY' && @$pair != 2) {
                $self->error( "Ignoring bad rename pair element: ", Dumper($pair) );
                next;
            }
            $self->_rename_file( @$pair );
        }
    }
    for my $file ( @{ $self->files->{delete} } ) {
        $file->delete if $file->exists;
    }
}

sub _file_exists {
    return -e $_[1];
}

sub _file_timestamp {
    return -e $_[1] ? -M _ : undef;
}

# allow drivers to over-ride the definition of various file routines
# in various contexts
sub _file_exists_for_skip {
    shift->_file_exists(@_);
}

sub _file_exists_for_in {
    shift->_file_exists(@_);
}

sub _file_exists_for_out {
    shift->_file_exists(@_);
}

sub _file_exists_for_delete {
    shift->_file_exists(@_);
}

sub _file_accepted_for_out {
    ; # no action in normal case
}

sub _file_timestamp_for_skip {
    shift->_file_timestamp(@_);
}

sub _file_timestamp_for_out {
    shift->_file_timestamp(@_);
}

sub _delete_file {
    unlink $_[1];
}

sub _unshared_file_exists_for_in {
}

sub _unshared_file_download_for_in {
}

sub _unshared_file_exists_for_out {
}

sub _unshared_file_upload_for_out {
}

sub _rename_file {
    my $self = shift;
    my $src  = shift;
    my $dst  = shift;
    if ($self->_file_exists($src)) {
        link $src, $dst;
        unlink $src;
    }
}

sub _file_list_acceptable_for_skip {
    my $self       = shift;
    my $newest_pre = shift;
    my $list       = shift;
    for my $file (@$list) {
        my $ts = $file->timestamp;
        if (not defined $ts) {
            $self->debug( "target file does not exist: $file" );
            return undef;
        }
        if ($newest_pre) {
            unless ($ts <= $newest_pre) {
                $self->debug( "target too old: timestamp of $file($ts) should be newer (less) than newest prerequisite ($newest_pre)" );
                return undef;
            }
        }
    }
    return 1;
}

=head2 should_choose_retry, choose_retries

If a cluster has a tendency to fail randomly, it may be desired to
retry a stage that fails rather than simply treating it as an unrecoverable
failure.

This pair of attributes specifies two aspects of making such a choice.

First, the should_choose_retry attribute can be given a code reference to code
that returns true if a retry should be made.  This code is only called if the
stage run has failed.

The sub is called with two arguments:
the status hash containing the known status results from the most recent try to
run the stage, and a string with the name of the stderr output file.  This code
returns a true value to indicate that a retry should be attempted.  If this
attribute is not explicitly provided, it defaults to code that always returns 0
to not cause a retry attempt.

Second, the choose_retries attribute specifies number of times that the stage
should be retried at the request of the should_choose_retry code (or at the
request of the verify_completion_status code).
The default is 1.

=cut

has 'should_choose_retry' => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => '_has_should_choose_retry'
);

has 'choose_retries' => (
    is        => 'ro',
    isa       => 'Int',
    lazy      => 1,
    default   => 1,
);

has '_chosen_retries' => (
    is        => 'rw',
    isa       => 'Int',
    init_arg  => undef,
    default   => 0
);

=head2 force_retries

If a cluster has a tendency to fail randomly, it may be desired to
retry a stage that fails rather than simply treating it as an unrecoverable
failure.

This attribute specifies the number of times that the stage should be retried
until it passes.  The default is to not retry (unless the underlying driver
retries for a specific reason).

There are three types of retry selections.  First, the devide driver can provide
automatic retries for considitions appropriate to that cluster type.  Second,
the retries selected by the should_choose_retry attribute can cause a retry if
the user-provided code chooses.  Finally, the force_retries attribute can cause
a retry.  Each of these three is independent - any of them can cause a retry
regardless of what the others would select.  A stage only is deemed to have
failed completely if none of the methods selects a retry.  The counters for each
type of retry test is only adjusted if that test was the one that caused a retry
so there can be as amny retries as the total of the number allowed by each type.

=cut

has 'force_retries' => (
    is        => 'ro',
    isa       => 'Int',
    default   => 0
);

has '_forced_retries' => (
    is        => 'rw',
    isa       => 'Int',
    init_arg  => undef,
    default   => 0
);

has '_failure_info' => (
    is        => 'ro',
    isa       => 'Str',
    writer    => '_set_failure_info',
    predicate => '_has_failure_info',
    init_arg  => undef,
);

has 'runs' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    default  => sub { [] },
);

sub _run {
    my $self = shift;
    my $runclass = $self->_run_class;
    my $run  = $runclass->new(
        $self->_run_args,
    );
    push @{ $self->runs }, $run;
    return $run;
}

sub _run_args {
    my $self = shift;
    return (
        stage              => $self,
        index              => scalar( @{ $self->runs } ),
    )
}

sub get_run_stats {
    my $self = shift;
    return [
        $self->_has_failure_info          ? { exit_status => $self->_failure_info }
        : scalar( @{ $self->runs } ) == 0 ? { exit_status => 'Stage skipped, skipstage determined it was complete',
                                              final_job_state => 'pass'
                                            }
        :                                   map { $_->stats } @{ $self->runs }
    ];
}

=head2 failure_action ('abort_group', 'abort_deps'*, or 'ignore')

Specifies the action to take if (the final retry of) this stage fails
(terminates with non-zero status).

There are three string values that it can have:

=over

=item - abort_deps (default)

If the stage fails, then any stages which depend upon it
(recursively) are not run.  The group continues executing stages
which are not dependent upon this stage.

=item - abort_group

If the stage fails, then no other stages are started.  The group
simply waits until previously started stages complete and then
returns.

=item - ignore

Execution continues unchanged, any dependent stages will be run
when they are no longer blocked.

=back

=cut

enum 'FailureAction', [qw(abort_group ignore abort_deps)];

has 'failure_action' => (
    is       => 'ro',
    isa      => 'FailureAction',
    default  => 'abort_deps',
);

with qw(HPCI::Env HPCI::CommandScript HPCI::ScriptSource);

=head1 METHODS

=head2 command setting methods

The following command setting methods can be used as an alternative to
providing the command as a string.

They each have the same parameter list:

    $stage->set_FOO_cmd( $command,
        $key1, $value1,
        $key2, $value2,
        ...
    );

There are three types of keys - keys with a single letter, longer
keys, and '--'.  Single letter keys will be prefixed with a single
dash; longer keys will be prefixed with a double dash.  The special
key '--' (two dashes) contains the non-option command line arguments.

The values can either be a scalar or an arrayref.  The way array
values are expanded depends upon the choice of command setting
method used.

The argparse method (used for python and R) sets lists by putting
all the list variables after a single option word:

    --infiles file1 file2 file3

The gnuparse method (used for Perl) uses the standard Unix and gnu
command way of setting lists by repeating the option word:

    --infiles file1 --infiles file2 --infiles file3

In the case of the interpreter methods (set_python_cmd, set_perl_cmd,
set_R_cmd), they simply prepend the appropriate interpreter to the
provided script name, and invoke the right parsing method.

=head2 set_argparse_cmd

Set the command attribute to execute a command taking Python's
argparse-style arguments.

=cut

sub set_argparse_cmd {
    my $self = shift;
    my $prog = shift;
    my %args = @_;
    my @args = ();
    my @tail = ();
    foreach my $key (sort keys %args) {
        if ($key eq '--') {
            push @tail, '--',
                (ref($args{$key}) eq 'ARRAY') ? (@{$args{$key}})
                :                               $args{$key};
            next;
        }
        push @args,
            (length $key > 1) ? "--$key"
            :                   "-$key";
        if (defined($args{$key})) {
            push @args,
                (ref($args{$key}) eq 'ARRAY') ? (@{$args{$key}})
                :                               $args{$key};
        }
        # else Assume this is a bool ean switch
    }
    $self->command( join ' ', $prog, @args, @tail );
}

=head2 set_gnu_cmd

Set the command line arguments for a command taking GNU's getlongopt-style
arguments.

=cut

sub set_gnu_cmd {
    my $self = shift;
    my $prog = shift;
    my %args = @_;
    my @args = ();
    my @tail = ();
    foreach my $key ( sort keys %args ) {
        if ($key eq '--') {
            push @tail, "--", ( ref( $args{$key} ) eq 'ARRAY' )
              ? @{ $args{$key} }
              : $args{$key};
            next;
        }
        else {
            my $key_prefix = length $key > 1 ? "--$key" : "-$key";
            push @args,
                ( !defined $args{$key}
                    ? ($key_prefix)
                    : map
                        { ( $key_prefix, $_ ) }
                        ( ref( $args{$key} ) eq 'ARRAY'
                            ? @{ $args{$key} }
                            : $args{$key}
                        )
                );
        }
    }
    $self->command( join ' ', $prog, @args, @tail );
}

=head2 set_perl_cmd

Wrapper around set_gnu_cmd that prefixes the Perl interpreter.

=cut

sub set_perl_cmd {
    my $self   = shift;
    my $script = shift;
    $self->set_gnu_cmd( "perl $script", @_ );
}

=head2 set_python_cmd

Wrapper around set_argparse_cmd that prefixes the Python interpreter.

=cut

sub set_python_cmd {
    my $self   = shift;
    my $script = shift;
    $self->set_argparse_cmd( "python $script", @_ );
}

=head2 set_r_cmd

Wrapper around set_argparse_cmd that prefixes the R interpreter.

=cut

sub set_r_cmd {
    my $self   = shift;
    my $script = shift;
    $self->set_argparse_cmd( "Rscript $script", @_ );
}

=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

Andre Masella - Boutros Lab

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;
