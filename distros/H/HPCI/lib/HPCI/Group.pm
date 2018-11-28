package HPCI::Group;

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

use MooseX::Role::Parameterized;
use MooseX::Types::Path::Class qw(Dir File);
use Moose::Util::TypeConstraints;

## no critic BoutrosLab::HangingComma
## no critic BoutrosLab::IndentationCheck

parameter theDriver => (
    isa      => 'Str',
    required => 1,
);

role {
    my $p = shift;
    my $theDriver = $p->theDriver;
    my $StageClass = "${theDriver}::Stage";

    # do nothing, but let roles write before/after/around wrappers
    method BUILD => sub {
    };

    with
        'HPCI::Super',
        'HPCI::SuperSub',
        'HPCI::Logger',
        'HPCI::Env',
    ;
    # Future considerations for adding:
    #
    # HPCI::HTML         - generate a report about an execution
    # HPCI::Template     - templates for reports
    #                        - was formerly used for script
    #                        - now generated dynamically
    #                        - allowing for easier control by plugins

    method wait_for_completed_stage => sub {
        my $self         = shift;
        my $finished_job = $self->next_finished_job;
        my $name         = $finished_job->stage->_full_name;
        my $stage        = $self->_stages->{$name};
        if ($stage->_has_command) {
            $stage->_analyse_completion_state($finished_job);
        }
        else {
            $stage->_set_state( $finished_job->status ? 'fail' : 'pass' );
        }
        # if ($stage->is_pass && ! $stage->_files_acceptable_for_completed_stage($finished_job)) {
            # $self->fail_stage( $stage )
        # }
        if ($stage->is_fail
                && $stage->_chosen_retries < $stage->choose_retries
                && ($finished_job->_analysis_chose_retry
                    || ( $stage->_has_should_choose_retry
                        && $stage->should_choose_retry->(
                            $finished_job->stats,
                            $finished_job->_stderr
                        )
                    )
                )
            ) {
            $stage->_set_state('retry');
            $stage->_chosen_retries($stage->_chosen_retries+1);
            $self->info( "Using user chosen retry: ",
                $stage->_chosen_retries,
                " of ",
                $stage->choose_retries,
            );
        }
        if ($stage->is_fail && $stage->_forced_retries < $stage->force_retries) {
            $stage->_set_state('retry');
            $stage->_forced_retries($stage->_forced_retries+1);
            $self->info( "Using forced retry: ",
                $stage->_forced_retries,
                " of ",
                $stage->force_retries,
            );
        }
        $stage->_files_actions_after_success if $stage->is_pass;

        my $state = $stage->state;
        $finished_job->stats->{final_job_state} = $state;
        my $index = $finished_job->index;
        $self->info("stage($name) run($index) completion state: $state");
        return $stage;
    };

=head1 NAME

    HPCI::Group

=head1 SYNOPSIS

Role for building a cluster-specific driver for a group
of stages.  This should only be used internally to the
C<HPCI> module - code that uses this driver will
not load this module (or the driver module) explicitly.

It describes the user interface for a generic group, hiding
(as much as possible) the specifics of the actual cluster that
is being used.  The driver module that consumes this role will
arrange to translate the generic interface into the particular
interface conventions of the specific cluster that it accesses.

An (internally defined) cluster-specific group object is
defined with:

    package HPCD::$cluster::Group;
    use Moose;

    ### required method definitions

    with 'HPCI::Group' => { StageClass => 'HPCD::$cluster::Stage' },
        # any other roles required ...
        ;

    ### cluster-specific method definition if any ...

=head1 DESCRIPTION

This role provides the generic interface for a group object
which can configure and run a collection of stages (jobs)
on machines in a cluster.  It is written to be independent
of the specifics of any particular cluster interface.  The
cluster-specific module that consumes this role is not accessed
directly by the user program - they are provided with a group
driver object of the appropriate cluster-specific type using
the "class method" HPCI->group (with an appropriate
C<cluster> argument) to request an appropriate to build it.

=head1 ATTRIBUTES

=head2 name (optional)

The name of this group of stages.  Defaults to 'default_group_name'.
Not actually required for a group.

=cut

    has 'name' => (
        is       => 'ro',
        isa      => 'Str',
        default  => 'default_group_name',
    );

=head2 cluster

The type of cluster that will be used to execute the group of stages.
This value is passed on internally by the HPCI->stage method when it
creates a new stage, or by the group->subgroup method when it creates
a new subgroup.  Since it also uses that value to select the type
of group object that is created, it is somewhat redundant.

=cut

    has 'cluster' => (
        is       => 'ro',
        isa      => 'Str',
        required => 1,
    );

=head2 base_dir (optional)

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
=head2 storage_classes (optional) (Not currently used, needs work)

HPCI has two conceptual storage types that it expects to be available.

Long-term storage is storage that is reliably preserved over time.
The data in long-term storage is accessible to all nodes on the
cluster, but possibly only accessible through special commands.

Working storage is storage that is directly-accessible to a node
through normal file system access methods.  It can be a private disk
that is not accessible to other nodes, or it can be a shared file
system that is available to other nodes.

It is fairly common, and most convenient, if the working storage also
qualifies as long-term storage.  That is the default expectation if
HPCI is not told otherwise.

However, some types of cluster can have their nodes rebuilt at intervals,
losing the data on their local disks.  Some types of cluster have a
shared file system that is not strongly persistent, but which can be
rebuilt at intervals.  Some types of cluster have shared file systems
that have size limitations that mean that some or all of the data sets
for stage processes cannot be stored there.

In such cases, some or all of the files must have a long-term storage
location that is different from the more convenient working storage
location that will be used when stages are running.  Depending upon the
environment, the long-term storage will use something like:

=over 4

=item network accessed storage

A storage facility that allows file to be uploeded and downloaded through
a netowrk connection (from any node in the cluster).

=item parent managed storage

The job controlling program may have long-term storage of it own that
is not accessible to other nodes in the cluster.  If there is a large
enough shared file system (that for some reason cannot be used as long-term
storage) the parent HPCI program can copy files between that storage and
the shared storage as needed to make the files available and to preserve
the results.

=item bundled storage

In a B<cloud> layout there is often no file system shared amongst all of
the nodes and the parent process.  In this type of cluster, a submitted
stage will include some sort of bundle containing a collection of data
and control files (possibly even the entire operating system) to be used
by the stage, and a similar sort of bundle is recovered to provide the
results of running a stage.  (This could be, for example, a C<docker>
image.)

=back

The attribute C<storage_classes> defines the available storage classes
that can be used for stage files.

In most cases, all files for all stages will be of the same storage
class, but some cluster configurations will have multiple storage
choices and can have, for some stages, the need to use more than one of
the storage classes for different files within the same job.

To cater to both of these, the C<storage_classes> attribute can either be
a single arrayref which will be used for all files, or it can be a hash of
named arrayrefs, with the name being used to select the class for each
individual file.  A file (described in the C<files> attribute of the C<stage>
class) can either be a scalar string specifying the pathname of the working
storage location that will be used, or it can be a one element hashref, with
the key selecting the storage class and the value providing the working
storage pathname.  If the hash of named arrayrefs is used, one of the
elements of the hash should have the key C<default> - that will be used for
files which do not provide an explicit storage class key.

The default value for this attribute is:

    [ 'HPCI::File ]

The HPCI::File class defines the usage for the common case in which there is
no need for a long-term storage area that is different from the working
storage area.

Classes that provide to separate long-term storage area will usually require
additional arguments, for specifying access control information (such as url,
username, password) and how to map the working storage pathname into the
corresponding location in the long-term storage.

See the documentation for HPCI::File for details on writing new classes.

=head2 file_class

The default storage class attribute for files that do not
have an explicit class given.  This is the name of a class.
The default is HPCI::File, but a sub-class of HPCI::File can
be provided instead.

=cut

has 'file_class' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => 'HPCI::File',
);

=head2 _default_file_info (internal)

This over-rides the _default_file_info method from HPCI::Super
which sets the default contents of the C<file_params> attribute.
HPCI::Super normally copies from the parent group, but since this
top-level group has no parent it is set to an empty hash.

=cut

sub _default_file_info { return { } };

=head2 _unique_name (internal)

The name of the top level group with a timestamp added to make it
unique so that the directory created to hold to files from the
execution of the group will not conflict with other runs.

=cut

    has '_unique_name' => (
        is       => 'ro',
        isa      => 'Str',
        lazy     => 1,
        init_arg => undef,
        default  => sub {
            my $self = shift;
            my $name  = $self->name;
            my $tstamp = DateTime->now->strftime("%Y%m%d-%H%M%S");
            return "$name-$tstamp";
        },
    );

    has '_stages' => (
        is       => 'ro',
        isa      => "HashRef[$StageClass]",
        lazy     => 1,
        init_arg => undef,
        default  => sub { {} },
    );

    method _register_stage => sub {
        my $self     = shift;
        my $stage    = shift;
        my $name     = $stage->name;
        my $fullname = $stage->_full_name;
        $self->info( "Created stage($fullname)" );
        $self->_stages->{$fullname} = $stage;
        $self->_stage_cnt( $self->_stage_cnt + 1 );
        $self->_ready->{$fullname} = 1;
    };

    has '_subgroups' => (
        is       => 'ro',
        isa      => "HashRef[HPCI::Subgroup]",
        lazy     => 1,
        init_arg => undef,
        default  => sub { {} },
    );

    method _register_subgroup => sub {
        my $self     = shift;
        my $subgroup = shift;
        my $name     = $subgroup->name;
        my $fullname = $subgroup->_full_name;
        $self->info( "Created subgroup($fullname)" );
        $self->_subgroups->{$fullname} = $subgroup;
    };

=head2 connect (optional)

This can contain a value to be used by the driver for types of cluster
where it is necessary to connect to the cluster in some way.  It can
be omitted for local clusters that are directly accessible.

=cut

    has 'connect' => (
        is       => 'ro',
        isa      => 'Str',
    );

=head2 login, password (optional)

This can contain a value to be used by drivers for
clusters which carry out a connection process which
require a login and password or some other similar
authorization data.

=cut

    has [ qw(login password) ] => (
        is       => 'ro',
        isa      => 'Str',
    );

=head2 max_concurrent (optional)

The maximum number of stages to be running concurrently.  The value 0
(which is the default) means that there is no limit applied directly by
HPCI (although the underlying cluster-specific driver might apply
limits of its own).  This limit is for the group and there is no
mechanism provided at present to manage the number of stages for a
user across separately invoked programs.  So, if your cluster requires
the user to limit the number of separate jobs a user is running
simultaneously then this can only be a partial solution for you.

=cut

    has 'max_concurrent' => (
        is       => 'ro',
        isa      => 'Int',
        default  => 0,
    );

=head2 status (provided internally)

After the execute method has been called, this attribute contains the
return result from the execution.  This is a hash (indexed by stage
name).  The value for each stage is an array of the return status.
(Usually, this array has only one element, but there will be more
if the stage was retried.  The final element of the array is almost
always the one that you wish to look at.)  The return status is a
hash - it will always contain an element key 'exit_status' giving
the exit status of the stage. Additional entries will be found in
the hash for cluster-specific return reults.  Thus, to check the
exit status of a particular stage you would code either:

    $result = $group->execute;
    if ($result->{SOMESTAGENAME}[-1]{exit_status}) {
        die "SOMESTAGENAME failed!";
    }

or:

    $group->execute;
    # ...
    if ($group->status->{SOMESTAGENAME}[-1]{exit_status}) {
        die "SOMESTAGENAME failed!";
    }

=cut

    has 'status' => (
        is       => 'ro',
        isa      => 'HashRef',
        lazy     => 1,
        init_arg => undef,
        default  => sub { {} },
        writer   => '_set_status',
    );

=head2 file_system_delay

Shared files systems can have a delay period during which an action
on the file system is not yet visible to another node sharing that
file system.  This is common for NFS shared file systems, for
example.

The file_system_delay attribute can be given a non-zero number of
seconds to indicate the amount of time to wait to ensure that
actions taken on another node are visible.

This is used for internal actions such as validating that required
stage output files have been created.

=cut

    has 'file_system_delay' => (
        is       => 'ro',
        isa      => 'Int',
        lazy     => 1,
        default  => 0,
    );

#### Internal attributes

    has [qw(_deps _pre_reqs)] => (
        is       => 'ro',
        isa      => 'HashRef[Str]',
        lazy     => 1,
        init_arg => undef,
        default  => sub { {} },
    );

    has [qw(_stage_cnt _running_cnt _finished_cnt)] => (
        is       => 'rw',
        isa      => 'Int',
        default  => 0,
    );

    has [qw(_ready _blocked _submitted _completed _failed)] => (
        is       => 'ro',
        isa      => 'HashRef',
        init_arg => undef,
        default  => sub { {} },
    );

    has [qw(_sub_secs _sub_microsecs)] => (
        is       => 'rw',
        isa      => 'Int',
        init_arg => undef,
        default  => 0,
        );

    has '_execution_started' => (
        is       => 'rw',
        isa      => 'Int',
        init_arg => undef,
        default  => 0,
    );

=head1 METHODS
=cut

=head2 $group->execute

Execute the stages in the group.  Does not return until all stages
are complete (or have been skipped because of a failure of some
other stage or the attempt is aborted).

=cut

    method execute => sub {
        my $self = shift;
        my $catcher = sub {
            my $sig = shift;
            $self->warn( "Killed with signal SIG$sig" );
            $self->kill_stages;
        };
        local $SIG{HUP} = $catcher;
        local $SIG{USR1} = $catcher;
        local $SIG{USR2} = $catcher;
        $self->_execution_started(1);
        local $SIG{CHLD} = $SIG{CHLD};
        $self->child_catcher;
        my $cnt = $self->_stage_cnt;
        my $s   = $cnt == 1 ? '' : 's';
        $self->info( "Starting execution with $cnt stage$s defined.");
        while ($self->_finished_cnt < $self->_stage_cnt) {
            $self->_submit_ready || next;
            unless (keys %{ $self->_submitted }) {
                my $blocked = join( ', ', keys %{ $self->_blocked } );
                $self->_discard_list( "Deadlock" );
                $self->_croak("Deadlock - cannot submit any more jobs, remaining jobs ($blocked) are blocked, there must be a dependency loop.")
            }
            $self->_await_one_job;
        }
        my $ret_stat = {};
        while (my ($name, $stage) = each %{ $self->_stages }) {
            my $base_name = $stage->name;
            next if $base_name =~ m/^__(START|END)__$/;
            my @subgroups;
            my $check = $stage;
            while (my $parent = $check->group) {
                last unless $parent->does('HPCI::Sub');
                unshift @subgroups, $parent->name;
                $check = $parent;
            }
            my $ret_hash = $ret_stat;
            while (my $subgroup = shift @subgroups) {
                $ret_hash = $ret_hash->{$subgroup} //= {};
            }
            $ret_hash->{$base_name} = $stage->get_run_stats;
        }
        $self->info( "All done!  Stage status:" );
        $self->_disp_status( "  Group", $self->name, $ret_stat );
        $self->_set_status($ret_stat);
        $self->systemlogger->($self,$ret_stat)
            if $self->can('systemlogger') && $self->_has_systemlogger;
        return $ret_stat;
    };

    method _disp_status => sub {
        my $self     = shift;
        my $type     = shift;
        my $name     = shift;
        my $hash     = shift;
        my $fullname = shift // $name;
        my $indent   = shift // '';
        my @stages;
        my @subgroups;
        return unless %$hash;
        $self->info( "$indent$type $name" );
        $indent .= '  | ';
        map {
            my $val = $hash->{$_};
            push @{ ref($val) eq 'HASH' ? \@subgroups : \@stages }, [ $_, $val ];
        } sort keys %$hash;
        if (@stages) {
            for my $stageinfo (@stages) {
                my ($sname,$runs) = @$stageinfo;
                $self->info( "${indent}Stage $sname   ($fullname/$sname)" );
                for my $runnum (0..$#$runs) {
                    my $run = $runs->[$runnum];
                    my $runnumdesc =
                        $runnum != $#$runs ? "Retried run $runnum"
                        : $runnum          ? "Final run after $runnum retries"
                        :                    "Only run - no retries";
                    $self->info( "$indent    $runnumdesc" );
                    $self->info( sprintf "$indent      %-20s => %s", $_, $run->{$_} )
                        for sort keys %$run;
                }
            }
        }
        if (@subgroups) {
            for my $sginfo (@subgroups) {
                my ($name, $childinfo) = @$sginfo;
                $self->_disp_status( "Subgroup", $name, $childinfo, "$fullname/$name", $indent );
            }
        }
    };

    # sub wait_for_all_jobs {
    #   # TODO: Never called, so the html report is never written!
    #   #       Merge this code into execute when it is ready to work
    #   my $self = shift;
    #
    #   # Already done differently in execute
    #   my $runs = [];
    #   while ((scalar (keys %{$self->_runs})) > 0) {
    #       push($runs, $self->next_finished_job);
    #   }
    #
    #   # modify for the different layout of run status info in execute
    #   if ($self->generate_html_report) {
    #       $self->info("Building html report\n");
    #       $self->render_template_to_file(
    #           template_name       => 'report.html.template',
    #           output_file_path    => $self->html_report_path,
    #           rendering_variables => {
    #               jobs               => $runs,
    #               report_root_url    => $self->html_report_url,
    #           }
    #       );
    #   }
    #   else {
    #       $self->info("No html report to build\n");
    #   }
    #
    #   # execute already returns its different structure
    #   return $runs;
    # }


### Internal methods


    # _croak
    #     Kill off any executing stages, issue an error message, and quit.
    #     Make sure that the quit happens even if the rest of the cleanup fails

    method _croak => sub {
        my $self = shift;
        my $msg  = shift;
        my $fatalfailed;
        try {
            $self->fatal($msg);
        }
        catch {
            ++$fatalfailed;
        };
        try {
            $self->kill_stages if $self->_finished_cnt < $self->_stage_cnt;
        }
        catch {
            try {
                $self->fatal("Additional failure during cleanup: $_")
                    unless $fatalfailed;
            }
        };
        confess $msg;
    };

    # _submit_ready
    #   - submit all stages that are ready to be run
    #   - that will be stages which have no pre_reqs, or for which all pre_reqs
    #     have completed successfully

    method _submit_ready => sub {
        my $self              = shift;
        my $min_submit_window = 500_000;  # 0.5 second
        my $min_delay         =   1_000;  # 1 millisecond is not worth a delay
        $self->info("Searching for unblocked stages to submit.\n");
        while ( keys %{ $self->_ready } ) {
            # tricky loop through all of the keys of the _ready list
            # cannot just use: for my $name ( keys %{ $self->_ready } )
            # as the loop because the loop will be not just deleting $name
            # (which the for loop is guaranteed to survive and still return
            # all of the keys), but it can also add new keys when a stage
            # is elegible to be skipped.  That could cause the for loop to
            # terminate while there are still keys in the hash, and might
            # give the appearance of a dependency loop where there is not
            # really one present.
            (my $name) = keys %{ $self->_ready };
            return 1 if $self->max_concurrent
                     && $self->max_concurrent <= $self->_running_cnt;
            delete $self->_ready->{$name};
            my $stage = $self->_stages->{$name};
            my ($check, $type) =
                $stage->name eq '__START__'
                    ? ( $stage->group, 'subgroup' )
                    : ( $stage,        'stage'    );
            my $checkname = $check->_full_name;
            $stage->assert_command_filled;
            if ($check->_can_be_skipped) {
                $self->info("Determined that $type ($checkname) can be skipped.\n");
                if ($type eq 'stage') {
                    $self->_completed->{$name} = 1;
                    $self->_finished_cnt( $self->_finished_cnt + 1 );
                    $self->_unblock_deps($name);
                    $stage->_set_state('pass');
                    return 0;
                }
                else {
                    $self->_skip_subgroup($checkname);
                }
            }
            if ( ! $stage->_files_ready_to_start_stage) {
                # required in file not present, abort running the stage
                $self->fail_stage( $name, $stage );
                $self->_finished_cnt( $self->_finished_cnt + 1 );
                $self->_discard_deps($stage);
                return 0;
            }
            $self->_running_cnt( $self->_running_cnt + 1 );
            $self->_submitted->{$name} = 1;
            my ( $now_secs, $now_microsecs ) = gettimeofday;
            if ($stage->_has_command && $now_secs < $self->_sub_secs + 2) {
                my $delta_microsecs =
                    ( $now_secs - $self->_sub_secs ) * 1_000_000 +
                    ( $now_microsecs - $self->_sub_microsecs );
                $delta_microsecs = $min_submit_window - $delta_microsecs;
                if ($delta_microsecs > $min_delay) {
                    $self->info(
    "Safety delay ($delta_microsecs) microseconds before submit.\n"
                        );
                    usleep($delta_microsecs) if $delta_microsecs;
                    $now_microsecs += $delta_microsecs;
                    # 'while' instead of 'if'
                    # to allow delay bounds to be adjusted in the future
                    while ($now_microsecs > 1_000_000) {
                        $now_microsecs -= 1_000_000;
                        $now_secs++;
                    }
                }
            }
            $self->_sub_secs($now_secs);
            $self->_sub_microsecs($now_microsecs);
            $self->info("Submitting stage ($name).\n");
            $self->submit_stage( $stage );
        }
        return 1;
    };

    # _unblock_deps
    #   - after a stage has finished successfully, any stages that are
    #     dependent upon it can be (possibly partially) unblocked
    #   - if this is the final block for a dependent, it is marked ready to run

    method _unblock_deps => sub {
        my $self    = shift;
        my $pre_req = shift;
        for my $dep ( keys %{ $self->_deps->{$pre_req} } ) {
            delete $self->_pre_reqs->{$dep}{$pre_req};
            $self->debug( "removing dep: $pre_req -> $dep, remaining deps are( "
                . join( ' ', sort keys %{ $self->_pre_reqs->{$dep} } )
                . " )" );
            unless (keys %{ $self->_pre_reqs->{$dep} }) {
                $self->_ready->{$dep} = 1
                    if delete $self->_blocked->{$dep};
            }
        }
    };

    # _blocked_deps_list
    #   - get all deps recursively

    method _blocked_deps_list => sub {
        my $self   = shift;
        my $target = shift;
        my $seen   = shift // {};

        for my $dep ( grep { !$seen->{$_} && $self->_blocked->{$_} }
            keys %{ $self->_deps->{$target} } )
        {
            $seen->{$dep} = 1;
            $self->_blocked_deps_list( $dep, $seen );
        }
        return $seen;
    };

    # _discard_deps
    #   - after a stage has failed. the action to be taken is determined by the
    #     setting of the failure_action attribute
    #
    #     - abort_group
    #       - discard all unstarted stages
    #     - abort_deps
    #       - discard all stages that are deps of the failed stage
    #         (and their deps, recursively)
    #     - ignore
    #       - continue with all other stages

    method _discard_deps => sub {
        my $self = shift;
        my $stage = shift;

        my $action = $stage->failure_action;

        return                                   if $action eq 'ignore'; 

        my $name = $stage->name;
        $self->_discard_list(
            "failure of stage $name",
            $action eq 'abort_deps'
                ? $self->_blocked_deps_list( $name )
                : () # $action eq 'abort_group'
        );
    };

    method _discard_list => sub {
        my $self     = shift;
        my $reason   = shift;
        my $list     = shift // $self->_blocked;
        unless (defined $list) {
            # discard all blocked stages, if no explicit list was provided
            $list = $self->_blocked;
        }
        my @discards = sort keys %$list;
        for my $stage (@discards) {
            $self->error(
                "Skipping stage ($stage) because of $reason");
            $self->_finished_cnt( $self->_finished_cnt + 1 );
            delete $self->_blocked->{$stage};
            $self->_failed->{$stage} = 1;
            $self->_stages->{$stage}->_set_failure_info(
                "Skipped because of $reason");
        }
    };

    # _await_one_job
    #   - wait until a running stage completes
    #     - if it failed: remove any stages that depend upon it
    #       (or all remaining jobs if abort_group_on_failure was set)

    method _await_one_job => sub {
        my $self  = shift;
        my $stage = $self->wait_for_fully_completed_stage;
        my $fullname  = $stage->_full_name;

        delete $self->_submitted->{$fullname};
        $self->_finished_cnt( $self->_finished_cnt + 1 );
        $self->_running_cnt( $self->_running_cnt - 1 );
        if ($stage->is_pass) {
            $self->info("Successful completion of stage ($fullname).\n");
            $self->_completed->{$fullname} = 1;
        }
        else {
            # job failed and cannot be resubmitted
            $self->fail_stage( $fullname, $stage );
        }
        $self->_unblock_deps($fullname);
    };

    method _skip_subgroup => sub {
        my $self     = shift;
        my $subgroup = shift;
        my @consider = ( $subgroup->_full_name . '/__END__' );
        my %skipping = ();
        my $comp     = $self->_completed;
        while (my $next = shift @consider) {
            # next if $comp->{$next};
            # unshift @members, $next;
            for my $pred ( @{ $self->_pre_reqs->{$next} } ) {
                next if $comp->{$next} || $skipping{$pred}++;
                unshift @consider, $pred;
            }
        }
        $self->_discard_list( "part of subgroup ($subgroup) being skipped", \%skipping );
    };

    method fail_stage => sub {
        my $self  = shift;
        my $fullname  = shift;
        my $stage = shift;
        $self->error( "Failed stage ($fullname).\n" );
        $self->_failed->{$fullname} = 1;
        $self->_discard_deps( $stage );
        $stage->_set_state( 'fail' );
    };

    # wait for a stage to complete
    #   - if it failed, determine whether it can be retried
    #
    # if it can be restarted, it will be marked as such, and any recomputing
    # of its internal info required for the retry will have already been done.
    # All that is required is to actually resubnit it for execution
    #
    # return the first completed stage that does not need to be restarted
    method wait_for_fully_completed_stage => sub {
        my $self = shift;
        while (1) {
            my $stage = $self->wait_for_completed_stage;
            return $stage unless $stage->is_retry;
            $self->retry($stage);
        }
    };

    # this method can be over-ridden if cluster-specific code needs to take
    # any action different from the submit done initially that can't be
    # handled already in the wait_for_completed_stage method
    method retry => sub {
        my $self  = shift;
        my $stage = shift;
        $self->warn( "Retrying stage(".$stage->name.")");
        $self->submit_stage($stage);
    };

};

=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros http://www.omgubuntu.co.uk/2016/03/vineyard-wine-configuration-tool-linuxLab

The Ontario Institute for Cancer Research

=cut

1;

