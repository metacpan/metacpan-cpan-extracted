package Grid::Request::Command;

=head1 NAME

Command.pm - Model a command that is to be executed on the computational grid.

=head1 VERSION

This document refers to Command.pm $Revision: 8365 $.

=head1 DESCRIPTION

Warning: Do not use this module directly unless you absolutely know what you
are doing. Please use the Grid::Request module instead. The POD provided
here is purely for documentation purposes only and does not mean that this
module should be used directly by end users.

The term DCE, as used in this documentation, shall be taken to mean
"Distributed Computing Environment". This term is freely interchangeable with
"HTC" (for High Throughput Computing) which you may also see run across.

=head2 Overview

This module is not designed for direct use. Please consult the documentation
for Grid::Request.

=head2 Class and object methods

=over 4

=cut


use strict;
use Log::Log4perl qw(get_logger);
use File::Temp qw(tempfile);
use Grid::Request::Param;

my $DEFAULT_BLOCK_SIZE = 100;

my $logger = get_logger(__PACKAGE__);

use vars qw( %VALID_OS %VALID_PARAM_ARGS %VALID_STATE
             %VALID_TYPE %VALID_CMD_TYPE );

# The IO:Scalar and XML::Writer are pulled in with "require" if necessary.
our $VERSION = qw$Revision: 8365 $[1];

# Get rid of warnings about single usage.
if ($^W) {
    $VERSION = $VERSION;
}

# These are the valid operating systems supported by the DCE.
%VALID_OS = ( Linux => 1,
              Solaris => 1,
              Linux64   => 1,
              Solaris64   => 1,
            );

%VALID_STATE = ( INIT        => 1,
                 WAITING     => 1,
                 FAILED      => 1,
                 FINISHED    => 1,
                 RUNNING     => 1,
                 INTERRUPTED => 1,
                 SUSPENDED   => 1,
                 UNKNOWN     => 1,
               );

%VALID_TYPE = ( ARRAY     => 1,
                DIR       => 1,
                PARAM     => 1,
                FILE      => 1,
                TEMPFILE  => 1,
              );

%VALID_CMD_TYPE = ( htc     => 1,
                    mw       => 1,
                  );

%VALID_PARAM_ARGS = ( KEY   => 1,
                      VALUE => 1,
                      TYPE  => 1,
                    ); 

# The default operating system to run the command on. This must be
# a key in %VALID_OS.
my $default_opsys = "Linux";

my $default_cmd_type = "htc";

# The default state of a command. This is the state that all commands
# start with.
my $default_state = "INIT";

=item Grid::Request::Command->new(%args);

B<Description:> This is the object constructor. Parameters are passed to
the constructor in the form of a hash. Example:

  my $req = Grid::Request::Command->new( opsys => "Linux",
                                         project => "SomeProject",
                                       );

B<Parameters:> Only the project parameter is required when calling the
constructor. Remaining parameters can be added with individual method calls.

B<Returns:> $obj, a command object.

=cut

sub new {
    $logger->debug("In constructor, new.");
    my ($class, %args) = @_;
    my $self = bless {}, $class || ref($class);
    $self->_init(\%args);
    return $self;
}


sub _init {
    $logger->debug("In _init");
    my ($self, $arg_ref) = @_;
    my %args = %$arg_ref;

    # Set the opsys attribute.
    my $opsys = $args{opsys} || $default_opsys;
    $logger->debug("Setting the opsys to $opsys.");
    $self->opsys($opsys);

    $self->cmd_type($default_cmd_type);

    $self->{params} = [];
    $self->{ids} = [];

    # Set the state attribute to the default.
    $self->{state} = $default_state;

    # This is important for systems such as psearch, which change
    # uid's in order to submit jobs on behalf of users.
    # We should use the real user id.
    $logger->debug("Setting the username according to effective uid: ",
                   "$self->{username}.");
    $self->{username} = getpwuid($<);

    # Set the default block size.
    $logger->debug("Setting the default block size.");
    $self->{block_size} = $DEFAULT_BLOCK_SIZE;
    
    $logger->debug("Setting the project.");
    if ( exists($args{project}) && defined($args{project}) ) {
        $self->project($args{project});
    } else {
        my $msg = "Mandatory 'project' attribute not provided.";
        $logger->fatal($msg);
        Grid::Request::Exception->throw($msg);
    }

    foreach my $method qw(block_size command class error getenv initialdir input output
                          name priority times evictable length runtime hosts
                         ) {
        if (exists($args{$method}) && defined($args{$method})) {
            $logger->info("Initializing $method.");
            $self->$method( $args{$method} );
        }
    }
}

=item $obj->account([account]);

B<Description:> The account attribute is used to affiliate a grid job with
a particular account. Grid engines differ in their treatment of the account
attribute.

B<Parameters:> To use as a setter, the first parameter will be used to
set (or reset) the account attribute for the command.

B<Returns:> The currently set account (if called with no parameters).

=cut

sub account {
    $logger->debug("In account");
    my ($self, $account, @args) = @_;

    if (defined $account) {
        $logger->warn("The account method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{account} = $account;
    } elsif (exists($self->{account}) && defined($self->{account})) {
        return $self->{account};
    } else {
        return undef;
    }
}


=item $obj->block_size( [ $scalar | $code_ref ] );

B<Description:> By default, Master/Worker jobs have a default block size of
100.  That is to say, that each worker on the grid will process 100 elements of
the overall pool of job invocations. However, this isn't always appropriate.
The user may override the default block size by calling this method and setting
the block size to an alternate value (a positive integer). The user may also
provide an anonoymous subroutine (code reference) so that the block size can be
computed dynamically. If choosing to pass a subroutine , the code will be passed
two arguments: the command that will be invoked, and the number of elements that
will be iterated over. The subroutine can then use these pieces of information
to compute the block size. The subroutine MUST return a positive integer scalar
or an exception will be thrown.

B<Parameters:> A positive integer scalar, or an anonymous subroutine/code
reference.

B<Returns:> The block size scalar or code reference if called as an accessor
(no-arguments). If the block size has not been explicitly set, then the default
block size is returned. No return if called as a mutator.

=cut

sub block_size {
    $logger->debug("In block_size");
    my ($self, $block_size, @args) = @_;

    if (scalar @args) {
        Grid::Request::InvalidArgumentException->throw(
            "Too many arguments passed to the 'block_size' method.");
    }

    if (defined $block_size) {
        if (ref $block_size eq "CODE") {
            $logger->debug("Got a code reference for the block size.");
        } elsif (ref \$block_size eq "SCALAR") {
            if ($block_size =~ /^-?\d+$/) {
                if ($block_size <= 0) {
                    Grid::Request::InvalidArgumentException->throw(
                        "Scalar argument for 'block_size' must be a positive integer.");
                } 
            }
        } else {
            Grid::Request::InvalidArgumentException->throw(
                "Illegal argument for 'block_size' method.");
        }
        
        # If we get here, then we have an acceptable block size
        $self->{block_size} = $block_size;
    } elsif (exists($self->{block_size}) && defined($self->{block_size})) {
        return $self->{block_size};
    } else {
        return undef;
    }
}


=item $obj->add_param(@param_args);

B<Description:> This is documented in Grid::Request (Request.pm).

B<Parameters:> Scalar, list or hash, depending on what you are trying
to achieve.
 
B<Returns:> The currently set account (if called with no parameters).

=cut

sub add_param {
    $logger->debug("In add_param");
    my ($self, @args) = @_;
    my $param_obj = Grid::Request::Param->new();
    my $msg;
    # We need to determine if we are being passed named parameters in a hash
    # or not. We do this by counting arguments and seeing what type they are.
    if ( (@args == 1) && (ref($args[0]) eq "HASH") ) {
        $logger->debug("Args appear to be named parameters.");
        my %param_hash = %{ $args[0] };
        foreach my $named (keys %param_hash) {
            # uppercase to make things case insensitive.
            my $uc_named = uc($named);
            my $lc_named = lc($named);
            unless ( $VALID_PARAM_ARGS{$uc_named} ) {
                $msg = "Invalid named parameter: $named. Only " .
                      join(", ", sort keys(%VALID_PARAM_ARGS)) .
                      " are recognized.";
                $logger->error($msg);
                Grid::Request::InvalidArgumentException->throw($msg);
            } else {
                # Store the lowercase version because that is what is needed
                # later in the to_xml() method.
                $param_hash{$lc_named} = $param_hash{$named};
            }
        }
        # They have to pass "VALUE" at the very least.
        unless ( exists($param_hash{value}) && defined($param_hash{value}) ) {
            $msg = "'value' must be specified.";
            $logger->error($msg);
            Grid::Request::InvalidArgumentException->throw($msg);
        }

        # If type was not specified, then we default it to "PARAM" here.
        my $type = $param_hash{type} ||= "PARAM";
        $param_obj->type($type) if ($type ne "PARAM");
        $param_obj->value($param_hash{value});
        $param_obj->key($param_hash{key}) if exists($param_hash{key});
    } else { 
        if (@args == 1) {
            $param_obj->type("PARAM");
            $param_obj->value($args[0]);
        } elsif (@args == 3) {
            # For cases of ->add_param("-input", '/path/to/input.$(Index).txt', "DIR");
            $param_obj->key($args[0]);
            $param_obj->value($args[1]);
            # Make the type case insensitive from the perspective of the user
            # by always capitalizing what they passed in.
            $param_obj->type(uc($args[2]));
        } elsif (@args > 3 || @args == 0) {
            # This method was called incorrectly.
            $msg = "add_param() only accepts 1 or 3 arguments.";
            $logger->error($msg);
            Grid::Request::InvalidArgumentException->throw($msg);
        }
    }

    # cmd type defaults to "htc" and is switched to "mw" if any type of
    # param other than PARAM is used.
    my $type = $param_obj->type();
    if ($type ne "PARAM") {
	$logger->info("Switching CMD Type to mw because param is of type $type.");
	$self->cmd_type("mw");
    }

    # If type is 'DIR', make sure that the directory has more than 0 files. 
    if ($type eq 'DIR') {
	my $mydir = $param_obj->value();
	$logger->info("Validating the directory $mydir for valid number of files");
	opendir(DIR, $mydir) || $logger->logcroak("Can't opendir $mydir: $!");
        my @files = sort grep { -f "$mydir/$_" && !/^\./ } readdir DIR;
	closedir DIR;

	# If the number of files in the directory is 0, error out.
	if (scalar(@files) == 0) {
	    $msg = "$mydir has 0 valid files. Cannot add the parameter.";
            $logger->fatal($msg);
            Grid::Request::InvalidArgumentException->throw($msg);
	}
	$logger->info("$mydir is not empty.");
    }

    # Handle an ARRAY type by writing the contents of the array to a temporary
    # file, and translating the ARRAY call to a FILE call.
    if ($type eq "ARRAY") {
	$logger->info("Type was array.");
        # The "value" is assumed to contain the array as an array reference.
        my $array = $param_obj->value();
        unless (scalar(@$array)) {
	    $msg = "The array is empty!";
	    $logger->fatal($msg);
            Grid::Request::InvalidArgumentException->throw($msg);
        }
        my $tempfile = $self->_write_temp_array_file($array);
	$logger->debug("Temp file created: $tempfile");

	# Get the file size 
	my $size = (stat($tempfile))[7];
	if ($size == 0) {
	    $msg = "The tempfile created for the array has 0 size. Can't submit request!";
	    $logger->fatal($msg);
            Grid::Request::Exception->throw($msg);
	}
	$logger->info("$tempfile has a valid size");
        $param_obj->type("FILE");
        $param_obj->value($tempfile);
    }

    ## If type is 'FILE' then make sure the file is of more than 0 in size.
    if ($type eq 'FILE') {
	my $myfile = $param_obj->value();
	$logger->info("Validating the file: $myfile.");

	# Get the file size 
	my $size = (stat($myfile))[7];
	# If the file size is 0, then error out.
	if ($size == 0) {
	    $msg = "$myfile has 0 size. Can't submit request! Stopped";
	    $logger->error($msg);
            Grid::Request::InvalidArgumentException->throw($msg);
        }
	$logger->info("$myfile is not empty.");
    }

    push( @{ $self->{params} }, $param_obj);
}


=item $obj->class([$class]);

B<Description:> This method is used to set and retrieve the command class
attribute. Class describes the general purpose for a command or what is will
be used for. For example, a command can be marked as a request for "engineering"
or "marketing". Ad hoc commands will generally not use a class setting. If in
doubt, leave the class attribute unset.

B<Parameters:> With no parameters, this method functions as a getter. With one
parameter, the method sets the command class. No validation is performed on
the class passed in.

B<Returns:> The currently set class (when called with no arguments).

=cut

sub class {
    $logger->debug("In class");
    my ($self, $class, @args) = @_;

    if (defined $class) {
        $logger->warn("The class method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{class} = $class;
    } elsif (exists($self->{class}) && defined($self->{class})) {
        return $self->{class};
    } else {
        return undef;
    }
}


=item $obj->command([$command]);

B<Description:> This method is used to set or retrieve the executable that
will be called for the request.

B<Parameters:> With no parameters, this method functions as a getter. With one
parameter, the method sets the command executable. Currently, this module does
not attempt to verify whether the exeutable is actually present or whether
permissions on the executable are appropriate.

B<Returns:> The currently set executable (when called with no arguments).

=cut

sub command {
    $logger->debug("In command");
    my ($self, $command, @args) = @_;

    if (defined $command) {
        $logger->warn("The command method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{command} = $command;
    } elsif (exists($self->{command}) && defined($self->{command})) {
        return $self->{command};
    } else {
        $logger->warn("The command executable is not yet set.");
        return undef;
    }
}


=item $obj->email([$command]);

B<Description:> This method is used to set or retrieve the email of the user
submitting the command. The email is important for notifications and for
tracking purposes in case something goes wrong.

B<Parameters:> With no parameters, this method functions as a getter and
returns the currently configured email address. If the command has not yet
been submitted, the user may set or reset the email address by providing an
argument. The address is not currently validated for RFC compliance.

B<Returns:> The email address currently set, or undef if unset (when called
with no arguments).

=cut

sub email {
    $logger->debug("In email.");
    my ($self, $email, @args) = @_;

    if (defined $email) {
        $logger->warn("The email method takes only one argument.") if @args;
        $self->{email} = $email;
    } elsif (exists($self->{email}) && defined($self->{email})) {
        return $self->{email};
    } else {
        return undef;
    }
}

=item $obj->end_time()

B<Description:> This method is used as a getter for the finish time of the
command. It may only be used as a setter by the ProxyServer module. If any
other package (including main) attempts to set the end_time attribute with
this method, an error will result.

B<Parameters:> None.

B<Returns:> The ending time of the command (the time the DCE finished
processing the command), or undef if the end_time has not yet been
established.

=cut

sub end_time {
    $logger->debug("In end_time.");
    my ($self, $end_time, @args) = @_;

    if (defined $end_time) {
        $logger->warn("The end_time method takes only one argument.")
            if @args;
        $self->{end_time} = $end_time;
    } elsif (exists($self->{end_time}) && defined($self->{end_time})) {
        return $self->{end_time};
    } else {
        return undef;
    }
}


=item $obj->error([errorfile])

B<Description:> This method allows the user to set, or if the command has
not yet been submitted, to reset the error file for the command. The error
file will be the place where all STDERR from the invocation of the executable
will be written to. This file should be in a globally accessible location on
the filesystem. The attribute may no longer be changed with this method once
the command has been submitted.

B<Parameters:> To set the error file, call this method with one parameter,
which should be the path to the file where STDERR is to be written.

B<Returns:> When called with no arguments, this method returns the currently
set error file, or undef if not yet set.

=cut

sub error {
    $logger->debug("In error");
    my ($self, $error, @args) = @_;

    if (defined $error) {
        $logger->warn("The error method takes only one argument. ",
                      "when making an assignment.") if @args;
        $self->{error} = $error;
    } elsif (exists($self->{error}) && defined($self->{error})) {
        return $self->{error};
    } else {
        return undef;
    }
}

sub ids {
    my ($self, @job_ids) = @_;
    if (@job_ids) {
        $self->{ids} = \@job_ids;
    } else {
        return wantarray ? @{ $self->{ids} } : $self->{ids};
    }
}

sub id {
    my ($self, @args) = @_;
    warn "id() is deprecated. Please use the ids() method.\n";
    return $self->ids(@args);
}

=item $obj->getenv([1]);

B<Description:> The getenv method is used to set whether the user environment
should be replicated to the DCE or not. To replicate your environment, call
this method with an argument that evaluates to true. Calling it with a 0
argument, or an expression that evaluates to false, will turn off environment
replication. The default is NOT to replicate the user environment across the
DCE.

B<Parameters:> This method behaves as a getter when called with no arguments.
If called with 1, or more arguments, the first will be used to set the
attribute to either 1 or 0.

B<Returns:> The current setting for getenv (if called with no arguments).

=cut

sub getenv {
    $logger->debug("In getenv");
    my ($self, $getenv, @args) = @_;

    if (defined $getenv) {
        $logger->warn("The getenv method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{getenv} = ($getenv) ? 1 : 0;
    } elsif (exists($self->{getenv}) && defined($self->{getenv})) {
        return $self->{getenv};
    } else {
        return undef;
    }
}


=item $obj->project([project]);

B<Description:> The project attribute is used to affiliate usage of the
Distributed Resource Manager (DRM) with a particular administrative
project. This will allow for more effective control and allocation
of resources, especially when high priority projects must be fulfilled.
Therefore, the "project" is mandatory when the object is built with the
constructor, however, the user may still change the project attribute
as long as the job has not yet been submitted (after submission most
attributes are locked).

B<Parameters:> To use as a setter, the first parameter will be used to
set (or reset) the project attribute for the command.

B<Returns:> The currently set project (if called with no parameters).

=cut

sub project {
    $logger->debug("In project");
    my ($self, $project, @args) = @_;

    if (defined $project) {
        $logger->warn("The project method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{project} = $project;
    } elsif (exists($self->{project}) && defined($self->{project})) {
        return $self->{project};
    } else {
        return undef;
    }
}

=item $obj->input()

B<Description:>

B<Parameters:>

B<Returns:>

=cut

sub input {
    $logger->debug("In input");
    my ($self, $input, @args) = @_;

    if (defined $input) {
        $logger->warn("The input method takes only one argument. ",
                      "when making an assignment.") if @args;
        $self->{input} = $input;
    } elsif (exists($self->{input}) && defined($self->{input})) {
        return $self->{input};
    } else {
        return undef;
    }
}


=item $obj->initialdir([path]);

B<Description:> This method sets the directory where the DCE will be
chdired to before invoking the command. This is an optional parameter,
and if the user leaves it unspecified, the default will be that the DCE
will be chdired to the root directory "/" before beginning the command.
Use of initialdir is encouraged to promote use of relative paths.

B<Parameters:> A scalar holding the path to the directory the DCE should
chdir to before invoking the executable (command).

B<Returns:> When called with no arguments, returns the currently set
initialdir, or undef if not yet set.

=cut

sub initialdir {
    $logger->debug("In initialdir");
    my ($self, $initialdir, @args) = @_;

    if (defined $initialdir) {
        $logger->warn("The initialdir method takes only one argument. ",
                      "when making an assignment.") if @args;
        $self->{initialdir} = $initialdir;
    } elsif (exists($self->{initialdir}) && defined($self->{initialdir})) {
        return $self->{initialdir};
    } else {
        return undef;
    }
}


=item $obj->length([length]);

B<Description:> This method is used to characterize how long the request
is expected to take to complete. For long running requests, an attempt to
match appropriate resources is made. If unsure, leave this setting unset.

B<Parameters:> "short", "medium", "long". No attempt is made to validate
the length passed in when used as a setter.

B<Returns:> The currently set length attribute (when called with no
arguments).

=cut

sub length {
    $logger->debug("In length.");
    my ($self, $length, @args) = @_;

    if (defined $length) {
        $logger->warn("The length method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{length} = $length;
    } elsif (exists($self->{length}) && defined($self->{length})) {
        return $self->{length};
    } else {
        return undef;
    }
}


=item $obj->name([name]);

B<Description:> The name attribute for command objects is optional and is
provided as a convenience to users of the DCE to name their commands.

B<Parameters:> A scalar name for the command. Note that the name will
be encoded for packaging into XML, so the user is advised to refrain from
using XML sensitivie characters such as > and <.

B<Returns:> When called with no arguments, returns the current name, or
undef if not yet set. The name cannot be changed once a request is submitted.

=cut

sub name {
    $logger->debug("In name.");
    my ($self, $name, @args) = @_;

    if (defined $name) {
        $logger->warn("The output method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{name} = $name;
    } elsif (exists($self->{name}) && defined($self->{name})) {
        return $self->{name};
    } else {
        $logger->warn("The command name was not set.");
        return undef;
    }
}

=item $obj->opsys($os[,$os2,..,$osn]);

B<Description:> The default operating system that commands will be run on is
Linux. Users can choose to submit commands to other operating systems in the
DCE by using this method. Available operating systems are "Linux", "Solaris",
"Linux64", "Solaris64". Multiple operating systems can be specified in a 
comma seperated list "Linux,Solaris". An attempt to set the opsys attribute 
to anything else results in an error.

B<Parameters:> A comma seperated list of one or more of the following
"Linux", "Solaris" when called as a setter (with one argument). 

B<Returns:> When called with no arguments, returns the operating system the
command will be run on, which defaults to "Linux".

=cut

sub opsys {
    $logger->debug("In opsys.");
    my ($self, $opsys, @args) = @_;

    if (defined $opsys) {
        $logger->warn("The opsys method takes only one argument.") if @args;
	# We now accept a comma separated list of operating systems, so we
	# need to validate the list
        foreach my $os (split(/,/, $opsys)) {
	    if (defined $VALID_OS{$os}) {
		$logger->debug("Operating system $opsys validated correctly.");
	    } else {
                my $msg = "Invalid opsys: $os. Must be one of " . join(", ", keys %VALID_OS) . ".";
		$logger->error($msg);
                Grid::Request::InvalidArgumentException->throw($msg);
	    }
	}
	$self->{opsys} = $opsys;
    } elsif (exists($self->{opsys}) && defined($self->{opsys})) {
        return $self->{opsys};
    } else {
        $logger->error("The opsys was somehow reset. Using default of $default_opsys.");
        $self->{opsys} = $default_opsys;
    }
}


sub cmd_type {
    $logger->debug("In cmd_type.");
    my ($self, $ctype, @args) = @_;

    if (defined $ctype) {
        $logger->warn("The cmd_type method takes only one argument.") if @args;
	if (defined $VALID_CMD_TYPE{$ctype}) {
	    $logger->debug("command $ctype validated correctly.");
	} else {
            my $msg = "Invalid command type: $ctype.";
	    $logger->error($msg);
            Grid::Request::InvalidArgumentException->throw($msg);
	}

	$self->{cmd_type} = $ctype;
	
    } elsif (exists($self->{cmd_type}) && defined($self->{cmd_type})) {
        return $self->{cmd_type};
    } else {
        $logger->error("The cmd_type was somehow reset. Using default.");
        $self->{cmd_type} = $default_cmd_type;
    }
}


# Documeted in Grid::Request
sub hosts {
    $logger->debug("In hosts.");
    my ($self, $hosts, @args) = @_;

    if (defined $hosts) {
        $logger->warn("The hosts method takes only one argument.") if @args;
	$self->{hosts} = $hosts;
    } elsif (exists($self->{hosts}) && defined($self->{hosts})) {
        return $self->{hosts};
    } else {
	return undef;
    }
}

# Documeted in Grid::Request
sub pass_through {
    $logger->debug("In pass_through");
    my ($self, $pass_through, @args) = @_;

    if (defined $pass_through) {
        $logger->warn("The pass_through method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{pass_through} = $pass_through;
    } elsif (exists($self->{pass_through}) && defined($self->{pass_through})) {
        return $self->{pass_through};
    } else {
        return undef;
    }
}


# Documeted in Grid::Request
sub memory {
    $logger->debug("In memory");
    my ($self, $memory, @args) = @_;

    if (defined $memory) {
        $logger->warn("The memory method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{memory} = $memory;
    } elsif (exists($self->{memory}) && defined($self->{memory})) {
        return $self->{memory};
    } else {
        return undef;
    }
}

=item $obj->max_time($seconds);

B<Description:> The maximum amount of time to wait for completion of this
command on the grid in seconds. If not max_time is provided for a command the
default behavior is to wait indefinitely for its completion.

B<Parameters:> $seconds, a scalar integer.

B<Returns:> When called as a getter, the method returns the number of
seconds configured. When called as a setter, the method returns undef.

=cut

sub max_time {
    $logger->debug("In max_time");
    my ($self, $max_time, @args) = @_;
    if (defined $max_time) {
        $logger->warn("The max_time method takes only one argument ",
                      "when making an assignment.") if @args;
        if ($max_time !~ m/\D/) {
            $self->{max_time} = $max_time;
        } else {
            Grid::Request::InvalidArgumentException->throw("Invalid max_time.");
        }
    } elsif (exists($self->{max_time}) && defined($self->{max_time})) {
        return $self->{max_time};
    }
    return undef;
}


=item $obj->output([path]);

B<Description:> Sets the path for the output file, which would hold all of
the output directed to STDOUT by the invocation of the command on the DCE.
This method functions as a setter and getter.

B<Parameters:> A path to a file. The file must be globally accessible on
the filesystem in order to work, otherwise, the location may not be accessible
to compute nodes on the DCE. This attribute may not be changed once a command
is submitted.

B<Returns:> When called with no arguments, the method returns the currently
set path for the output file, or undef if not yet set.

=cut

sub output {
    $logger->debug("In output");
    my ($self, $output, @args) = @_;

    if (defined $output) {
        $logger->warn("The output method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{output} = $output;
    } elsif (exists($self->{output}) && defined($self->{output})) {
        return $self->{output};
    } else {
        return undef;
    }
}


=item $obj->params();

B<Description:> Retrieve the list of currently registered parameters for the
command.

B<Parameters:> None.

B<Returns:> The method returns a list of hash references.

=cut

sub params {
    $logger->debug("In params.");
    my $self = shift;
    return @{ $self->{params} };
}


=item $obj->priority([priority]);

B<Description:> Use this method to set the optional priority attribute on the
command object. The priority setting is used to help allocate the appropriate
resources to the request if and when they are available. Higher priority
commands may displace lower priority commands.

B<Parameters:> Scalar priority value.

B<Returns:> The current priority, or undef if unset.

=cut

sub priority {
    $logger->debug("In priority.");
    my ($self, $priority, @args) = @_;

    if (defined $priority) {
        $logger->warn("The priority method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{priority} = $priority;
    } elsif (exists($self->{priority}) && defined($self->{priority})) {
        return $self->{priority};
    } else {
        return undef;
    }
}


=item $obj->start_time([time]);

B<Description:> This method is only intended to be used as a getter by end
users. It may only be used as a setter by the ProxyServer module. If any
attempt is made to set the start_time attribute of the command object
elsewhere, an error will occur.

B<Parameters:> None.

B<Returns:> $time, the start time (scalar) that the DCE began processing
the command.

=cut

sub start_time {
    $logger->debug("In start_time.");
    my ($self, $start_time, @args) = @_;

    if (defined $start_time) {
        $logger->warn("The start_time method takes only one argument.")
            if @args;
        $self->{start_time} = $start_time;
    } elsif (exists($self->{start_time}) && defined($self->{start_time})) {
        return $self->{start_time};
    } else {
        return undef;
    }
}


=item $obj->state([state]);

B<Description:> This method is only intended to be used as a getter by end
users. It may only be used as a setter by the ProxyServer module. If any
attempt is made to set the "state" attribute of the command object
elsewhere, an error will occur. Valid states are:

    INIT
    INTERRUPTED
    FAILURE
    FINISHED
    RUNNING
    SUSPENDED
    UNKNOWN
    WAITING

B<Parameters:> None.

B<Returns:> $state, the current state of the command.

=cut

sub state {
    $logger->debug("In state.");
    my ($self, $state, @args) = @_;

    if (defined $state) {
        $logger->warn("The state method takes only one argument.") if @args;
        if (defined $VALID_STATE{$state}) {
            $logger->debug("Command state: $state validated correctly.");
            $self->{state} = $state;
        } else {
            $logger->error("Bad state: $state. Must be one of ",
                           join(", ", sort keys %VALID_STATE), ".");
        }
    } elsif (exists($self->{state}) && defined($self->{state})) {
        return $self->{state};
    } else {
        $logger->error("The state was somehow reset. ",
                       "Using default $default_state.");
        $self->{state} = $default_state;
    }
}


=item $obj->tempdir([tempdir]);

B<Description:> This method may be used to set or retrieve the path to
the directory where temporary files are stored for the HTC request system.
Temporary files are sometimes created when the user passes the add_param
method an array with the type set to ARRAY. The system processes this
by writing each element of the array to a temporary file so that the
server processing the request may consult the file and iterate over each
entry.

B<Parameters:> A scalar holding the path to the temporary directory.
Additional arguments will cause a warning and will be ignored.

B<Returns:> When called with no arguments, returns the currently set
temporary directory, or undef if not yet set.

=cut

sub tempdir {
    $logger->debug("In tempdir.");
    my ($self, $tempdir, @args) = @_;

    if (defined $tempdir) {
        $logger->warn("The tempdir method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{tempdir} = $tempdir;
    } elsif (exists($self->{tempdir}) && defined($self->{tempdir})) {
        return $self->{tempdir};
    } else {
        $logger->warn("The tempdir was not set.");
        return undef;
    }
}


=item $obj->times([times]);

B<Description:> Sometimes it may be desirable to execute a command more than
one time. For instance, a user may choose to execute a particular command many
times, with each invocation operating on a different input file. This
technique allows for very powerful parallelization of commands. The times
method establishes how many times the command should be invoked.

B<Parameters:> An integer number may be passed in to set the times attribute
on the command object. If no argument is passed, the method functions as a
getter and returns the currently set "times" attribute, or undef if unset. The
setting cannot be changed after the request has been submitted.

B<Returns:> $times, when called with no arguments.

=cut

sub times {
    $logger->debug("In times.");
    my ($self, $times, @args) = @_;

    if (defined $times) {
        $logger->warn("The times method takes only one argument ",
                      "when making an assignment.") if @args;
        # TODO: Not robust enough of a check
        if ($times =~ m/\D/) {
            $logger->error("Encountered non-numeric 'times' attribute.");
            return undef;
        }
        $self->{times} = $times;
    } elsif (exists($self->{times}) && defined($self->{times})) {
        return $self->{times};
    } else {
        return undef;
    }
}

=item $obj->runtime([runtime]);

B<Description:> Use this method to set the optional runtime attribute on the
command object. The runtime setting helps to schedule the request relatively 
faster. 

B<Parameters:> Scalar runtime value.

B<Returns:> The current runtime, or undef if unset.

=cut

sub runtime {
    $logger->debug("In runtime.");
    my ($self, $runtime, @args) = @_;

    if (defined $runtime) {
        $logger->warn("The runtime method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{runtime} = $runtime;
    } elsif (exists($self->{runtime}) && defined($self->{runtime})) {
        return $self->{runtime};
    } else {
        return undef;
    }
}

=item $obj->evictable([evictable]);

B<Description:> Use this method to set the optional evictable attribute on the
command object. The evictable setting helps to schedule the request on an appropriate
machine on the grid. 

B<Parameters:> Scalar runtime value.

B<Returns:> The current runtime, or undef if unset.

=cut

sub evictable {
    $logger->debug("In evictable.");
    my ($self, $evictable, @args) = @_;

    if (defined $evictable) {
        $logger->warn("The evictable method takes only one argument ",
                      "when making an assignment.") if @args;
        $self->{evictable} = $evictable;
    } elsif (exists($self->{evictable}) && defined($self->{evictable})) {
        return $self->{evictable};
    } else {
        return undef;
    }
}

=item $obj->to_xml();

B<Description:> Requests are packaged into XML before they are submitted. To
inspect the XML produced, users can call this method, which will return the
XML in the form of a string (scalar).

B<Parameters:> None.

B<Returns:> $xml, a string representation of the command object
in XML as it would be transmitted to the High Throughput Computing
(HTC) infrastructure.

=cut


sub to_xml {
    $logger->debug("In to_xml.");
    my ($self, @args) = @_;
    
    $logger->debug("Loading XML::Writer");
    require XML::Writer;
    require IO::Scalar;

    my $exe      = $self->command;
    my $cmd_type = $self->cmd_type;
    my $error    = $self->error;
    my $input    = $self->input;
    my $project  = $self->project;
    my $initial  = $self->initialdir;
    my $opsys    = $self->opsys;
    my $hosts    = $self->hosts;
    my $memory   = $self->memory;
    my $pass_through = $self->pass_through;
    my $output   = $self->output;
    my $priority = $self->priority;
    my $times    = $self->times;
    my $length   = $self->length;
    my $getenv   = $self->getenv;
    my $email    = $self->email;
    my @ids      = $self->ids();
    my $name     = $self->name;
    my $class     = $self->class;
    my $runtime   = $self->runtime;
    my $evictable = $self->evictable;

    my $xml = "";
    my $handle = IO::Scalar->new(\$xml);

    my $w= XML::Writer->new( OUTPUT => $handle,
                             DATA_MODE => 1,
                             DATA_INDENT => 4
                           );

    $w->startTag('command', 'type' => $cmd_type);
    $w->dataElement('executable', $exe);
    $w->dataElement('project', $project );
    $w->dataElement('username', getpwuid($<));
    foreach my $id (@ids) { 
        $w->dataElement('id', $id );
    }
    $w->startTag('config');
    
    $logger->debug("XML :  Opsys is $opsys \n");
    $w->dataElement("opSys", $opsys) if (defined $opsys);
    $w->dataElement("class", $class) if (defined($class));
    $w->dataElement("hosts", $hosts) if (defined($hosts) && ($hosts ne ""));
    $w->dataElement("memory", $memory) if defined($memory);
    $w->dataElement("passThrough", $pass_through) if (defined($pass_through) && ($pass_through ne ""));

    # getenv and length are are not mandatory in the config block.
    # Check if they are defined before writing any XML for them.
    $w->dataElement('getenv', $getenv) if defined($getenv);
    $w->dataElement('length', $length) if (defined($length) && ($length ne ""));
    $w->dataElement('evictable', $evictable) if (defined($evictable));
    $w->dataElement('runningTime', $runtime) if (defined($runtime));
					   
    $w->endTag('config');


    # Several fields are are not required. Check if they are defined
    # before writing any XML for them.
    $w->dataElement('email', $email) if (defined($email) && ($email ne ""));
    $w->dataElement('name', $name) if defined($name);
    $w->dataElement('times', $times) if defined($times);
    
    # Command Param block.
    my @params = $self->params;
    if (@params) {
        $logger->info("Coding params into XML document.");
        foreach my $ref (@params) {
            $w->startTag('param', 'type' => $ref->{type} );
            if ( exists($ref->{key}) && defined($ref->{key}) ) {
                $w->dataElement('key', $ref->{key});
            }
            $w->dataElement('value', $ref->{value});
            $w->endTag('param');
        }
    } else {
        $logger->info("No params provided.");
    }
    
    $w->dataElement('initialDir', $initial) if (defined($initial)  && ($initial ne ""));
    $w->dataElement('output', $output) if (defined($output)  && ($output ne ""));
    $w->dataElement('error', $error) if (defined($error)  && ($error ne ""));
    $w->dataElement('input', $input) if (defined($input)  && ($input ne ""));

    # Close the XML document.
    $w->endTag('command');
    $w->end();
    $handle->close;

    return $xml;
}


sub _write_temp_array_file {
    $logger->debug("In _write_temp_array_file.");
    my ($self, $arrayref) = @_;
    # To aid in tracking down problems, we are going to use the hostname to
    # of the machine making the requests to name our temporary file.
    require Sys::Hostname;
    # Get the temporary file location. This was probably set by the enclosing
    # Request object when add_param was invoked.
    my $tempdir = $self->tempdir();
    $logger->debug("Temporary directory: $tempdir.");
    unless ( -d $tempdir ) {
        $logger->warn("$tempdir does not seem to exist as a directory.");
        # The directory does not seem to exist. Attempt to create it.
        if ( -f $tempdir ) {
            $logger->logcroak("Configured temp directory is a file!");
        }
        $logger->debug("Attempting to make the temp directory.");
        require File::Path;
        File::Path::mkpath($tempdir) or
            $logger->logcroak("Temp dir $tempdir, does not exist and could ",
                              "not be created.");
    }
    my $template = Sys::Hostname::ghname() . "-perl_client-XXXXXXXXX";
    # Since we are requesting the filename, the default behavior is for
    # the file to remain after the process has exited. This is what we
    # want, because the server side will need access to the file.
    my ($fh, $filename) = tempfile($template, DIR => $tempdir);
    if ( ref($arrayref) ne "ARRAY" ) {
        $logger->logcroak("When specifying ARRAY as the type, the VALUE must ",
                          "be an array reference.");
    }
    $logger->debug("Writing elements into the temporary file: $filename.");
    foreach my $element (@$arrayref) {
        $element =~ s/\n//g;
        print $fh "$element\n";
    }
    chmod 0666, $filename;
    close $fh or
        $logger->logcroak("Could not close temporary file filehandle.");
    return $filename;
}

1;

__END__

=back

=head1 ENVIRONMENT

This module does not read or set any environment variables. However, if the
getenv attribute is set, the user environment is replicated to the compute
node before the executable is invoked.

=head1 DIAGNOSTICS

=over 4

=item "Mandatory 'project' attribute not provided."

The project attribute is mandatory when creating a Command object.

=item "When specifying ARRAY as the type, the VALUE must be an array reference."

An attempt was made to pass something other than an array reference as
a VALUE when using a type of "ARRAY". When using "ARRAY", the add_param
method assumes that "VALUE" contains an array reference. Adjust your call
to add_param() accordingly, and try again.

=item 'value' must be specified.

When using the add_param method with named arguments (by passing a hash
reference) the "value" key must be specified.

=item "Could not close temporary file filehandle."

The filehandle for a temporary file could not be closed.

=item "Temp dir I<tempdir>, does not exist and could not be created."

The configured location of the directory to contain temporary files does
not exist, and the system could not create it either. Check the filesystem
and permissions.

=back

=head1 BUGS

Description of known bugs (and any workarounds). Usually also includes an
invitation to send the author bug reports.

=head1 SEE ALSO

 File::Temp
 File::Path
 IO::Scalar
 Log::Log4perl
 Sys::Hostname
 XML::Writer
