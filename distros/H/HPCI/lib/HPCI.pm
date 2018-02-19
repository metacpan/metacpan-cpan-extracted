package HPCI;
### HPCI.pm ###################################################################

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Module::Load;
use Module::Load::Conditional qw(can_load);
use List::MoreUtils qw(uniq);

our @extra_roles;

sub add_extra_role {
	# next line is documentation
	# my ($cluster, $level, $role) = @_;
	shift; # get rid of HPCI class name
	push @extra_roles, [ @_ ];
}

sub get_extra_roles {
	my ($target_cluster, $target_level) = @_;
	my @roles;
	for my $role_bunch (@extra_roles) {
		my ($cluster, $level, $roles) = @$role_bunch;
		next unless $cluster eq 'ALL' || $cluster eq $target_cluster;
		next unless $level eq $target_level;
		push @roles, ref $roles ? @$roles : $roles;
	}
	return @roles;
}

my $default_attrs = {};

sub add_default_attrs {
	shift; # get rid of HPCI class name
 	my $newhash = ref($_[0]) eq 'HASH' ? shift : { @_ };
	_merge_hash( $default_attrs, $newhash );
}

sub _merge_hash {
	my( $target, $new, $path ) = @_;
	$path ||= [];
	croak "not a hash when merging attribute hash{".join('}{',@$path)."}"
		unless ref($target) eq 'HASH' && ref($new) eq 'HASH';
	while (my($k,$v) = each %$new) {
		if (ref($v) eq 'HASH' || (exists $target->{$k} && ref($target->{$k}) eq 'HASH')) {
			$target->{$k} //= {};
			_merge_hash( $target->{$k}, $v, [ @$path, $k ] );
		}
		else {
			$target->{$k} = $v;
		}
	}
}

sub explist {
	return (
		map {
			ref($_) eq 'ARRAY' ? @$_
			: defined($_)      ? ( $_ )
			:                    ( )
		} @_
	);
}

# get the env_keys, in original order, but use *LAST* instance
# that retains the order specified in either default or args
# but lets the relative order in args take precedence for keys
# that are in both
#
# So, the order is:
# [ keys that are only in default in the order they were specified in default ]
# [ then keys that are in args in the order they were specified in args ]
# No complaint is made if the same key is specified twice in either default
# or args, the earlier one(s) are simply ignored.
sub keylist {
	my @keys;
	for my $arg (@_) {
		my $keys = (delete $arg->{env_keys}) // [];
		push @keys, @$keys;
	}
	return (reverse uniq reverse @keys);
}

sub group {
	my $pkg = shift;
	my $args =
		scalar(@_) == 1 && ref($_[0]) eq 'HASH' ? shift
		: scalar(@_) % 2 == 0                   ? { @_ }
		: croak("HPCI->group() requires a hashref or a hash in list form");
	# copy the default attributes as a start
	my $use_args = {};
	_merge_hash( $use_args, $default_attrs );

	# pull out the env_keys (if any)
	my @keys = keylist( $use_args, $args );
	my @key_specific = map { $_->{env_key_specific} // () } $use_args, $args;

	# merge any specified env_key list that has a value available
	for my $key (@keys) {
		for my $key_spec (@key_specific) {
			if (my $spec_args = $key_spec->{$key}) {
				_merge_hash( $use_args, $spec_args );
			}
		}
	}

	my $cluster = $args->{cluster} // $use_args->{cluster}
		// croak("HPCI->group() requires a cluster key in the argument hash");

	for my $arg_set ($use_args, $args) {
		if (my $spec_args = delete $arg_set->{cluster_specific}) {
			_merge_hash( $use_args, $spec_args->{$cluster} // {} );
		}
	}
	_merge_hash( $use_args, $args );
	my $clmod = "HPCD::${cluster}::Group";
	load $clmod;
	return $clmod->new($use_args);
}


sub _trigger_mkdir {
	my $self = shift; # an object with a log
	my $dir  = shift; # a Path::Class::Dir object
	$self->info( "Created directory: $_" ) for $dir->mkpath;
}

=head1 NAME

    HPCI

=head1 VERSION

Version 0.60

=cut

our $VERSION = '0.60';

our $LocalConfigFound;

$LocalConfigFound = can_load( modules => { 'HPCI::LocalConfig' => undef });

if (!$LocalConfigFound) {
	my $err = $Module::Load::Conditional::ERROR;
	if (defined $err && $err !~ /^Could not find or check module /) {
		print STDERR "Conditional load of HPCI::LocalConfig failed.  Error is:\n";
		print STDERR "$err\n";
	}
}

=head1 SYNOPSIS

    use HPCI;

    my $group = HPCI->group(
        cluster => ($ENV{HPCI_CLUSTER} // 'uni'),
        ...
    );
    $group->stage(
        name => 'analysis_A',
        command => '...'
    );
    $group->stage(
        name => 'analysis_B',
        command => '...'
    );
    $group->stage(
        name => 'analysis_C',
        command => '...'
    );
    $group->stage(
        name => 'report',
        command => '...'
    );
    $group->add_deps(
        pre_reqs => [ qw(analysis_A analysis_B analysis_C) ],
        dep => 'report'
    );

    my $status_info = $group->execute;

    my $exit_status = 0;
    for my $stage ( qw(analysis_A analysis_B analysis_C report) ) {
        if (my $stat = $status_info->{$stage}[-1]{exit_status}) {
            $exit_status ||= $stat;
            print stderr "Stage $stage failed, status $stat!\n";
        }
    }

	exit(0); # all stages completed without error

=head1 OVERVIEW

HPCI (High Performance Computing Interface) provides an interface to
a range of types of computer aggregations (clusters, clouds, ...).
(The rest of this document will use I<cluster> henceforth to refer
to any type of aggregation that is supported by HPCI.)

A cluster is defined as a software interface that allows running
multiple programs on separate compute elements (nodes).

HPCI uses an HPCD (High Performance Computing Driver) module
to translate its standard interface into the appropriate access
mechanisms for the type of cluster that is selected.  (If you have
used the DBI/DBD modules for accessing databases, this will seem
very familiar.)

The goal of this HPCI/HPCD split is to allow users to write
programs that make use of cluster facilities in a portable manner.
If there is a reason to run the same program using a different
type of cluster, it should only require change the cluster
definition attributes provided to one parent object creation; the
rest of code need not know or care about the changed cluster type.
Programs which are likely to be run on different cluster types will
usually be written to get the cluster attribute information from
a configuration file, or command line arguments - so the program
itself need not change at all.

Running a program on different types of clusters can happen for a
number of reasons.  An organization might have access to multiple
types of cluster, such as an in-house cluster plus an external cloud.
Scholarly research often shares programs both to allow similar
research, or to validate existing research results.

HPCD modules can provide cluster-specific extensions.  That can
either be a different kind of functionality, or it can be as simple
as allowing the teminology familiar to users of that cluster type
to be used in place of the generic terminology provided by HPCI.
However, using such extensions makes it harder to move to a
different cluster type.  So, actually making use of such extensions
must be considered carefully.

=head1 The life cycle of a B<group>

A B<group> is the main mechanism for using HPCI.  It is an object that
manages a group of computation steps (called B<stage>s), distributing them
across the cluster and keeping track of various housekeeping details like
when each stage can be run, checking for the result of each completed stage
run, deciding whether a failure should cause a stage to be retried to to
prevent other stages from being executed, and collecting the status for each
stage.

The life cycle of running a group of commands on a cluster is:

=over 4

=item create group

A B<group> object is created using the HPCI "class method" B<group>.
HPCI isn't really a class, it just appears to be one.  Its B<group>
"class method" actually delegates creation of a group object to
the HPCD module that is indicated by the I<cluster> attribute
and it returns an cluster-specific group object that supports the
HPCI interface.

=item create stages

A B<stage> is created for each command that is to be executed on a
separate node of the cluster.  This is created using the B<group>
object's method B<stage>.

=item define dependency ordering between the stages

An important reason for running a group of jobs on a cluster is the
ability to use multiple computers to run portions of the computation
at the same time, rather than having them compete for the rsources
of a single computer.  However, often some stages will depend
upon the output of other stages.  Such a dependent stage cannot
start executing until all pre-requisite stages have completed.
Specifying such dependency requirements is done with the B<group>
method B<add_deps>.

=item execution

Finally, the B<group> method B<execute> will run the entire set
of stages.  It does not return until all stages have completed (or
have been skipped).  Each stage will normally be run once, however
it is possible for some stages to be retried under some
failure conditions.
A failure of one stage (after retry possibilities have been exhausted)
can be a trigger for
completely skipping the execution of other stages.  Each separate
execution of a stage (original or retry) is managed with an internal object
called a job - but a user program won't see job objects directly.

As many stages as possible are run simultaneously.  This is limited by
the specified dependencies, by cluster-specific driver limits, and by
user-specified limits on concurrent execution.

=back

The objects that calling code deals with directly are a group object to
manage a group of stages, and a stage object for each separately run job.
Internally, there are also job objects for each retry of a stage, and a
log object for logging the execution process (alternately, the user can
provide their own Log4Perl compatible log object for HPCI to use - this may be
of use if you wish to merge logging of multiple groups and/or of other
processing within your program together in a single log).

There are also some facilities to provide local customization of the standard
usage of HPCI (see "Local Customization" below).

=head1 Output Tree Layout

There are a number of output files and directories created during a group execution.

The default layout of these is:

  <base_dir>                     "."
    <group_dir>                  <base_dir>/<name>-<YYYYMMDD-hhmmss>
      <log>                      <group_dir>/<name>.log
      <stage_dir>                <group_dir>/<stage_name>
        <script_file>            <stage_dir>/script.sh
        <job_dir>                <stage_dir>/<retry_number>
          stdout
          stderr
        final_retry              symlink to final <job_dir>

Many of these files/directories can be re-assigned to different
location using group or stage attributes - shown above is the
default layout.  Commonly, you will specifically use the I<base_dir>
attribute to choose a location other than the current directory for
placing the tree; or else use the I<group_dir> attribute if you want
to choose a location that does not create a sub-directory for you.
(If this is an already existing directory that is being re-used you
may end up with a mixture of old and new contents that are hard to
figure out.)

=over 4

=item base_dir

The top level of all the generated output.  It defaults to ".",
but can be specified explicitly when the group is created with
the attribute B<base_dir>.

=item group_dir

By default, a new directory is created under B<base_dir>.  Its name
is I<name>-I<YYYYMMDD>-I<hhmmss> - the name of the group along with
a timestamp of when the execution started.  This can be over-ridden
when the group is created by providing the group attribute B<group_dir>.

=item log

The automatically provided log is written to the file I<"group.log">
directly under I<group_dir>.  This logs information about the
execution of the entire group of stages.  See B<Logging Attributes
of group object> below for ways of changing the default setting.

=item stage_dir

Each stage creates a sub-directory beneath I<group_dir> with the
same name as the stage.  An alternate name can be used by providing
the B<dir> attribute when the stage object is created.

=item script_file

The script created to be executed on the cluster node.  This wraps
the specified command with additional logic to pass on environment
and config info, and to set output redirection.  It is called
"script.sh" and placed in I<stage_dir>.

=item job_dir

A sub-directory is created under I<stage_dir> for each attempt to
run the command.  Usually, there will only be a single attempt.
However, if the cluster driver provides mechanisms for detecting
recoverable issues and then retries a command there can be more
than one attempt; or alternately, if a pre-requisite stage
fails there might be no attempt made (in that case, though,
the entire I<stage_dir> directory would not even get created).
These directories are simply named with the retry number ("0",
"1", ...).

=item stdout/stderr

Within each I<job_dir>, the files "stdout" and "stderr" collect
the standard output and standard error output from that (re)try
attempt to run the command.

=item final_retry

A symlink named "final_retry" is created within I<stage_dir> that
points to the I<job_dir> of the final (re)try.  Since you often
don't care as much about the initial run tries as you do about the
last one, this symlink provides a consistant access path to that
final retry.

=back

=head1 HPCI "Class" Methods

You can pretend that B<HPCI> is a class with one primary class
method named B<group>.

There a few other class methods used for localization purposes, they
are decribed below in "Local Customization".

=head2 B<group> method

The B<group> method creates and returns a group object, which
you can treat like a B<HPCI::Group> object.  (In fact, it really
returns an object of class B<HPCD::I<cluster>::Group>, but if you
ignore that fact then you can trivially have your program run on
some other cluster type.)

=head2 B<group> object

The description of attributes and methods for the B<group> object given here describe
the generic attributes and how they are treated for all cluster types.
Individual cluster drivers can modify this behaviour and can provide
additional attributes and methods for cluster-specific purposes.

=head3 Cluster-Related Attributes of B<group> object

The one necessary attribute is B<cluster>.  For some specific
cluster types there may be additional attributes required for
connecting to the cluster software (authentification, usage
class info, etc.).

=over 4

=item cluster

The B<cluster> attribute specifies which type of cluster is to be used.
This is the only required attribute.  (Some cluster types may have
additional attributes that are required for specifying connection
and authentification info.)

=item cluster_specific

The attribute B<cluster_specific> is optional.  If provided, it should
contain a hashref of hashrefs.  If the value specified for the I<cluster>
attribute is present as a key in the B<cluster_specific>
hash, the corresponding value will be used as a set of attribute values
when the group is created.  Its elements will replace or augment any values
for the same attribute name provided to the group method.  This will normally be
used if the program can be dynamically configured for different cluster
types, and there are different arg settings required for the different
types of cluster.

=back

=head3 Basic Attributes of B<group> object

=over 4

=item name

The B<name> you give to a group is used for creating the directory
where output is stored, and also in log messages.  A default name
"default_group_name" is provided if you do not specific an explicit
name.  Using the default name is adequate in simple programs which
only create one group, but for more complicated programs giving
separate names to each group is necessary to easily identify the
output of each group.  The value of B<name> may also be used by
the cluster-specific driver to provide an identifier name (or the
basis of one) to the underlying cluster, if it needs one.

=item stage_defaults

The attribute B<stage_defaults> is optional.  If provided, it should
contain a hashref.  This hash will be used as default values for
every stage created by this group.

=back

=head3 Directory Layout Attributes of B<group> object

=over 4

=item base_dir

If none of the other directory layout attributes are used to
over-ride this, this attribute specifies the directory in which
all output directories and files will be created.  This is
usually an existing directory; it defaults to the current
directory ".".

=item group_dir

This directory is usually created to contain the outputs of the
group execution.  By default, it is directly under B<base_dir> with
a name that consists of the group name attribute and a timestamp
(e.g. "T_Definition-20150521-153256").

If you provide an explicit value for this parameter, then it
should not be an existing directory containing previous results.
(If it is, the log file will be appended to the previous one, but
the stage directories will over-write equivalently named directories
and files that are created in this run, while leaving unchanged any
that did not recur, so you'll have a mix of old and new contents.)
The names of files and directories created under B<group_dir> are
chosen to be consistent and easy to find automatically.

=back

=head3 Logging Attributes of B<group> object

An HPCI group logs its activities using a Log::Log4perl logger.
The logger can either be provided by the caller, or else HPCI will
create its own.

=over 4

=item log

This a Log::Log4perl::Logger object.  If it is provided as an
attribute to the B<group> creation call, it will be used as it is,
and the other logging attributes will be ignored.

If it is not provided by the user, a new Log::Log4perl::Logger
object will be created using the attributes below to define where
it is logged to.  This created logger will send all log entries to
a file, as well as sending all info and higher log entries to stderr.

=item log_path

If this attribute is provided (and the B<log> attribute is not
provided) it will be used as the full pathname of a file where the
log will be written.  If it is not provided, it will use the path
B<log_dir>/B<log_file> by default.

=item log_dir

If neither B<log> or B<log_path> is provided, this attribute can
be used to specify the directory where the log file is to be written.
By default, it uses B<group_dir>.

=item log_file

If neither B<log> or B<log_path> is provided, this attribute can
be used to specify the file name to be written in the log directory.
By default, it uses the constant name "group.log".

=item log_level

You can provide this attribute to change the default log level setting from "info" to any of I<debug info warn error fatal>.

=item log_no_stderr, log_no_file

Normally, the default log is written to both stderr and to the log file.
Either of those can be suppressed by setting the corresponding attribute to a true value.
These attributes have no effect if the user proviedes their own logger instead of using the default one. 

=back

=head3 Operational Attributes of B<group> object

=over 4

=item max_concurrent

This attribute specifies the maximum number of stages that will
be executing at one time.  The default setting of 0 allows as
many stages as possible (all those that are not waiting for a
pre-requisite stage to complete) to run at the same time.

=item status

This attribute is set internally while stages are executed.
It contains the final result status from each stage run that
has completed.  The B<execute> method returns this value when
execution completes, so you will usually not need to access it
explicitly yourself.

This value is a hashref (indexed by stage name).  The values are
arrayrefs (indexed by run number 0..n).  For each run, there is
a hash.  The key B<exit_status> contains the exit status of the run.
If the stage was never run, B<exit_status> instead contains a text
message listing the reason that it was skipped.

=back

=head3 Environment Passing Attributes of B<group> object

You can set up a set of enviroment variables that will be provided to
all stages.  (You can also set variables that are only for individual
stages - if so, they will modify any set you provide in the group.)

See B<HPCI::Env> for a description of these.

=head3 Method B<stage> of B<group> object

The method B<stage> is used to create a new stage object.
Its characteristics are described below.

The B<group> object keeps track of all B<stage> objects created
within that group so that they can all be managed properly when the
B<execute> method is invoked.

=head3 Method B<add_deps> of B<group> object

The method B<add_deps> is used to specify pre-requisite/dependent
relationships.  It takes either a hashref or a list containing
pairs.  One of the keys must be either B<pre_req> or B<pre_reqs>,
another must be either B<dep> or B<deps>.

The value for each of these keys can be either a scalar, or an arrayref
of scalar values.  A scalar value can be either a B<stage> object (a reference),
the exact name of a stage object (a string), or a pattern that matches
the name of zero or more stages (a regexp).

HPCI will ensure that the stage or all of the stages specified for pre_req
or pre_reqs have completed execution before any of the dep (or deps) stages
is allowed to start executing.

The plural forms are provided for convenience - often the output
file from one preparation stage is required by many others, or the
output from many processing stages is needed by a stage that merges
results into a summary report.  Rather than having to loop over the
pre_reqs and deps and calling B<add_deps> individually for every
individual dependency, a single call will handle the entire combination.

Allowing a regexp to match no stages at all makes it possible to write
an add_deps call for stages that are optional - no dependency will be
added if the optional stage was not created this run.

While it is recommended for code readability that you use the singular
form (B<dep> or B<pre_req>) is you are providing a single stage, and the
plural form (B<deps> or B<pre_reqs>) if you are providing a list of
stages, either can be used.

The B<add_deps> method can be called multiple times.  HPCI will
accumlate the dependencies appropriately.

It is an error to provide a sequence of dependencies that form
a cycle in which a stage directly or indirectly has itself as a
pre-requisite.  (Such a stage could never run.  HPCI will detect
when all remaining stages are blocked by pre-requisites and abort,
but that might be after numerous stages have already been executed.)

=head3 METHOD execute of B<group> object

The B<execute> method is the final goal of building the group.
It schedules the execution of individual stages.  It waits for
pre-requisites before running a stage.  It provides for re-running
a stage if a soft failure has occurred that allows a retry.  If a
failure that cannot be retried occurs, it can skip scheduling dependent
stages, or even stop scheduling all new stages.

=head2 Stage Object

=head3 Attributes

=over 4

=item name

A unique B<name> attribute must be provided for stages.  It is a string.
There is no default value provided.

=item command

The B<command> attribute must be provided before the group is
executed.  It can either be provided as a string attribute when the
stage is created, or by using the one of
the command-setting methods provided by the stage class.

See B<HPCI::Stage> for more details about the command setting
methods.

=item dir

The B<dir> attribute is optional.  It specifies the direcory
in which files related to the stage are placed.  By default,
it is I<group_dir>/I<stage_name>.  You will usually not need to
change this.

=item cluster

The B<cluster> attribute is automatically passed on fro mthe B<group>
to each B<stage>.  You are not likely to need this.

=item group

The B<group> that created a stage is automatically passed on (as a weak
reference) to the stage.  You are not likely to need to use this attribute
in user code.

=item resources_required

=item retry_resources_required

The B<resources_required> and B<retry_resources_required> are used to
define resources that will be required by the stage when it executes.
These attributes are somewhat cluster specific - each cluster has
its own set of requirements for how a job submission must specify
the sort of resources that it will require.

The B<resources_required> attribute is a hash, specifying the
value for each resource that is to be considered.

The B<retry_resources_required> attribute is also a hash.  For
each resource, you can specify an array of values.  If the cluster
driver is able to detect that a run failed because the resource
was inadequate, it will retry the run with the next larger value
from this list.

See B<HPCI::Stage> for more details about resources.

=item force_retries

This attribute specifies an integer number of time to retry the
stage before comcluding that it has actually failed.  You might use
this if your cluster has some nodes that work differently from
others and a stage might fail on one type of node but succeed on
another.

These retries are done after any cluster-specific retry mechanisms
have been used.

The default value for this attribute is 0 (zero), giving no forced
retries unless you specifically ask for them.

=item failure_action ('abort_group', 'abort_deps'*, or 'ignore')

Specifies the action to take if this stage fails (terminates with
a non-zero status).

There are three string values that it can have:

=over 4

=item - abort_deps (default)

If the stage fails, then any stages which depend upon it
(recursively) are not run.  The group continues executing until
all stages which are not dependent upon this stage (including those
that have not yet been initiated) complete execution.

=item - abort_group

If the stage fails, then no other stages are started.  The group
simply waits until stages that have already been started complete
and then returns.

=item - ignore

Execution continues unchanged, any dependent stages will be run when they are
no longer blocked.

=back

=item abort_group_on_failure abort_deps_on_failure ignore_failure

As an alternative to providing a value to the failute_action attribute
when you create a stage, you can instead provide one of the pseudo-attributes
'abort_group_on_failure', 'abort_deps_on_failure', or 'ignore_failure' with
a true value to specify 'abort_group', 'abort_deps', or 'ignore' respectively.

=item state

The B<state> is mostly an internal attribute but after the group has
finished execution you can use this to check whether the stage was
run successfully. After execution, B<state> will either be 'pass" or
'fail'.

=item Environment passing attributes

You can set up a set of environment variables that will be provided to
this stage.  It will use set defined for the group as a basis (if such a set was
defined for the group), but that set can be changed for individual stages
or you can have no group default and only provide a set to specific stages
as needed.  See B<HPCI::Env> for further details.

=back

=head3 Methods

=head4 command creation

There are a number of helper methods to assist in building different
types of commands to be provided for the B<command> attribute.
See B<HPCI::Stage> for details.

=head1 Local Configuration

TODO: write this section
 - describe the HPCI::LocalConfig module
 - describe the mechanism for adding extra roles to group, stage, etc.

=head1 Additional

This is an early public release of HPCI, and at present, there are
only two drivers available.

Only one cluster type is directly included within the HPCI package.
The cluster type B<HPCD::uni> runs on a "cluster" of only one
machine.  It simply uses fork to submit individual stages and has
facility for retries and timeouts.  This is the default cluster
type used for testing, as it will work natively on all types of
Unix systems.  It is also possible to use this driver as a fallback,
in cases where the only available "real" cluster is not accessable
for some reason.

Additionally, there is the B<HPCD::SGE> driver available on CPAN.
It has seen heavy use within Boutros Lab.

Now that these packages have been released, it is likely new
cluster drivers will be written.  People interested in developing
drivers for additional cluster types should contact the authors
of this package to co-ordinate releases, features needed, etc. at
B<mailto:BoutrosLabSoftware@oicr.on.ca>.

Additionally, you may wish to subscribe to the email list mentioned
at B<https:://lists.oicr.on.ca/mailman/listinfo/hpci-discuss>.
This is expected to be a low volume discussion group, although the
future will tell what the actual volume will be.

As additional capabilities of new cluster types are addressed, and as
different control needs used at other organizations are identified;
this interface will surely change.  As far as possible, such changes
will be done in an upwardly compatible manner, but until a few more
drivers have been integrated there is the possibility of changes
that are not fully backward compatible.  Watch the release notes
for warnings of such issues.  At some point there will be a 1.0.0
release, at which point this expectation of (limited) incompatible
future change will be dropped.  After that point, incompatible
changes will only be made for critical reasons.

The reason for separate distribution of cluster-specific HPCD
packages are fairly obvious:

=over 4

=item -

The maintainers of the HPCI package do not have access to every
possible cluster type, and it unlikely that anyone will have access
to all supported cluster types from one location, so the driver
modules will need to be tested separately anyhow.

=item -

A user of HPCI is equally not going to have need to access every
type of cluster that exists, so they will probably prefer to only
download the driver modules that they actually need.

=back

=head1 SEE ALSO

=over 4

=item HPCI::Group

Describes the interface common to all B<HPCI Group>
objects, regardless of the particular type of cluster that
is actually being used to run the stages.  In the future, the
common interface may change somewhat as supprt for additional
cluster types is added and a better understanding of the common
features is achieved.

=item HPCI::Stage

Describes the interface common to stage object returned
by all B<HPCI Stage> objects, regardless of the
particular type of cluster that is actually being used to
run the stages.  The common interface may change somewhat
as supprt for additional cluster types is added and a better
understanding of the common features is achieved.

=item HPCI::Logger

Describes the logger parameters in more detail.

=item HPCI::Env

Describes the environment passing parameters in more detail.

=item HPCD::I<$cluster>::Group

Describes the group interface unique to a specific type of cluster,
including any limitations or extensions to the generic interface.

=item HPCD::I<$cluster>::Stage

Describes the stage interface unique to a specific type of cluster,
including any limitations or extensions to the generic interface.

=back

=head1 AUTHOR

Christopher Lalansingh - Boutros Lab

John Macdonald         - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

