package Grid::Request;

=head1 NAME

Grid::Request - An API for submitting jobs to a computational grid such as SGE or Condor.

=head1 DESCRIPTION

An API for submitting work to a Distributed Resource Management (DRM) system
such as Sun Grid Engine (SGE) or Condor.

=head1 SYNOPSIS

 use Grid::Request;
 my $request = Grid::Request->new( project => "SomeProject" );

 $request->times(2);
 $request->command("/path/to/executable");
 $request->initialdir("/path/to/initial/directory");
 $request->error("/path/to/dir/stderr.err");

 # Note, most of the methods in this module may also be called
 # with get_ and set_ prefixes. For example, the above code would
 # also have worked if coded like so:

 $request->set_times(2);
 $request->set_command("/path/to/executable");
 $request->set_initialdir("/path/to/initial/directory");
 $request->set_error("/path/to/dir/stderr.err");

 # When retrieving information (accessor behavior), you can call
 # such methods with no arguments to return the information, or
 # the "get_" may be prepended. For example:

 my $times = $request->times();
 my $times_another_way = $request->get_times();
 # Please note that calling the get version of a method and
 # providing arguments does not make sense and will likely, not work...

 # WRONG
 my $times_wrong_way = $request->get_times(3);

 # Finally, submit the request...
 my @id = $request->submit();
 print "The first ID for this request is $id[0].\n";

 # ...and wait for the results. This step is not necessary, only
 # if you wish to block, or wait for the request to complete before
 # moving on to other tasks.
 $request->wait_for_request();

 # Or, you could simply submit and block:
 $request->submit_and_wait();

 exit;

=head1 CONSTRUCTOR AND INITIALIZATION

Grid::Request->new(%args);

B<Description:> This is the object constructor. Parameters are passed to
the constructor in the form of a hash. Examples:

  my $req = Grid::Request->new( project => "SomeProject" );

  or

  my $req = Grid::Request->new( project    => "SomeProject",
                                opsys      => "Linux",
                                initialdir => "/path/to/initialdir",
                                output     => "/path/to/output",
                                times      => 5,
                              );
Users may also add a "debug" flag to the constructor call for increased
reporting:

  my $req = Grid::Request->new( project => "SomeProject",
                                debug   => 1 );

B<Parameters:> Only the 'project' parameter is mandatory when calling the
constructor.

B<Returns:> $obj, a Grid::Request object.

=head1 CONFIGURATION

By default, the configuration file that is used to determine what grid engine
type to use and where to store temporary files is located in the invoking
user's home directory under ~/.grid_request.conf. The file needs needs to have
a [request] header and entries for the 'tempdir' and 'drm' parameters.  In addition,
the file may also specify the path to a Log::Log4perl configuration file with the
'log4perl-conf' entry name.The following is an example:

      [request]
      drm=SGE
      tempdir=/path/to/grid/accessible/tmp/directory
      log4perl-conf=/path/to/custom-log4perl.conf

The 'tempdir' directory must point to a directory that is accessible
to the grid execution machines, for instance, over NFS...
Users may provide an alternate path to a different configuration file
by specifying the 'config' parameter to the constructor:

  my $req = Grid::Request->new( project => "SomeProject",
                                config => "/some/other/dir/request.conf",
                              );
Another way of specifying an alternate configuration is to define
the GRID_CONFIG environment variable.

=head1 CLASS AND OBJECT METHODS

=over 4

=cut


use strict;
use Config::IniFiles;
use Carp;
use Log::Log4perl qw(get_logger);
use POSIX qw(ceil);
use Schedule::DRMAAc qw(:all);
use Grid::Request::HTC;
use Grid::Request::Command;
use Grid::Request::Exceptions;

use vars qw($AUTOLOAD);
# These will be holders for the various method names so we can identify
# what class to route the calls to.
my %comm_meths;

# These are package variables.
my ($debug, $default_config, $logger);
$default_config = Grid::Request::HTC->config();
# The [section] heading in the configuration file.
my $section = $Grid::Request::HTC::config_section;

my $WORKER = $Grid::Request::HTC::WORKER;

my $command_element = 0;
my $DRMAA_INITIALIZED = 0;
our $VERSION = qw$Revision: 8365 $[1];
my $SESSION_NAME = lc(__PACKAGE__);
$SESSION_NAME =~ s/:+/_/g;

# Avoid ugly warnings about single usage.
if ($^W) {
    $VERSION = $VERSION;
}

BEGIN: {
    require 5.006_00; # Make sure we're not running some old Perl.

    # Here we set up which methods go where.
    my @command_meths = qw(account add_param block_size class cmd_type command
                           email end_time getenv project error hosts initialdir
                           input length memory name opsys output
                           priority start_time state times runtime evictable
                           max_time pass_through params
                          );

    # Create the hash lookups for the methods so we know how to route later.
    %comm_meths = map { $_ => 1 } @command_meths;
}


# The constructor.
sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class || ref($class);

    my $mapper = sub {
        my @meths = @_;
        my %hash;
        foreach my $meth (@meths) {
            if ( exists($args{$meth}) && defined($args{$meth}) ) {
                $hash{$meth} = $args{$meth};
            }
        }
        return \%hash;
    };

    # Here we separate our arguments to route them to the right class.
    my $command_args = $mapper->( sort keys %comm_meths );

    # $config will hold the location of the configuration file for the
    # module, which holds the logger configuration, etc...
    # The user may specify it with a "config" parameter in the
    # constructor.
    my $config = $args{config} || $default_config;
    $debug = $args{debug} || 0;
    
    $self->_init($command_args, $config);
    return $self;
}

# Initialize the object. This is a private method. Do not call directly.
sub _init {
    # Initialize the Request object. We need to parse the configuration
    # file, initialize the logger, create the Command object.
    my ($self, $command_args_ref, $config, @remaining) = @_;
    die "Initialization failed. Too many arguments, stopped" if @remaining;

    # Parse the default config file. Then, check if the user specified their
    # own, and if so, parse that and import the values from the default
    # config. The default config has information about where to create
    # temporary files and other information that user configuration files do
    # not need (or should) know about.

    my $cfg = _init_config_logger($config);

    $logger->info("Creating the first Command object.");
    # holds an array of command elements.
    $self->{_cmd_ele}->[$command_element] =
        Grid::Request::Command->new(%$command_args_ref);

    $self->{_drm} = _load_drm($cfg);
    $self->{_simulate} = 0;   # For simulate.
    $self->{_submitted} = 0;  # For the submitted flag.
    $self->{_config} = $cfg;  # For the configuration object.
    $self->{_env} = [];       # To hold the environment.
    $self->{_session} = "";
    _init_drmaa();
}

# Private method only. Used to configure logging.
sub _init_config_logger {
    my $config = shift;
    # TODO: Since Grid::Request::HTC already parsed the default config file, use
    # an accessor to get that config object rather than reparsing it
    # here. This will involve adding an additional method in Grid::Request::HTC.
    my $default_cfg_obj = Config::IniFiles->new( -file => $default_config );
    my ($cfg, $same_configs);
    if (defined $config && ($config eq $default_config)) {
        $same_configs = 1;
        $cfg = $default_cfg_obj;
    } else {
        $cfg = Config::IniFiles->new(-file   => $config,
                                     -import => $default_cfg_obj);
    }

    # Parse the location of the logger configuration and initialize
    # Log4perl, if it has not already been initialized.
    my $logger_conf = $cfg->val($section, "log4perl-conf");
    if (defined $logger_conf) {
        if (-f $logger_conf && -r $logger_conf) {
            Log::Log4perl->init_once($logger_conf);
        } else {
            warn "Unable to configure logging with $logger_conf.\n";
        }
    }

    $logger = get_logger(__PACKAGE__);

    return $cfg;
}

# Accessors (private) used to return internal objects.
sub _drm { return $_[0]->{_drm}; }
sub _com_obj_list { return $_[0]->{_cmd_ele}; }
sub _com_obj { return $_[0]->{_cmd_ele}->[$command_element]; }
sub _config { return $_[0]->{_config}; }

sub _load_drm {
    $logger->debug("In _load_drm.");
    my $cfg = shift;
    my $param = $Grid::Request::HTC::drm_param;
    my $drm = uc($cfg->val($section, $param));
    if (! defined $drm) {
        Grid::Request::Exception->throw("No $param parameter specified in the config file " . $cfg->GetFileName());
    }
    my $package = __PACKAGE__ . "::DRM::$drm";
    my $load_result = eval "require $package";

    if (defined($load_result) && ($load_result == 1) ) {
        import $package;
        $logger->info(qq|Loaded and imported "$package".|);
    } else {
        my $msg = qq|Could not load "$package".|;
        $logger->fatal($msg);
        Grid::Request::Exception->throw($msg);
    }
    my $drm_obj;
    eval {
        $drm_obj = $package->new();
    };
    if ($@ or ! defined $drm_obj) {
        Grid::Request::Exception->throw(qq|Could not instantiate "$package".|);
    }
    $logger->info("Returning a " . ref($drm_obj) . " object.");
    return $drm_obj;
}

# A private method for internal use only.
sub _get_env_list {
    $logger->debug("In get_env_list");
    my $self = shift;
    # If the environment hasn't yet been determined, determine it and
    # store it in element 6 (number 5).
    if (scalar(@{ $self->{_env} }) == 0) {
	my @temp_env;
	foreach my $key (keys %ENV) {
	    my $value = $ENV{$key};
	    if((index($key, ";") == -1) && (index($value, ";") == -1)) {
		push (@temp_env, "$key=$value");
	    }
	}
	$self->{_env} = \@temp_env;
    }

    # Return either the list or the reference depending on the context.
    return wantarray ? @{ $self->{_env} } : $self->{_env};
}

# This is invoked before submit and submit_and_wait
sub _validate {
    my $self = shift;
    $logger->debug("In _validate.");
    my $rv = 1;
    if ($self->project() =~ m/\s/) {
        Grid::Request::Exception->throw("White space is not allowed for the project attribute.");
    }

    if ($self->account() =~ m/\s/) {
        Grid::Request::Exception->throw("White space is not allowed for the account attribute.");
    }

    $logger->debug("Returning $rv.");
    return $rv;
}



# This method knows how to dispatch method invocations to the proper module
# or class by checking the name against the hashes set up early in this
# module. The hashes are used to look up which methods go where.
sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method = (split(/::/, $AUTOLOAD))[-1];
    my $set = 0;
    if (($method =~ m/^set_/) || (@args && $method !~ m/^get_/)) {
        $set = 1;
    }
    $method =~ s/^(s|g)et_//;

    if ( $comm_meths{$method} ) {
        $logger->debug("Received a Command method: $method.");
	if ($set) {
	    if (! $self->is_submitted()) {
                $self->_com_obj->$method(@args);
	    } else {
		$logger->logcroak("Cannot change a Command object after submission.");
	    }
	} else {
	    $self->_com_obj->$method;
	}
    } else {
        $logger->logcroak("No such method: $AUTOLOAD.");
    }
}


# We need a DESTROY method because we are using AUTOLOAD. Otherwise,
# the autoload mechanism will fail because it cannot find a DESTROY
# method. Don't modify or remove unless you know what you are doing.
# This is a private method that is not to be invoked directly.
sub DESTROY { 
    # Close the DRMAA Session
    $logger->debug("Closing the DRMAA session.");
    my ($error, $diagnosis) = drmaa_exit();
    if ($error) {
        $logger->error("Error closing the DRMAA session: ",
                 drmaa_strerror($error), $diagnosis);
    } else {
        $DRMAA_INITIALIZED = 0;
    }
}


=item $obj->account([account]);

B<Description:> The account attribute is used to affiliate a grid job with
a particular account. Grid engines differ in their treatment of the account
attribute.

B<Parameters:> To use as a setter, the first parameter will be used to
set (or reset) the account attribute for the command.

B<Returns:> The currently set account (if called with no parameters).


=item $obj->add_param($scalar | @list | %hash );

B<Description:> Add a command line argument to the executable when it is
executed on the grid. Since many executables associate meaning with the order
that command line arguments are given, Grid::Request also honors the
order in which parameters are added. They are reassembled at runtime on the grid in
the same order that they were added...

B<Parameters:> If the number of arguments is 1, then it will be considered to
be a simple, "anonymous" parameter and ...  When called with a single scalar
argument, no logic is attempted to interpret the string provided. The module
simply adds the specified string verbatim to the list of parameters when
building the command line to invoke on the grid.  If 3 parameters are passed,
then they are read as "key", "value", "type". The parameter 'type' can be
either "ARRAY", "DIR", "PARAM", or "FILE" (the default is "PARAM").

The 'type' is used in the following way to aid in the parallelization of
processes: If ARRAY is used, the job will be iterated over the elements of the
array, with the value of the parameter being changed to the next element of the
array each time. The array must be an array of simple strings passed in as an
array reference to 'value'. Newlines will be stripped.  Note: Nested data
structures will not be respected.

If "DIR" is specified as the 'type', the file contents of the directory
specified by the 'value' will be iterated over.  If the directory contains 25
files, then there will be at least 25 invocations of the executable on the grid
( one per file) with the name of each file substituted for the '$(Name)' token
each time. Note that hidden files and directories are not counted and the
directory is NOT scanned recursively.

If "FILE" is specified, then the 'value' specified in the method call
will be interpreted as the path to a file containing entries to iterate over.
The file may contain hundreds of entries (1 per line) to generate a
corresponding number of jobs.

If greater clarity and flexibility is desired, one may wish to pass named
parameters in a hash reference instead:

  $obj->add_param( { key   => '--someparam=$(Name)',
                     value => "/path/to/directory",
                     type  => "DIR",
                   });

The 3 supported keys are case insensitive, so "KEY", "Value" and "tYpE" are
also valid. Unrecognized keys will generate warnings.

If more then 3 arguments are passed to the method an error occurs.

For each parameter that is added, the 'key' is what dictates how the parameter
should be processed as a command line argument and how the values from the
iterable directory, array or file are to be dropped into the final command line
invocation.  Parameter keys can make use of two tokens: $(Index) and $(Name).
The $(Index) token is replaced at runtime with the actual sequence number of
the job on the grid. The '$(Name)' token is replaced with the string taken from
the iterable file, directory or array. In the case of parameters of type

    FILE  -> $(Name) is repeatedly replaced with each line in the file
    DIR   -> $(Name) is repeatedly replaced with the name of each file in the directory 
    ARRAY -> $(Name) is repeatedly replaced with each scalar value of the element of the array

Examples: 

   FILE
      $request->add_param({ type  => "FILE",
                            key   => '--string=$(Name)',
                            value => "/path/to/some/file.txt",
                         });

   DIR
      $request->add_param({ type   => "DIR",
                            key    => '--filepath=$(Name)',
                            value  => "/path/to/some/directory",
                         });
   ARRAY
      $request->add_param({ type   => "ARRAY",
                            key    => '--element=$(Name)',
                            value  => \@array,
                         });

B<Returns:> None.

=cut

sub add_param {
    $logger->debug("In add_param.");
    my ($self, @args) = @_;

    # This is just a function to set the temporary directory on the
    # command object. It's necessary when the user calls add_param with
    # a type of "ARRAY". The temp dir is the location where a file is
    # created that contains each element of the array.
    my $tempdir_setter = sub {
        $logger->debug("Getting the configuration object.");
        my $cfg = $self->_config();
        $logger->debug("Setting the temporary directory ",
                       "on the command object.");
        my $tempdir = $cfg->val($Grid::Request::HTC::config_section, "tempdir");
        if (defined $tempdir) {
            $self->_com_obj->tempdir($tempdir);
        } else {
            Grid::Request::Exception->throw("tempdir has not been configured in " . $cfg->GetFileName());
        }
    };

    if ( (@args == 1) && (ref($args[0]) eq "HASH") ) {
        foreach my $key ( keys %{ $args[0] } ) {
            if ( (uc($key) eq "TYPE") && (uc($args[0]->{type}) eq "ARRAY") ) {
                $tempdir_setter->();
            }
        }
    } elsif ( (@args == 3) && ($args[2] eq "ARRAY") ) {
        $tempdir_setter->();
    }
    my $return = $self->_com_obj->add_param(@args);
    return $return;
}

=item $obj->block_size( [ $scalar | $code_ref ] );

B<Description:> By default, Master/Worker (mw) jobs have a default block size
of 100.  That is to say, that each worker on the grid will process 100 elements
of the overall pool of job invocations. However, this isn't always appropriate.
The user may override the default block size by calling this method and setting
the block size to an alternate value (a positive integer). The user may also
provide an anonoymous subroutine (code reference) so that the block size can be
computed dynamically. If choosing to pass a subroutine , the code reference
will be passed two arguments: the Grid::Request::Command object that will be
invoked, and the number of elements that will be iterated over, in that order.
The subroutine can then use these pieces of information to compute the block
size. The subroutine MUST return a positive integer scalar or an exception will
be thrown.

    Examples:
        # simple scalar block size
        $request->block_size(1000);

        # Passing a code ref, to make the block size dependent on the
        # executable...
        $request->block_size(
                      sub {
                          my $com_obj = shift;
                          my $count = shift;

                          my $exe = $com_obj->command();

                          my $block_size = 50;
                          if ($exe =~ m/sort/i) {
                              $block_size = ($count > 100000) ? 10000 : 1000;
                          }
                          return $block_size;
                      }
                  );

B<Parameters:> A positive integer scalar, or an anonymous subroutine/code
reference.

B<Returns:> The block size scalar or code reference if called as an accessor
(no-arguments). If the block size has not been explicitly set, then the default
block size is returned. No return if called as a mutator.

=item $obj->class([$class]);

B<Description:> This method is used to set and retrieve the request's class
attribute. A request's class describes its general purpose or what it will
be used for. For example, a command can be marked as a request for "engineering"
or "marketing". Ad hoc requests will generally not use a class setting. If in
doubt, leave the class attribute unset.

B<Parameters:> With no parameters, this method functions as a getter. With one
parameter, the method sets the request's class. No validation is
performed on the class passed in.

B<Returns:> The currently set class (when called with no arguments).


=item $obj->command([$command]);

B<Description:> This method is used to set or retrieve the executable that
will be called for the request.

B<Parameters:> With no parameters, this method functions as a getter. With one
parameter, the method sets the executable. Currently, this module does not
attempt to verify whether the exeutable is actually present or whether
permissions on the executable allow it to be invoked by the user on grid
machines.

B<Returns:> The currently set executable (when called with no arguments).


=item $obj->email([$email_address]);

B<Description:> This method is used to set or retrieve the email of the user
submitting the request. The email is important for notifications and for
tracking purposes in case something goes wrong.

B<Parameters:> With no parameters, this method functions as a getter and
returns the currently configured email address. If the request has not yet been
submitted, the user may set or reset the email address by providing an
argument. The address is not currently validated for RFC compliance.

B<Returns:> The email address currently set, or undef if unset (when called
with no arguments).


=item $obj->end_time()

B<Description:> Retrieve the finish time of the request.

B<Parameters:> None.

B<Returns:> The ending time of the request (the time the grid finished
processing the request), or undef if the ending time has not yet been
determined.


=item $obj->error([errorfile])

B<Description:> This method allows the user to set, or if the request has not
yet been submitted, to reset the error file. The error file will be the place
where all STDERR from the invocation of the executable will be written to. This
file should be in a globally accessible location on the filesystem such that
grid execution machines may create the files. The attribute may not be changed
with this method once the request has been submitted.

B<Parameters:> To set the error file, call this method with one parameter,
which should be the path to the file where STDERR is to be written.  Note that
when submitting array jobs (with the use of the times() method or with
Master/Worker parameters through add_param()), one can also use the $(Index)
token when specifying the error path. The token will be replaced with the
grid's task ID number. For example, if a request generated 100 grid jobs, then
an error path containing '/path/to/directory/job_$(Index).err' will result in
STDERR files numbered job_1.err, job_2.err, ..., job_100.err in
/path/to/directory.

B<Returns:> When called with no arguments, this method returns the currently
set error file, or undef if not yet set.


=item $obj->getenv([1]);

B<Description:> The getenv method is used to set whether the user's environment
should be replicated to the grid or not. To replicate your environment, call
this method with an argument that evaluates to true. Calling it with a 0
argument, or an expression that evaluates to false, will turn off environment
replication. The default is NOT to replicate the user environment across the
grid.

B<Parameters:> This method behaves as a getter when called with no arguments.
If called with 1, or more arguments, the first will be used to set the
attribute to either 1 or 0.

B<Returns:> The current setting for getenv (if called with no arguments).


=item $obj->ids();

B<Description:> This method functions only as a getter, but returns
the DRM ids associated with the overall request after it has been
submitted.

B<Parameters:> None.

B<Returns:> Returns an array in list context. In scalar context, returns a
reference to an array.

=cut

sub ids {
    $logger->debug("In id");
    my ($self, @args) = @_;
    if (@args) {
        my $msg = "The ids method takes only one argument " .
                  "when making an assignment.";
        $logger->logwarn($msg);
    }
    my $total = $self->command_count();
    my @ids;
    my $count = 1;
    for (my $cmd=0;$cmd<$total;$cmd++) {
        $logger->debug("Getting ids from command $count/$total.");
        my $cmd_obj = $self->_com_obj_list->[$cmd];
        my @sub_ids = $cmd_obj->ids();
        push @ids, @sub_ids;
        $count++;
    }
    return wantarray ? @ids : \@ids;
}


=item $obj->is_submitted();

B<Description:> Returns whether a request object has been submitted.

B<Parameters:> None.

B<Returns:> 1 if the request has been submitted and 0 if it has not.

=cut

sub is_submitted {
    my ($self, $submitted) = @_;
    if (defined($submitted)) {
        $self->{_submitted} = ($submitted) ? 1 : 0;
    } else {
        return $self->{_submitted};
    }
}
=item $obj->project([$project]);

B<Description:> The project attribute is used to affiliate usage of the DRM with
a particular administrative project. This will allow for more effective
control and allocation of resources, especially when high priority projects
must be fulfilled. Therefore, the "project" is mandatory when the request object
is built. However, the user may still change the project attribute as long as
the job has not yet been submitted (after submission most attributes are
locked).

B<Parameters:> The first parameter will be used to set (or reset)
the project attribute for the request, as long as the request has not
been submitted.

B<Returns:> The currently set project (if called with no arguments).


=item $obj->input([path]);

B<Description:> Used to specify a file to be used as the STDIN for
the executable on the grid.

B<Parameters:> A scalar containing the globally accessible path to
the file to use for STDIN.

B<Returns:> The currently set input file if called as a getter with no
arguments, or undef if not yet set.


=item $obj->initialdir([path]);

B<Description:> This method sets the directory where the grid will be
chdir'd to before invoking the executable. This is an optional parameter,
and if the user leaves it unspecified, the default will be that the grid
job will be chdir'd to the root directory "/" before beginning the request.
Use of initialdir is encouraged to promote the use of relative paths.

B<Parameters:> A scalar holding the path to the directory the grid should
chdir to before invoking the executable.

B<Returns:> When called with no arguments, returns the currently set
initialdir, or undef if not yet set.


=item $obj->length([length]);

B<Description:> This method is used to characterize how long the request
is expected to take to complete. For long running requests, an attempt to
match appropriate resources is made. If unsure, leave this setting unset.

B<Parameters:> "short", "medium", "long". No attempt is made to validate
the length passed in when used as a setter.

B<Returns:> The currently set length attribute (when called with no
arguments).

=item $obj->name([name]);

B<Description:> The name attribute for request objects is optional and is
provided as a convenience to users to name their requests.

B<Parameters:> A scalar name for the request.

B<Returns:> When called with no arguments, returns the current name, or
undef if not yet set. The name cannot be changed once a request is submitted.


=item $obj->new_command();

B<Description:> The module allows for requests to encapsulate multiple
commands. This method will start work on a a new one by moving a cursor.
Commands are processed in the order in which they are created if they are
submitted synchronously, or in parallel if submitted asynchronously (the
default). In addition, the only attribute that the new command inherits from
the command that preceded it, is the project. However, users are free to change
the project by calling the project() method...

B<Parameters:> None.

B<Returns:> None.

=item $obj->opsys([$os]);

B<Description:> The default operating system that the request will be processed
on is Linux. Users can choose to submit requests to other operating systems by
using this method. Available operating systems are "Linux", "Solaris".  An
attempt to set the opsys attribute to anything else results in an error. Values
must be comma separated, so if you would loke your command to run on Linux or
Solaris:

 $obj->opsys("Linux,Solaris");

and for Linux only:

 $obj->opsys("Linux"):

B<Parameters:> "Linux", "Solaris", etc, when called as a setter
(with one argument).

B<Returns:> When called with no arguments, returns the operating system the
request will run on, which defaults to "Linux".

=item $obj->hosts([hostname]);

B<Description:> Used to set a set the list of possible machines to run the
jobs on. If this value is not set then any host that matches the other
requirements will be used according to the grid engine in use.
Hostnames are passed in in comma-separated form with no spaces.

B<Parameters:> hostname(s), example "machine1,machine2"

B<Returns:> When called with no arguments, returns the hosts if set.


=item $obj->memory([megabytes]);

B<Description:> Used to set the minimum amount of physical memory needed.

B<Parameters:> memory in megabytes. Examples: 1000MB, 5000MB

B<Returns:> When called with no arguments, returns the memory if set.


=item $obj->pass_through([pass_value]);

B<Description:> Used to pass strings to the underlying DRM (Distributed
Resource Mangement) system (Condor, SGE, LSF, etc...) as part of the
request's requirements. Such pass throughs are forwarded unchanged. This is an
advanced option and should only be used by those familiar with the the
underlying DRM.

B<Parameters:> $string, a scalar.

B<Returns:> None.

=cut

sub new_command {
    $logger->debug("In new_command.");
    my $self = shift;

    # The only piece of information replicated from command to command is the
    # project. So we first get the project and then use it to build the new
    # Command object.
    my $project = $self->project();

    # Increment element pointer.
    $command_element++;
    $logger->debug("Creating Command object in element $command_element.");
    $self->_com_obj_list->[$command_element] =
        Grid::Request::Command->new( project => $project );
}

=item $obj->output([path]);

B<Description:> Sets the path for the output file, which would hold all of
the output directed to STDOUT by the request on the grid. This method functions
as a setter and getter.

B<Parameters:> A path to a file. The file must be globally accessible on the
filesystem in order to work, otherwise, the location will not be accessible to
compute nodes on the grid. This attribute may not be changed once a request is
submitted. Note that when submitting array jobs (with the use of the times()
method or with Master/Worker parameters through add_param()), one can also use
the $(Index) token when specifying the output path. The token will be replaced
with the grid's task ID number. For example, if a request generated 100 grid
jobs, then an output path containing '/path/to/directory/job_$(Index).out' will
result in STDOUT files numbered job_1.out, job_2.out, ..., job_100.out in
/path/to/directory.

B<Returns:> When called with no arguments, the method returns the currently
set path for the output file, or undef if not yet set.


=item $obj->params();

B<Description:> Retrieve the list of currently registered parameters for the
request.

B<Parameters:> None.

B<Returns:> The method returns a list of hash references.


=item $obj->priority([priority]);

B<Description:> Use this method to set the optional priority attribute on the
request. The priority setting is used to help allocate the appropriate
resources to the request. Higher priority requests may displace lower priority
requests.

B<Parameters:> Scalar priority value.

B<Returns:> The current priority, or undef if unset.

=cut

=item $obj->set_env_list(@vars);

B<Description:> This method is used to establish the environment that a a
request to the grid should run under. Users may pass this method a list of
strings that are in "key=value" format. The keys will be converted into
environment variables set to "value" before execution of the command is begun.
Normally, a request will not copy the user's environment in this way.  The only
time the environment is established on the grid will be if the user invokes the
getenv method or sets it with this method. This  method allows the user to
override the environment with his or her own notion of what the environment
should be at runtime on the grid.

B<Parameters:> A list of strings in "key=value" format. If any string does
not contain the equals (=) sign, it is skipped and a warning is generated. 

B<Returns:> None.

=cut

sub set_env_list {
    my ($self, @args) = @_;
    my @valid; 
    foreach my $arg (@args) {
        if ($arg !~ /\S+=\S+/) {
            $logger->logcroak("$arg is not a valid environment parameter. Skipping it.");
            next;
        }
        push(@valid, $arg);
    }

    $self->[5] = \@valid;

    # If the user has set their own environment with set_envlist, then we
    # assume that they want getenv to be true. We do it for them here to save
    # them an extra step.
    $self->getenv(1);
}


=item $obj->simulate([value]);

B<Description:> This method is used to toggle the simulate flag for the
request. If this method is passed a true value, the request will not be
submitted to the grid, but will appear to have been submitted. This is most
useful in development and testing environments to conserve resources. When a
request marked simulate is submitted, the request ID returned will be -1. Note
that this attribute cannot be modified once a request is submitted.

B<Parameters:> A true value (such as 1) to mark the request as a simulation.
A false value, or express (such as 0) to mark the request for execution.

B<Returns:> When called with no arguments, this method returns the current
values of the simulate toggle. 1 for simulation, 0 for execution. 

=cut

sub simulate {
    $logger->debug("In simulate.");
    my ($self, $simulate, @args) = @_;
    if (defined $simulate) {
        $self->{_simulate} = ($simulate) ? 1 : 0;
    } else {
        return $self->{_simulate};
    }
}


=item $obj->start_time();

B<Description:> Retrieve the start time when the request began processing.
Any attempt to set the time will result in an error.

B<Parameters:> None.

B<Returns:> $time, the start time (scalar) that the grid began processing
the request.


=item $obj->state();

B<Description:> Retrieve the "state" attribute of the request. This method
is "read only" and an attempt to set the state will result in an error.
The states are:

    INIT
    INTERRUPTED
    FAILURE
    FINISHED
    RUNNING
    SUSPENDED
    UNKNOWN
    WAITING

B<Parameters:> None.

B<Returns:> $state, a scalar with the current state of the request.


=item $obj->stop([$id]);

B<Description:> Stop a request that has already been submitted.

B<Parameters:> Request ID (optional)

B<Returns:> None.

=cut

sub stop {
    $logger->debug("In stop.");
    my ($self, $stop_id, @args) = @_;

    if (! defined $stop_id) {
	if (! $self->is_submitted()) {
	    $logger->warn("Stop was called but the request was not submitted. Do nothing...");
	    return;
	} else {
	    $logger->debug("Stop called for self.");
	    $stop_id = $self->get_id();
            # TODO Stop all jobs associated with this Request.
	}
    } else {
	$logger->warn("The stop method takes only one argument.") if @args;
        #TODO: Stop a particular ID
    }
}


=item $obj->submit_serially();

B<Description:> Calling this method is the equivalent of calling
submit with the serial flag set to a true value, eg. $obj->submit(1).

B<Parameters:> None.

B<Returns:> The array of grid ids in list context, or an array reference
in scalar context.

=cut

sub submit_serially {
    $logger->debug("In submit_serially.");
    my $self = shift;
    if ($self->is_submitted()) {
        Grid::Request::Exception->throw("This request has already been submitted.");
    }
    my @ids = $self->submit(1);
    return wantarray ? @ids : \@ids;
}

=item $obj->submit([$serial]);

B<Description:> Submit the request to the grid for execution.

B<Parameters:> An optional parameter, which if true, will cause
the commands to be executed serially. The default is for asynchronous
execution

B<Returns:> The array of DRM ids in list context, or an array reference
in scalar context.

=cut

sub submit {
    $logger->debug("In submit.");
    my ($self, $serially, @args) = @_;
    my @ids = ();
    if ($self->is_submitted()) {
        Grid::Request::Exception->throw("This request has already been submitted.");
    }
    $serially = (defined $serially) ? $serially : 0;
    if ($self->_validate()) {
        $logger->info("Validation process succeeded.");
        if ($self->simulate()) {
            $logger->debug("Simulation is turned on, so do not really submit.");
        } else {
            @ids = $self->_drmaa_submit($serially);
        }
        # Set the submitted flag, so we can't submit multiple times.
        $logger->debug("Setting the submitted flag.");
        $self->is_submitted(1);
    } else {
        my $msg = "Validation failed.";
        $logger->error($msg);
        Grid::Request::Exception->throw($msg);
    }

    $logger->debug("Returning from submit.");
    return wantarray ? @ids : \@ids;
}


# A private method for internal use only. Throws a DRMAA
# related exception.
sub _throw_drmaa {
    my ($msg, $error, $diagnosis) = @_;
    $logger->error($msg);
    $logger->error("Diagnosis: $diagnosis");
    Grid::Request::DRMAAException->throw(
                           error => $msg,
                           drmaa => drmaa_strerror($error),
                           diagnosis => $diagnosis
                          );
}

# This is a private method for internal use only. It initializes a DRMAA
# session. It also logs some very basic information about the DRMAA
# implementation.
sub _init_drmaa {
    $logger->debug("In _init_drmaa.");
    if ($DRMAA_INITIALIZED) {
        $logger->debug("DRMAA session aready initialized.");
    } else {
        my ($error, $diagnosis) = drmaa_init("session=$SESSION_NAME");
        _throw_drmaa("Could not initialize DRMAA", $error, $diagnosis) if $error;
        $DRMAA_INITIALIZED = 1;

        my $contact;
        ($error, $contact, $diagnosis) = drmaa_get_contact();

        # Log the DRMAA version if we are in debug logging mode.
        if ($logger->is_debug()) {
            my ($major, $minor);
            ($error, $major, $minor, $diagnosis) = drmaa_version();
            if ($error) {
                $logger->warn("Unable to get the DRMAA Version: " . drmaa_strerror($error));
            } else {
                $logger->debug("DRMAA Version: ${major}.${minor}.");
            }
        }
    }
}


# Default is serial execution. This is a private method for internal use only.
sub _drmaa_submit {
    $logger->debug("In _drmaa_submit.");
    my ($self, $serially) = @_;
    $serially = (defined $serially) ? $serially : 0;
    if ($serially) {
        $logger->debug("Submissions will occur serially."); 
    } else {
        $logger->debug("Submissions will occur asynchronously."); 
    }

    my @ids;
    my $total = $self->command_count();
    my $count = 1;
    for (my $cmd = 0; $cmd < $total; $cmd++) {
        my $cmd_obj = $self->_com_obj_list->[$cmd];
        $logger->debug("Submitting command $count/$total.");
        my $jt = $self->_cmd_base_drmaa($cmd_obj);
        $logger->debug("Got a good job template.") if defined $jt;
        my @sub_ids;
        if ($cmd_obj->cmd_type() eq "mw") {
            @sub_ids = $self->_submit_mw($jt, $cmd_obj);
        } else {
            @sub_ids = $self->_submit_htc($jt, $cmd_obj);
        }
        if ($serially) {
            _sync_ids($cmd_obj);
        }
        push @ids, @sub_ids;
        $count++;
    }
    $logger->debug("Finished submitting.");
    return wantarray ? @ids : \@ids;
}

# Private method for internal use only. Used to conigure DRMAA settings
# that are common to all jobs, regardless of whether they are Master-Worker (mw)
# or simple jobs (htc).
sub _cmd_base_drmaa {
    $logger->debug("In _cmd_base_drmaa.");
    my ($self, $cmd) = @_;

    my ($error, $jt, $diagnosis) = drmaa_allocate_job_template();
    _throw_drmaa("Could not allocate job template", $error, $diagnosis) if $error;

    my $input = $cmd->input();
    if (defined $input) {
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_INPUT_PATH, ':' . $input);
        _throw_drmaa("Could not set input path.", $error, $diagnosis) if $error;
    }

    # To prevent users from getting an accumulation of job_name.e* and job_name.o* files
    # in their working directories (most likely their home directories), we set the error
    # and output paths to /dev/null unless they were specified...
    my $output = $cmd->output();
    my $error_path = $cmd->error();
    if (defined($output) || defined($error_path)) {
        $output =~ s/\$\(Index\)/\$drmaa_incr_ph\$/g;
        $error_path =~ s/\$\(Index\)/\$drmaa_incr_ph\$/g;

        $output ||= '/dev/null';
        $logger->debug("STDOUT will go to $output.");
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_OUTPUT_PATH, ':' . $output);
        _throw_drmaa("Could not set output path.", $error, $diagnosis) if $error;

        $error_path ||= '/dev/null';
        $logger->debug("STDERR will go to $error_path.");
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_ERROR_PATH, ':' . $error_path);
        _throw_drmaa("Could not set output path.", $error, $diagnosis) if $error;
    } else {
        $logger->info("Neither output nor error were defined. Setting both to go /dev/null.");
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_OUTPUT_PATH, ':/dev/null');
        _throw_drmaa("Could not set input path to /dev/null", $error, $diagnosis) if $error;
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_JOIN_FILES, 'y');
        _throw_drmaa("Could not tell DRM to join input and output files.", $error, $diagnosis) if $error;
    }
     
    my $initialdir = $cmd->initialdir();
    if (defined $initialdir) {
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_WD, $initialdir);
        _throw_drmaa("Could not set the job working directory.", $error, $diagnosis) if $error;
    }
    
    my $name = $cmd->name();
    if (defined $name) {
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_JOB_NAME, $name);
        _throw_drmaa("Could not set command name.", $error, $diagnosis) if $error;
    }

    # Replicate the environment, if the user asked for it
    if ($cmd->getenv()) {
        $logger->info("Setting environment attributes for the job.");
        my $env_ref = $self->_get_env_list();
        ($error, $diagnosis) = drmaa_set_vector_attribute($jt, $DRMAA_V_ENV, $env_ref);
        _throw_drmaa("Unable to set the job environment.", $error, $diagnosis) if $error;
    }

    # Set the notification email address, if configured
    my $email = $cmd->email();
    if ($email) {
        $logger->info("Setting DRM to not block emails.");
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_BLOCK_EMAIL, 0);
        _throw_drmaa("Unable to unblock emails.", $error, $diagnosis) if $error;
        $logger->info("Setting the job email.");
        ($error, $diagnosis) = drmaa_set_vector_attribute($jt, $DRMAA_V_EMAIL, [$email]);
        _throw_drmaa("Unable to set the job email.", $error, $diagnosis) if $error;
    }
 
    my @drm_methods = qw(account hosts opsys evictable priority memory
                         length project class runtime);
    my @native_attrs;
    foreach my $method (@drm_methods) {
        my $val = $cmd->$method;
        if (defined $val) {
            # Translate the user provided value to what the DRM understands by calling the
            # DRM plugin...
            my $attr = $self->_drm->$method($val);
            $logger->debug(qq|DRM plugin mapped "$val" to "$attr".|);
            push (@native_attrs, $attr) if defined $attr;
        } else {
            $logger->debug(qq|Nothing defined for "$method".|);
        }
    }
    # Apply the pass_through, if configured
    my $pass_through = $cmd->pass_through();
    if ($pass_through) {
        $logger->info("Adding job pass-through: $pass_through");
        push (@native_attrs, $pass_through);
    }

    if ( scalar(@native_attrs) > 0 ) {
        my $native = join(" ", @native_attrs);
        $logger->debug(qq|Setting native attribute "$native".|);
        ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_NATIVE_SPECIFICATION, $native);
        _throw_drmaa("Unable to set native specification.", $error, $diagnosis) if $error;
    }

    return $jt;
}


# Private method for internal use only. This method is used to submit
# mw (Master/Worker) jobs, which are jobs that iterate over files in a directory,
# lines in a file, or elements in an array, by calling grid_request_worker.
sub _submit_mw {
    $logger->debug("In _submit_mw.");
    my ($self, $jt, $cmd) = @_;
    unless (defined $jt && defined $cmd) {
        Grid::Request::InvalidArgumentException->("Job template and/or command object are not defined.");
    }

    $logger->debug("Setting the command executable.");
    my ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_REMOTE_COMMAND, $WORKER);
    _throw_drmaa("Could not set command executable.") if $error;

    # Calculate how many workers we need. First, calculate the number of iterations by
    # examining the mw arguments
    my $min_count;
    foreach my $param ($cmd->params()) {
        if ($param->type() ne "PARAM") {
            my $count = $param->count();
            if (! defined $min_count) {
                $min_count = $count;
            } else {
                if (($count > 0) && ($count < $min_count)) {
                    $min_count = $count;
                    $logger->debug("New minimum iteration count of $min_count.");
                }
            }
        }
    }

    # Approach for master/worker (mw) jobs:
    #
    # 1. For each parameter, create an argument that contains the argument type, and a 
    #    list of the values to iterate over
    # 2. Calculate the minimum number of iterations from the parameters. In other words,
    #    if there is a mismatch, then you have to take the lowest number of parameters
    #    so that all parameters have defined siblings.
    # 3. Based on the number of iterations N, launch a number of workers on the grid to
    #    process these where the number is some function of N, f(N).
    # 4. Pass the path of the exe to the worker program, so that it knows what to execute
    #    The worker will know what portion of the work to do by the task id that the DRM
    #    gives it. In SGE, this is done with an environment variable: SGE_TASK_ID.
    # 5. Worker will replace $(Index) and $(Name) placeholders with the iteration number or
    #    or the value itself in the output file, error file, input file, args, etc...
    #
    #  General form:
    #  /path/to/worker <executable> <iterations> <workers>  \
    #                    param:blah_blah_blah               \
    #                    dir:<directory>:blah_blah_blah     \
    #                    file:<file>:blah_blah_blah
    #
    # Example: /path/to/worker /path/to/user/command 1000 5 \
    #            dir:/path/to/user/directory:-d $(Name)     \
    #            file:/path/to/user/file:-arg $(Name)       \
    #            param:-plain_arg
    #
    # We use a helper utility and method to determine how to divide the work.
    # We don't just path the min_count, because maybe different types of jobs
    # should be split up differently. This is why we pass $cmd, so that more
    # intelligent analysis may be done if configured...
    
    my $block_size = $cmd->block_size();
    if (ref($block_size) eq "CODE") {
        $logger->debug("Detected a code reference for block size.");
        my $block_size_calculator = $block_size;
        $logger->debug("Invoking the code to determine the block size.");
        $block_size = $block_size_calculator->($cmd, $min_count); 


        if ($block_size =~ /^-?\d+$/) {                                                                          
            if ($block_size > 0) {                                                                              
                $logger->debug("Invocation yielded a block size of $block_size.");
            } else {
                Grid::Request::Exception->throw(                                                  
                    "Block size code reference yielded an invalid result. Must be a positive integer.");
            }
        } else {
            Grid::Request::Exception->throw(
                    "Block size code reference yielded an invalid result.");
        }
    } else {
        $logger->debug("block_size is a regular scalar: $block_size");
    }

    # Compute the number of workers to invoke based on the block size.
    my $workers = ceil($min_count / $block_size);

    my $plurality = ($workers == 1) ? "worker" : "workers";
    $logger->info("This master/worker command requires $workers $plurality.");

    my $exe = $cmd->command();
    my @params;
    my $number_of_tasks = $min_count;  # Just a variable rename for clarity

    push (@params, $exe, $block_size);

    my $delim = ':';
    foreach my $param ($cmd->params()) {
        my $arg_type;
        my $type = $param->type();
        if ($type eq "PARAM") {
            $logger->debug("Found a regular (non-MW) parameter.");
            push(@params, "param" . $delim . $param->value());
            next;
        } elsif ($type eq "DIR") {
            $arg_type = "dir";
        } elsif ($type eq "ARRAY") {
            $arg_type = "array";
        } elsif ($type eq "FILE") {
            $arg_type = "file";
        }
        my $value = $param->value();
        my $key = $param->key();
        my $arg = join($delim, ($arg_type, $value, $key));
        $logger->debug("Formulated MW worker argument: $arg");
        push(@params, $arg);
    }
    # Set these parameters
    ($error, $diagnosis) = drmaa_set_vector_attribute($jt, $DRMAA_V_ARGV, \@params);
    _throw_drmaa("Could not set command arguments.", $error, $diagnosis) if $error;


    # Get the job running...
    my @ids;
    if (defined($workers) && ($workers > 0)) {
        my $job_ids;
        ($error, $job_ids, $diagnosis) = drmaa_run_bulk_jobs($jt, 1, $workers, 1);
        _throw_drmaa("Could not run bulk jobs.", $error, $diagnosis) if $error;
        for (my $i=1; $i<=$workers; $i++) {
            my ($error, $job_id) = drmaa_get_next_job_id($job_ids);
            _throw_drmaa("Error getting next job id.", $error, $diagnosis) if $error;
            $logger->debug("Adding job id $job_id to the jobs array.");
            push (@ids, $job_id);
        }
    } else {
        Grid::Request::Exception->throw("MW job resulted in no workers to launch.");
    }
    # Set the job ids for the command
    $cmd->ids(@ids);
    
    # Delete the job template
    ($error, $diagnosis) = drmaa_delete_job_template($jt);
    _throw_drmaa("Error deleting the job template.", $error, $diagnosis) if $error;

    $logger->debug("Number of ids to return: " . scalar(@ids));
    return wantarray ? @ids : \@ids;
}

# Private method for internal use only. This method is used to submit
# non-mw (Master/Worker) jobs. In other words, jobs that do not iterate
# over anything by calling grid_request_worker.
sub _submit_htc {
    $logger->debug("In _submit_htc.");
    my ($self, $jt, $cmd) = @_;
    unless (defined $jt && defined $cmd) {
        Grid::Request::InvalidArgumentException->(
            "Job template and/or command object are not defined.");
    }

    my $exe = $cmd->command();
    unless (defined $exe) {
        Grid::Request::InvalidArgumentException->("Command executable is not defined.");
    }
    $logger->debug("Setting the command executable.");
    my ($error, $diagnosis) = drmaa_set_attribute($jt, $DRMAA_REMOTE_COMMAND, $exe);
    _throw_drmaa("Could not set command executable.") if $error;

    my @params = $cmd->params();
    my @args = ();
    $logger->debug("Parameters obtained from the command object: " . scalar(@params));
    foreach my $param (@params) {
        my $value = $param->value();
        my $key = $param->key();
        if (defined $key) {
            $logger->debug("Got parameter key: $key");
            push (@args, $key);
        }
        $logger->debug("Got parameter value: $value");
        push (@args, $value);
    }

    if (scalar(@args)) {
        $logger->debug("Setting " . scalar(@args) . " arguments to the executable.");
        ($error, $diagnosis) = drmaa_set_vector_attribute($jt, $DRMAA_V_ARGV, \@args);
        _throw_drmaa("Could not set command arguments.", $error, $diagnosis) if $error;
    } else {
        $logger->debug("No arguments to set for the command.");
    }

    # Get the job running...
    my $times = $cmd->times();
    my @ids;
    if (defined($times) && ($times > 1)) {
        my $job_ids;
        ($error, $job_ids, $diagnosis) = drmaa_run_bulk_jobs($jt, 1, $times, 1);
        _throw_drmaa("Could not run bulk jobs.", $error, $diagnosis) if $error;
        for (my $i=1; $i<=$times; $i++) {
            my ($error, $job_id) = drmaa_get_next_job_id($job_ids);
            _throw_drmaa("Problem getting next job id.", $error, $diagnosis) if $error;
            $logger->debug("Adding job id $job_id to the jobs array.");
            push (@ids, $job_id);
        }
    } else {
        # If here, this is a singleton type job. Only 1 execution...
        my $job_id;
        ($error, $job_id, $diagnosis) = drmaa_run_job($jt);
        _throw_drmaa("Error running job.", $error, $diagnosis) if $error;
        $logger->debug("Adding job id $job_id to the jobs array.");
        # since the return is for an array of ids, make an array containing
        # a single job id.
        @ids = ($job_id);
    }
    # Set the job ids for the command
    $cmd->ids(@ids);
    
    # Delete the job template
    ($error, $diagnosis) = drmaa_delete_job_template($jt);
    _throw_drmaa("Error deleting the job template.", $error, $diagnosis) if $error;

    $logger->debug("Number of ids to return: " . scalar(@ids));
    return wantarray ? @ids : \@ids;
}

=item $obj->submit_and_wait();

B<Description:> Submit the request for execution on the grid and wait for the
request to finish executing before returning control (block).

B<Parameters:> None.

B<Returns:> $id, the request's id.

=cut

sub submit_and_wait {
    $logger->debug("In submit_and_wait.");
    my ($self, @args) = @_;
    my $validate_result = $self->_validate();
    my @ids = ();
    if ($validate_result == 1) {
        $logger->info("Validation process succeeded.");
        if ($self->simulate()) {
            $logger->info("Simulation is turned on, so do not really submit.");
        } else {
            @ids = $self->submit();
            # The submit() method handles setting the submitted flag.
            $self->wait_for_request();
        }
    } else {
        my $msg = "Validation failed.";
        $logger->fatal($msg);
        Grid::Request::Exception->throw($msg);
    }
    return wantarray ? @ids : \@ids;
}


=item $obj->times([times]);

B<Description:> Sometimes it may be desirable to execute a command more than
one time. For instance, a user may choose to run an executable many
times, with each invocation operating on a different input file. This technique
allows for very powerful parallelization of commands. The times method
establishes how many times the executable should be invoked.

B<Parameters:> An integer number may be passed in to set the times attribute on
the request object. If no argument is passed, the method functions as a getter
and returns the currently set "times" attribute, or undef if unset. The setting
cannot be changed after the request has been submitted.

B<Returns:> $times, when called with no arguments.


=item $obj->to_xml();

B<Description:> Returns the XML representation of the entire request.

B<Parameters:> None.

B<Returns:> $xml, a scalar XML string.

=cut

sub to_xml {
    my ($self, @args) = @_;
    $logger->debug("In to_xml.");

    require IO::Scalar;
    require XML::Writer;
    my $xml = "";
        
    my $handle = IO::Scalar->new(\$xml);

    my $w = XML::Writer->new( OUTPUT      => $handle,
                              DATA_MODE   => 1,
                              DATA_INDENT => 4
                            );

    $w->xmlDecl();
    $w->comment("Generated by " . __PACKAGE__ . ": " . localtime());
    $w->startTag('commandSetRoot');

    # We de-reference the array reference containing all Command
    # objects, call to_xml() on each of them and use the XML string to
    # build the overall request XML document.

    my $count = 1;
    my $total = $self->command_count();
    foreach my $com_obj ( @{ $self->_com_obj_list() } ) {
        $logger->debug("Encoding command object $count/$total.");
        my $command_xml = $com_obj->to_xml();
        $handle->print($command_xml);
        $count++;
    }

    $w->endTag('commandSetRoot');
    $w->end();

    $handle->close;
    return $xml;
}

=item $obj->command_count();

B<Description:> Returns the number of currently configured commands
in the overall request.

B<Parameters:> None.

B<Returns:> $count, a scalar. 

=cut

sub command_count {
    $logger->debug("In command_count.");
    my $self = shift;
    my $total = scalar( @{ $self->_com_obj_list() } );
    return $total;
}

=item $obj->wait_for_request();

B<Description:> Once a request has been submitted, a user may choose to wait
for the request to complete before proceeding. This is called "blocking". To
block and wait for a request, submit it ( by calling submit() ) and then call
wait_for_request(). Control will return once the request has been finished
(either completed or errored). If an attempt is made to call this method before
the request has been submitted, a warning is generated.

B<Parameters:> None.

B<Returns:> None. 

=cut

sub wait_for_request {
    $logger->debug("In wait_for_request.");
    my ($self, @args) = @_;
    if ($self->is_submitted()) {
        # Wait for the job to complete
        my $total = $self->command_count();
        my $count = 1;
        for (my $cmd = 0; $cmd < $total; $cmd++) {
            $logger->info("Waiting for command $count/$total.");
            my $cmd_obj = $self->_com_obj_list->[$cmd];
            _sync_ids($cmd_obj);
            $logger->info("Command $count/$total finished executing.");
            $count++;
        }
    } else {
        $logger->logwarn("The request must be submitted before wait_for_request ",
                         "may be called.");
    }
}

sub _sync_ids {
    $logger->debug("In _sync_ids.");
    my $cmd_obj = shift;
    my $max_time = $cmd_obj->max_time(); # In seconds
    my $wait_time = (defined $max_time) ? $max_time : $DRMAA_TIMEOUT_WAIT_FOREVER;
    if ($wait_time == $DRMAA_TIMEOUT_WAIT_FOREVER) {
        $logger->debug("Will wait indefinitely for it.")
    } else {
        $logger->debug("Will wait for $wait_time seconds.")
    }
    my @job_ids = $cmd_obj->ids();
    my ($error, $diagnosis) = drmaa_synchronize(\@job_ids, $wait_time, 0);
    _throw_drmaa("Error waiting for job execution.", $error, $diagnosis) if $error;
}

=item $obj->get_tasks();

B<Description:> Retrieve the tasks for this request

B<Parameters:> None.

B<Returns:> A hash of hashes (HoH) representing the tasks for this
request. The hash is organized by the index and the value
is another hashref with the actual data. The following is an example
of the return data structure:

  $hashref = {
            '1' => {
                   'returnValue' => 0,
                   'message'     => undef,
                   'state'       => 'FINISHED'
                 },
            '2' => {
                   'returnValue' => -1,
                   'message'     => 'Failed task.',
                   'state'       => 'FAILED'
                 }
          }

=cut

sub get_tasks {
    $logger->debug("In get_tasks.");
    my ($self, @args) = @_;
    my $tasks;
    if ($self->is_submitted) {
        # TODO: Implement via DRMAA vice HTC
    } else {
        $logger->logwarn("The request must be submitted before get_tasks ",
                         "may be called.");
    }
    return $tasks;
}

sub get_status {
    my ($class, $job_id) = @_;
    if (! defined $logger) {
        _init_config_logger($default_config);
    }
    _init_drmaa();

    $class = ref($class) || $class;
    if (! defined $job_id) {
        Grid::Request::Exception->throw("No job id specified.");
    }
    $logger->debug("Getting status for id $job_id.");

    my $status;
    my ($error, $remoteps, $diagnosis) = drmaa_job_ps($job_id);
    _throw_drmaa("Could not get status.", $error, $diagnosis) if $error;
    if ($remoteps == $DRMAA_PS_RUNNING) {
        $status = "RUNNING";
    } elsif ($remoteps == $DRMAA_PS_QUEUED_ACTIVE) {
        $status = "WAITING";
    } elsif ($remoteps == $DRMAA_PS_DONE) {
        $status = "FINISHED";
    } elsif ($remoteps == $DRMAA_PS_FAILED) {
        $status = "FAILED";
    } elsif (($remoteps == $DRMAA_PS_SYSTEM_SUSPENDED) ||
             ($remoteps == $DRMAA_PS_USER_SUSPENDED) ||
             ($remoteps == $DRMAA_PS_USER_SYSTEM_SUSPENDED)) { 
        $status = "SUSPENDED";
    } elsif (($remoteps == $DRMAA_PS_SYSTEM_ON_HOLD) ||
             ($remoteps == $DRMAA_PS_USER_ON_HOLD) ||
             ($remoteps == $DRMAA_PS_USER_SYSTEM_ON_HOLD)) {
        $status = "HELD";
    } elsif ($remoteps == $DRMAA_PS_UNDETERMINED) {
        $status = "UNKNOWN";
    } else {
        $status = "UNKNOWN";
    }
    return $status;
}

1;

__END__

=back

=head1 ENVIRONMENT

The GRID_CONFIG environment variable is checked for an alternate path
to the configuration file holding the DRM engine in use and the shared
temporary directory to use.

If however, the getenv() method is called, this module will read and
store the entire environment and attempt to recreate it for the job(s)
on the grid.

=head1 DIAGNOSTICS

=over 4

=item "Initialization failed. Too many arguments."

The object could not be initialized when the constructor was called.
Too many arguments were provided to "new".

=back

=head1 BUGS

None known.

=head1 SEE ALSO

 Config::IniFiles
 Hash::Util
 IO::Scalar
 Log::Log4perl
 Schedule::DRMMAc
 Grid::Request::Command
 Grid::Request::HTC
 Grid::Request::DRM::SGE
 XML::Writer
