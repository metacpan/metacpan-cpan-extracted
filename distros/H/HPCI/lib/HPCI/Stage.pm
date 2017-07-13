package HPCI::Stage;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;
use MooseX::Types::Path::Class qw(Dir File);

# do nothing, but let roles write before/after/around wrappers
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
    $self->croak("Run time of more than 100 days seems insane ($origbase)");
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
                // $self->croak("Unknown code ($let) in time string ($time)");
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
is just providig a system call (e.g. unlink, link, rename) will need to
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
	$self->croak( "Exactly one of 'code' or 'command' attributes must be specified, not both" )
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
execution), etc.  Only people writing drivers need to worry about this attribute.

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
        debug => 'debug',
        info  => 'info',
        warn  => 'warn',
        error => 'error',
        fatal => 'fatal',
    },
);

sub _croak {
    my $self = shift;
    my $msg  = shift;
    $msg = "Stage(" . $self->name . "): $msg";
    $self->fatal($msg);
    croak $msg;
}

=head2 files

A hash that can contain lists of files.

The top level of the hash has keys 'in' and 'out' for input and output.
(The same file might be under both.)

The next level down in each of these is 'req' and 'opt' for required and
optional.

A file may be listed under both the 'in' and 'out' sub-hashes, but at least one
of those listings must be under 'opt'.  This would be used for files that are
updated in place by the stage program.

=over 4

=item

'in' => 'req' files will be needed as input to the program - (in/req)

=item

'in' => 'opt' files will be used as input to the program if they are present - (in/opt)

=item

'out' => 'req' files must be generated as output by the program - (out/req)

=item

'out' => 'opt' files can be generated or modified as output by the program - (out/opt)

=back

These lists can be used in a number of ways.

=over

=item 1

If stages are allowed to be skipped when unnecessary, the decision to skip a
stage is made by:

=over 4

=item

all in/req and out/req files must exist

=item

the timestamp on the newest in/req file must be older than the timestamp on the oldest out/req file

=back

So, the stage will skipped if all the required inputs are older than all of the requierd
outputs.  If a file is updated in place,, then either it should be listed as optional
in the output list, or else the stage program must always update the other outputs after
this one - otherwise the execution of the stage can never happen.

=item 1

If the cluster type is not using a global shared file system for all nodes then this
attribute is used to control copying of files to and from the cluster node that will
execute the stage command.

=over 4

=item

in/req files are copied to the node that will run the stage before the stage is executed

=item

in/opt files are copied to the node that will run the stage if they exist before the stage is executed

=item

out/req files are copied back from the node after the stage has been executed

=item

out/opt files are copied back from the node after the stage has been executed if they exists
(possibly not copyiny them if they have not been changed - that is cluster-specific behaviour)

=back

=item 1

If automatic validation of stage execution is being done then
all out/req files must exist and be timestamped later than the start of the execution
of the stage.

=back

=cut

has 'files' => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => '_has_files',
);

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
        $stderr is the pathname of the srderr file
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

- running a program that always gives an error status, but you might wish to treat it as successful

- running a program that can give a zero status but not actually succeed (but perhaps a retry will succeed)

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

    if ($self->is_pass && $self->_has_files) {
        my $script_time = -M $self->script_file;
        my $files = $self->files;
		my $fs_delay = $self->group->file_system_delay;
        FILE:
        for my $file (map { ref($_) ? @$_ : $_ } $files->{out}{req} ) {
			while ($fs_delay && ! -e $file) {
				my $sleep_time = ($fs_delay > 5) ? 5 : $fs_delay;
				$fs_delay -= $sleep_time;
				sleep $sleep_time;
			}
            next FILE if -e $file && -M _ <= $script_time;
			$self->_set_state('fail');
			$run->stats->{failure_detected} = "required output file $file not updated";
			$self->error(
				"Stage (", $self->name,
				") status changed to failed because required output file $file was not updated"
			);
			if (-e _) {
				my $file_time = -M _;
				$self->error( "mod time: ($file_time) should be more recent (smaller) than script time ($script_time)" );
			}
			else {
				$self->error( "file does not exist" );
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
        $self->_has_failure_info
        ? { exit_status => $self->_failure_info }
        : map { $_->stats } @{ $self->runs }
    ];
}

=head2 failure_action ('abort_group', 'abort_deps'*, or 'ignore')

Specifies the action to take if (the final retry of) this stage fails (terminates with
aa non-zero status).  There are three string values that it can have:

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

with qw(HPCI::Env HPCI::CommandScript);

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

Set the command line arguments for a command taking GNU's getlongopt-style arguments.

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

