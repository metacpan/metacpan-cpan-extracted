#================================ Logger.pm ==================================
# Filename:             Logger.pm
# Description:          A fault handling logger
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:20:19 $ 
# Version:              $Revision: 1.12 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
# NOTE  * Care must be taken that no matter what user API call is used
#	  first, LOGGER is initialized and the local $self or $s value is
#         set to that. I do this by always calling _getargs before using
#	  self as an object pointer.
#
#       * Every logging routine will call the internal method 
#	  Fault::Logger->_log as the last thing it does, one way or the
#	  other. That is why it handles the update of the internal pointer
#	  to the last message actually logged.
#
#=============================================================================
use strict;
use POSIX;
use Fault::Delegate::Stdout;
use Fault::Delegate::Stderr;
use Fault::Delegate::List;
use Fault::Msg;

package Fault::Logger;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================
my $LOGGER  = undef;
my %once    = ();

sub new {
    my ($class,@l)         = @_;
    $LOGGER || ($LOGGER    = bless {}, $class);
    @l      || (@l         = (Fault::Delegate::Stderr->new));
    $LOGGER->{'message'}   = undef;
    %once                  = ();
    $LOGGER->{'delegates'} = Fault::Delegate::List->new (@l);
    return $LOGGER;
}

#------------------------------------------------------------------------------

sub delegates     ($)   {my $s=shift;     $LOGGER || $s->new; 
			 $LOGGER->{'delegates'}->delegates;}

sub add_delegates ($@)  {my ($s,@l) = @_; $LOGGER || $s->new;
			 $LOGGER->{'delegates'}->add (@l);}

sub message       ($)   {$LOGGER || shift->new; 
			 defined $LOGGER->{'message'} || return "";
			 return $LOGGER->{'message'}->msg;}

sub clr_log_once  ($)   {%once = ();}
sub clr_message   ($)   {$LOGGER || shift->new; $LOGGER->{'message'} = undef;}

#=============================================================================
#                      Bottom level logging methods
#=============================================================================

sub log ($;$$$$@) {
    my ($s,$msg,@rest) = _getargs(@_);
    $s->_log ($msg,@rest);
}

#------------------------------------------------------------------------------

sub crash ($;$$$$@) {
    my ($s,$msg,@rest) = _getargs(@_);

    $msg->set_prefix ("Fatal error");
    $s->_log         ($msg, @rest);
    die              ($msg->msg);
}

#------------------------------------------------------------------------------

sub log_once ($;$$$$@) {
    my ($s,$msg,@args) = _getargs(@_); 
    $s->_oneshot($msg,@args);
}

#=============================================================================
#                      Specialized logging methods
#=============================================================================

sub fault_check ($$;$$$$$@) {
    my ($self,$c,$tag,@args) = @_;
    my ($s,$msg,@rest)   = _getargs($self,@args);
    $c                   = ($c) ? 1 : 0;

    $msg->set_tag($tag);
    $s->_dflop ($c,$msg,@rest);
    return !$c;
}

#------------------------------------------------------------------------------

sub assertion_check ($$;$$$$$@) {
    my ($self,$c,$tag,@args) = @_;
    my ($s,$msg,@rest)   = _getargs($self,@args);
    $c                   = ($c) ? 1 : 0;

    $msg->set_tag($tag);

    $s->_log($msg,@rest) if $c;
    return !$c;
}

#==============================================================================
# Bug check call sequence differs from all other calls and this could cause
# confusion. 

sub bug_check ($$;$$$$@) {
    my ($self,$c,$m,@args) = @_;
    my ($s,$msg,@rest)     = _getargs($self,$m,'BUG','err',@args);
    $c                     = ($c) ? 1 : 0;

    $msg->set_tag($s->_get_tag);
    $s->_dflop ($c,$msg,@rest);
    return !$c;
}

#==============================================================================
#                    Argument check logging methods
#=============================================================================

sub arg_check_isalnum ($$$;$$$@) {
    my ($self,$v,$n,@args)    = @_;
    my ($m,$c)                = ("",1);
    $n                        = Fault::Logger->_validate_varname ($n);

    if    (!defined $v)        {$m = "\'$n\' is undefined.";}
    elsif (ref $v)             {$m = "\'$n\' should not be a pointer.";}
    elsif (!POSIX::isalnum $v) {$m = "\'$n\' contains non alphanumeric characters: \'$v\'.";}
    else                       {$c = 0;}

    my ($s,$msg,@rest)        = _getargs($self,$m,@args);
    $msg->set_tag($s->_get_tag);

    $s->_log($msg,@rest) if $c;
    return !$c;
}

#------------------------------------------------------------------------------

sub arg_check_isdigit ($$$;$$$@) {
    my ($self,$v,$n,@args)    = @_;
    my ($m,$c)                = ("",1);
    $n                        = Fault::Logger->_validate_varname ($n);

    if    (!defined $v)        {$m = "\'$n\' is undefined.";}
    elsif (ref $v)             {$m = "\'$n\' should not be a pointer.";}
    elsif (!POSIX::isdigit $v) {$m = "\'$n\' contains non digit characters: \'$v\'.";}
    else                       {$c = 0;}

    my ($s,$msg,@rest)        = _getargs($self,$m,@args);
    $msg->set_tag($s->_get_tag);

    $s->_log($msg,@rest) if $c;
    return !$c;
}

#------------------------------------------------------------------------------

sub arg_check_noref ($$$;$$$@) {
    my ($self,$v,$n,@args)    = @_;
    my ($m,$c)                = ("",1);
    $n                        = Fault::Logger->_validate_varname ($n);

    if    (!defined $v)        {$m = "\'$n\' is undefined.";}
    elsif (ref $v)             {$m = "\'$n\' should not be a pointer.";}
    else                       {$c = 0;}

    my ($s,$msg,@rest)        = _getargs($self,$m,@args);
    $msg->set_tag($s->_get_tag);

    $s->_log($msg,@rest) if $c;
    return !$c;
}

#------------------------------------------------------------------------------
my %refs = ('REF'=>1,'SCALAR'=>1,'ARRAY'=>1,'HASH'=>1,'CODE'=>1,'GLOB'=>1);

sub arg_check_isa ($$$$;$$$@) {
    my ($self,$v,$class,$n,@args) = @_;
    my ($m,$c)                    = ("",1);
    $n                            = Fault::Logger->_validate_varname   ($n);
    $class                        = Fault::Logger->_validate_classname ($class);

    if    (!defined $v)            {$m = "\'$n\' is undefined.";}
    elsif (!ref $v)                {$m = "\'$n\' is not a reference.";}
    else  {
	if (defined $refs{ref $v}) {
	    if (ref $v ne $class)  {$m = "\'$n\' is not a $class.";}
	    else                   {$c = 0;}
	}
	elsif (!$v->isa($class))   {$m = "\'$n\' is not a $class.";}
	else                       {$c = 0;}}

    my ($s,$msg,@rest)        = _getargs($self,$m,@args);
    $msg->set_tag($s->_get_tag);

    $s->_log($msg,@rest) if $c;
    return !$c;
}

#=============================================================================
#			Internal Methods
#=============================================================================
# Handle 'edge-triggered' logging.

sub _dflop ($$$;$$$@) {
    my ($s,$c,$msg,@rest)     = @_;
    
    my $list  = $s->{'delegates'};
    my $prev  = $list->fault_exists($msg);
    my $cur   = ($c)                ? 1 : 0;
    my $state = ($prev<<1) + $cur;
    my $chng  = 0;
    
  SWITCH: {
      if ($state == 0) {$list->trans00($msg,@rest);        last;}
      
      if ($state == 1) {$chng = 1;
			$list->trans01($msg,@rest);
			$msg->set_prefix("FAULT  RAISED"); last;}
      
      if ($state == 2) {$chng = 1;
			$list->trans10($msg,@rest); 
			$msg->set_prefix("FAULT CLEARED"); last;}
      
      if ($state == 3) {$list->trans11($msg,@rest);        last;}
  }
    
    $s->_log ($msg,@rest) if ($chng);
    return !$c;
}

#------------------------------------------------------------------------------
# Handle 'one-shot' logging.

sub _oneshot ($$;$$$@) {
    my ($s,$msg,@rest) = @_;
    !$once{$msg->msg} ||  (return 0);
    $once{$msg->msg}   = 1;
    $s->_log ($msg,@rest);
    return 1;
}

#------------------------------------------------------------------------------
#               Internal validation and convenience methods
#------------------------------------------------------------------------------
# Log a message unconditionally. This routine updates the pointer to the
# last message object logged.

sub _log ($$@) {
    my ($s,$msg,@rest) = @_;
    $s->{'message'}    = $msg;
    $s->{'delegates'}->log ($msg,@rest);
}

#------------------------------------------------------------------------------
sub _get_tag {
    my $self = shift;
    my $tag;
    my ($package, $filename, $line, $subroutine) = caller(2);
    if (defined $subroutine) {
	my @name  = split '::',$subroutine;
	my $mname = pop @name; 
	my $cname = join '::', @name;
	$tag      = ($cname) ? "[$cname->$mname()]" : $mname;
    }
    elsif (defined $package)  {$tag = "[$package]";}
    elsif (defined $filename) {$tag = "[$filename]";}
    else                      {$tag = "[Main]";}
    return "$tag ";
}

#------------------------------------------------------------------------------

sub _getargs ($;$$$@) {
    my ($s,$m,$t,$p,@rest) = @_;
    $LOGGER || $s->new;

    my $msg = Fault::Msg->new ($m,$t,$p);

    if ($msg->is_blank) {
	my $tag = $LOGGER->_get_tag;
	$msg->set_msg ("${tag}No message argument");
    }
    return ($LOGGER,$msg,@rest);
}

#------------------------------------------------------------------------------

sub _validate_varname ($@) {
    my ($s,$n) = @_;

    if    (!defined $n )            {$n = "Unnamed variable";}
    elsif (ref $n    )              {$n = "Invalid variable name (Pointer)";}
    elsif (!POSIX::isprint $n)      {$n = "Invalid variable name " . 
                                          "(Not printable)";}
    return ucfirst $n;
}

#------------------------------------------------------------------------------

sub _validate_classname ($@) {
    my ($s,$class) = @_;

    if    (!defined $class )        {$class = 'HASH';}
    elsif (ref $class)              {$class = 
					 'FaultyClassname-CannotBeAPointer';
				     Fault::ErrorHandler->warn 
					 ("Class cannot be a pointer.");}
    elsif (!POSIX::isprint $class)  {Fault::ErrorHandler->warn
				     ("Class contains non-printable char: " .
				      "\'$class\'.");
				     $class = 
					 'FaultyClassname-Unprintable';}
    return $class;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 Fault::Logger - A message logger proxy.

=head1 SYNOPSIS

 use Fault::Logger;
 $proxy        = Fault::Logger->new (@delegates);
 $proxy        = Fault::Logger->new;
 @delegates    = Fault::Logger->delegates;
 @delegates    = $proxy->delegates;
 $one          = Fault::Logger->add_delegates (@delegates);
 $one          = $proxy->add_delegates (@delegates);

 $msg          = Fault::Logger->message;
 $msg          = $proxy->message;
                 Fault::Logger->clr_message;
                 $proxy->clr_message;

                 Fault::Logger->clr_log_once;
                 $proxy->clr_log_once;

 $didlog       = Fault::Logger->log               ($m,$t,$p,$o,@rest);
 $didlog       = $proxy->log                      ($m,$t,$p,$o,@rest);
                 Fault::Logger->crash             ($m,$t,$p,$o,@rest);
                 $proxy->crash                    ($m,$t,$p,$o,@rest);
 $firsttime    = Fault::Logger->log_once          ($m,$t,$p,$o,@rest);
 $firsttime    = $proxy->log_once                 ($m,$t,$p,$o,@rest);

 $notfault     = Fault::Logger->fault_check       ($c,$tag,$m,$t,$p,$o,@rest);
 $notfault     = $proxy->fault_check              ($c,$tag,$m,$t,$p,$o,@rest);
 $notfault     = Fault::Logger->assertion_check   ($c,$tag,$m,$t,$p,$o,@rest);
 $notfault     = $proxy->assertion_check          ($c,$tag,$m,$t,$p,$o,@rest);

 $notfault     = Fault::Logger->arg_check_isalnum ($v,$varname,$t,$p,$o,@rest);
 $notfault     = $proxy->arg_check_isalnum        ($v,$varname,$t,$p,$o,@rest);

 $notfault     = Fault::Logger->arg_check_isdigit ($v,$varname,$t,$p,$o,@rest);
 $notfault     = $proxy->arg_check_isdigit        ($v,$varname,$t,$p,$o,@rest);

 $notfault     = Fault::Logger->arg_check_noref   ($v,$varname,$t,$p,$o,@rest);
 $notfault     = $proxy->arg_check_noref          ($v,$varname,$t,$p,$o,@rest);

 $notfault     = Fault::Logger->arg_check_isa ($v,$class,$varname,$t,$p,$o,@rest);
 $notfault     = $proxy->arg_check_isa        ($v,$class,$varname,$t,$p,$o,@rest);

 $notfault     = Fault::Logger->bug_check         ($c,$m,$t,$p,$o,@rest);
 $notfault     = $proxy->bug_check                ($c,$m,$t,$p,$o,@rest);

=head1 Inheritance

 Base Class

=head1 Description

This Class does not have instance objects, only a single 'Class Object'. As 
it may be referenced by class name, it is very easy for code at any level or 
location within a system to find it and thus send messages to a central 
logging point. The actual logging is handled by a user specified and easily 
changed list of delegates so the logging behavior and destinations of your 
entire program is modifiable at run-time. 

Since the actual logging is handled by a user delegate, you may ask, then 
what is the point of Logger? Logger is a controller. It provides the structure 
within which more sophisticated logging may be done. 

Defaulting is central to the philosophy of the design. A mistake in the 
args to your rarely used log or fault call should not prevent at least 
I<something> from being printed to let you know something happened. Crashing
is not an option.

Logger currently provides four different types of logging:

=head2 Simple logging

This is what most people have in mind. You call a routine, and it sends a 
message somewhere. What Logger adds to this most basic process is the ability 
to use different destinations in different part of your program or to mix and 
match them as you wish. If you provide a delegate that handles output to files,
you log to file; if it sets up syslog, you log the same message to syslog; if 
you set up a MySQL table then your delegate can log to that. All you need to
handle in your delegate code is the moving of a message from your input onto
one or more outputs. Logger passes through arguments unique to your delegate. 

The user's program must of course have write privileges to where their object
intends to log, whether it be file, syslog, database table or whatever.

Simple logging methods are log and crash.

=head2 Log once

There are times when you want to see if a particular condition happens, but 
you know that if it does it will recur at a high rate. The log_once method 
does just this. It keeps track of each string passed through it for logging
and if that string has already been seen it returns immediately without 
logging anything.

If you initialize the Logger via new it will also clear the list of logged 
messages kept up by log_once. You may also clear it with the clr_log_once 
method.

=head2 Conditional logging

It is quite often the case that you want to log a message every time some 
condition is true. This is the sort of thing which is done when you put 
diagnostic assertions into your code. You only want output if the assertion  
is true. For convenience we have assertion_check and a family of similar
methods. They embed the condition flag (or an entire expression) in the method
call so that you needn't construct a whole list of conditionals. In case 
you still require a conditional action, the subroutine returns the inverse 
of the value it tested. This will make it useful in common statements of 
the form: expression-a || expression-b.

=head2 Change of state logging

The most sophisticated use and one of the primary reasons for Logger is the 
management of 'edge-triggered' logging. The message text is used as a unique 
identifier. (It is thus not wise to do this sort of logging on messages with 
a non-repeatable component like the address of a variable). The full message 
is stored when first seen in conjunction with a true condition test; it is 
removed when the same text is seen with the condition test false. Changing 
from false to true causes the message to be logged as 'fault raised'; going 
from true to false logs a 'fault cleared' message.

The fault_check and bug_check methods are of this type.

There are also hooks supplied so that a user's delegate class may be called 
during initialization and at any or all transitions: false-false; false-true;
true-true; true-false. You probably would only be interested in the false-true
and true-false edge-transitions.

With this method you can construct systems to display and remove fault messages
in real time as conditions occur and are fixed.

All of the Logger methods accept and pass through a target object pointer as 
the second argument. This allows a calling object to pass a callback pointer 
to itself through the Logger to the delegate object. The delegate object is 
then free to communicate whatever it wishes with the object which declared the
error. It might write a copy of the log message into the target, or it might 
try to fix something. What happens is in the hands of the delegate writer. 
Logger only supplies the framework.

Logger also passes through a type argument in all calls, although it may be 
defaulted in most cases. To be truthful, this exists for my own database 
application, but it may be of use to others as well. It is intended to be used 
as a simple classifier of messages. 

The definition of type names are left (mostly) to the user to define and 
utilize. Currently Logger only demands one type be recognized: "BUG". You will 
see this in your delegate if you use bug_check or default the type argument 
in fault_check.

=head2 Logger delegate protocol

We have made much of delegates in the previous discussion. But exactly what 
is a delegate? How do you write one?

Most basically, a Logger delegate is any instance of a Class that accepts a 
method call of the form:

	$didlog = $delegate->log ($msg,$o,@rest)

Where $msg is the Fault::Msg object being processed by Logger; $o is a
callback pointer called the 'target', optionally passed in by the original 
caller of a Logger method; and @rest is any additional arguments which the 
Logger method received beyond those it uses itself. 

It should return $didlog true if $msg is successfully logged and false if it 
was not. In the examples below, the Simple class implements this most minimal
delegate.

This is a very useful capability. You can switch between using direct writes 
to logfiles to logging remotely, logging via a Unix socket to syslog, or even 
logging to a database table. The behavior is dependent on the capabilities of 
the delegate class passed to the Logger proxy.

In addition to the log method, delegates may define a number of other 
'callback' or 'hook' methods. In Objective C on NeXT computers this sort of 
thing is called a protocol.

The user may seed the fault table with an initial set of messages (perhaps 
ones previously saved in a database) by providing an initfaults method:

	@list = $delegate->initfaults

The list should be a simple list of fault messages

	("fault msg 1", "fault msg 2"...)
 
as previously captured via a trans01 method. The user may supply callbacks 
for any or all of the four possible fault transition states:

	$delegate->trans00 ($msg,$o,@rest)
	$delegate->trans01 ($msg,$o,@rest)
	$delegate->trans10 ($msg,$o,@rest)
	$delegate->trans11 ($msg,$o,@rest)

where $msg and $o are as described above and @rest are any private arguments 
the user passed into the logger call.

A method name will not be called unless it exists, so in most cases either none
of the above or only trans01 and trans10 need be defined. The return value is
not defined and will be ignored.

The meanings of the transitions are:

	00   No fault, no change.
	01   A new fault has occurred.
	10   An existing fault has cleared.
	11   Known fault, no change.

You may also wish to examine the code of the various Fault::Delegate 
classes provided as examples and a quick start.

=head2 Argument definitions

A number of arguments are standard and used in most of the callbacks defined
by this delegate.

=over 4
A message is a nearly arbitrary text string of arbitrary length. It should
not contain page formatting characters like formfeed, newline, etc. In practice
the length may be limited by the web server you are communicating with.

A Type is a single arbitrary capitalized word. You may add your own, but 
this is the required subset.

	BUG	For programming faults.
	DATA	Anything to do with file data or directories.
	SRV	Server operational issues, startup, login,
	        initializing. Hardware failures.
	NET	Failure to connect to a host, connectivity issues.
	NOTE	Reporting things of interest. Restarts, normal 
    		operational info. 
	other   The user may define any additional single word tags
                they desire and they will be treated equally to the
                required set.

If you use types not in this list, it is up to your web logger to accept
them. You must accept any of the default list, but what you do with them
or your own afterwards is up to you. Types help to categorize messages 
rather than define how important they are. You can have any 'type' of log 
messages reporting at any 'priority'. 

A priority must be one of the Unix syslog priorities:

        emerg   Off the scale.
    	alert	A major subsystem is unuseable. 
	crit	A critical subsystem is not working entirely.
	err	Bugs, bad data, files not found, things that went
 		bump in the night.
	warning	Something that should be attended to but that is not really
		an error.
	notice	The standard reports people want to read.
	info	Ordinarily unneeded chatter that is useful if
		trouble-shooting is needed after the fact.
        debug   Really boring diagnostic output.

If a subclass has no means of doing anything with priority, it may be left
out. All the arguments before it must be handled and if necessary defaulted
to reasonable values by a subclass. 

If you do specify a type but not a priority in an arg list, for whatever
reason, priority will default as follows:

	BUG	err
	DATA	warning
	SRV	warning
	NET	warning
	NOTE	info
	other   warning

If there is no type both arguments will default, resulting in type equal 
'BUG' and priority equal 'err'.

A target is an object reference. If present it is passed unexamined to the
subclass. A target could be used to return log state information to the 
site at which the log or fault occurred. 

As many additional subclass specific arguments as you wish may be added 
after the priority argument position in the calling sequences. They 
are passed straight through with no processing or checking.

=back 4

Besides these explicit arguments the delegate checks for the existence of
a global variable:

    $::PROCESS_NAME

If used, this should contain a single word name for your process. If the
process name contains spaces, use underscore as a replacement for them. For
example:

    $::PROCESS_NAME = "MyProcess";
    $::PROCESS_NAME = "My_Process";

If this global is undefined a default of "UnspecifiedProcess" is used as fault
processing depends upon it. Further, the value is retrieved in each method
just before use to cover the case of spawned processes whose names are
different from that of the parent process.

=head1 Examples

=head2 Example 1: Default everything

 use Fault::Logger;
 Fault::Logger->log ("test logging");

=head2 Example 2: Multiple delegates

 use Fault::Logger;
 use Fault::Delegate::Stdout;
 use Fault::Delegate::Stderr;
 use Fault::Delegate::Syslog;
 use Fault::Delegate::File;

 my $delegate1  = Fault::Delegate::Stdout->new;
 my $delegate2  = Fault::Delegate::Syslog->new;
 my $delegate3  = Fault::Delegate::File->new ("/tmp/test.log");

 my @delegates  = ($delegate1,$delegate2,$delegate3);
                  Fault::Logger->new         (@delegates);
                  Fault::Logger->log         ("test logging",'NOTE','warning');


=head2 Example 3: Fault monitoring

 use Fault::Logger;
 use Fault::Delegate::DB;

 # Works only if you have the Log and Fault Tables set up in mydbname. 
 # [see Fault::Delegate::DB]
 my $delegate1  = Fault::Delegate::DB->new (undef,"mydbname","user","passwd");
                  Fault::Logger->new       ($delegate1);

 # Set a fault
 my $fail      = 0;
 Fault::Logger->fault_check 
     (!defined $foo,"Optional tag","No foo!",'BUG','err') or return $fail;

 # Clear a fault
 my $foo       = 1;
 Fault::Logger->fault_check 
     (!defined $foo,"Optional tag","No foo!",'BUG','err') or return $fail;
    
[See example.pl for a bigger sample. It can be found either in eg/example.pl
in your Perl package or /var/share/doc/libfault-perl/example.pl if installed
from a debian package.]

=head1 Class  Variables

 delegates  An object which satisfies a minimal logger delegate protocol.
            It must at the very least implement the log method.
 message    The mostly recently logged message. the null string if cleared
            or there has been none since the logger was last initialized.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$proxy = Fault::Logger-E<gt>new (@delegates)>

=item B<$proxy = Fault::Logger-E<gt>new>

Initialize the logger proxy if it has never been called before and 
return a pointer to it in any case. There is only one logger object,
a class object, and further calls simply return the same pointer. It
can be accessed either by classname or the returned pointer.

By supplying a list of one or more delegate objects, you modify where and 
how your program will log and fault. The defaults is a Fault::Delegate::Stderr
object if no delegate is supplied the first time new is called. On any
subsequent calls, the default is to leave the delegate object as is.

Calling this routine re-initializes the logger object. it clears log once
entries, previous log delegates and the internal fault table. If 
the any of the new delegates have initfaults methods, they are used to 
retrieve any active faults. If the delegate has a method of keeping 
persistant data, programs can be stopped and started without forgetting 
about active faults.

=item B<$one = Fault::Logger-E<gt>add_delegates (@delegates)>

=item B<$one = $proxy-E<gt>add_delegates (@delegates)>

Add zero or more logger delegates. A delegate object is ignored if it
is already present.

=item B<$notfault = Fault::Logger-E<gt>arg_check_isa ($val,$class,$name,$type,$priority,$target,@rest)>

=item B<$notfault = $proxy-E<gt>arg_check_isa ($val,$class,$name,$type,$priority,$target,@rest)>

If the value $val of the variable named $name is undefined, is a not a
reference or is not a member of $class or one of its subclasses, log an
appropriate message. The message will contain the name of the subroutine or
class and method of the caller. Class defaults to 'HASH' if not present. 
Other values default as documented in the Argument Description section.

This method is useful for checking subroutine args.

=item B<$notfault = Fault::Logger-E<gt>arg_check_isalnum ($val,$name,$type,$priority,$target,@rest)>

=item B<$notfault = $proxy-E<gt>arg_check_isalnum ($val,$name,$type,$priority,$target,@rest)>

If the value $val of the variable named $name is undefined, is a reference or
contains a nonalphnumeric character, log an appropriate message. The message
will contain the name of the subroutine or class and method of the caller. Type
defaults to BUG if not present.

This method is useful for checking subroutine args.

=item B<$notfault = Fault::Logger-E<gt>arg_check_isdigit ($val,$name,$type,$priority,$target,@rest)>

=item B<$notfault = $proxy-E<gt>arg_check_isdigit ($val,$name,$type,$priority,$target,@rest)>

If the value $val of the variable named $name is undefined, is a reference or
contains a non digit characters log an appropriate message. The message will
contain the name of the subroutine or class and method of the caller. Type
defaults to BUG if not present.

This method is useful for checking subroutine args.

=item B<$notfault = Fault::Logger-E<gt>arg_check_noref ($val,$name,$type,$priority,$target,@rest)>

=item B<$notfault = $proxy-E<gt>arg_check_noref ($val,$name,$type,$priority,$target,@rest)>

If the value $val of the variable named $name is undefined or is a reference
or not alphanumeric, log an appropriate message. The message will contain the
name of the subroutine or class and method of the caller. Type defaults to BUG
if not present.

This method is useful for checking subroutine args.

=item B<$notfault = Fault::Logger-E<gt>assertion_check ($cond,$tag,$msg,$type,$priority,$target,@rest)>

=item B<$notfault = $proxy-E<gt>assertion_check ($cond,$tag,$msg,$type,$priority,$target,@rest)>

If the condition flag is true log the message. This is much like log except 
it encapsulates the condition test. This is useful if you want to log the 
testing of assertions sprinkled through your code. It does nothing if $cond 
is false or undefined.

=item B<$notfault = Fault::Logger-E<gt>bug_check ($cond,$msg,$target,@rest)>

=item B<$notfault = $proxy-E<gt>bug_check ($cond,$msg,$target,@rest)>

Set or clear a bug fault report. 

If $cond is defined and true, a fault defined by $tag and $msg is now active;
it is false or undefined, that fault is now inactive.

The return value is the inverse of $cond: it is true if there was no fault 
and false if there was. This makes the function useful in statements like:

	Fault::Logger->bug_check(@arglist) || (return undef);
or
	return Fault::Logger->bug_check(@arglist);

Note that your methods will always receive type equal "BUG" and a priority of
'err' from this method. So...

I<Beware. For convenience the calling sequence of this method differs from 
that of all the other methods. You have been warned.>

=item B<Fault::Logger-E<gt>clr_log_once>

=item B<$proxy-E<gt>clr_log_once>

Flush the 'log once' table. Doing this will allow those messages to be logged
again. Sometimes useful in debugging. I can imagine running it once a day
so as to see if some problems are still present or have gone away.

=item B<Fault::Logger-E<gt>clr_message>

=item B<$proxy-E<gt>clr_message>

Clear the most recently logged message by setting it to a null string.

=item B<Fault::Logger-E<gt>crash ($msg,$type,$priority,$target,@rest)>

=item B<$proxy-E<gt>crash ($msg,$type,$priority,$target,@rest)>

The message "Fatal error: $msg" is sent to the delegate and then calls die 
with the same message. 

=item B<@delegates = Fault::Logger-E<gt>delegates>

=item B<@delegates = $proxy-E<gt>delegates>

Return the list of logger delegates.

=item B<$notfault = Fault::Logger-E<gt>fault_check ($cond,$tag,$msg,$type,$priority,$target,@rest)>

=item B<$notfault = $proxy-E<gt>fault_check ($cond,$tag,$msg,$type,$priority,$target,@rest)>

This method provides 'edge triggered' fault handling. It should be called 
every time an action is taken, not just when there is an error. $cond is an 
expression which tests your fault condition, where true means fault and 
anything else means there is no fault condition. When a new fault arises, a 
message of the form:

 [FAULT    RAISED] $msg

will be printed. When $cond is next false with the same message, the fault is 
considered cleared:

 [FAULT CLEARED] $msg

This is useful for monitoring of systems as it can keep track of many unique 
fault conditions at a low level with very little code overhead in the user's 
program. As an example:

 Fault::Logger->fault_check
    (((-e $fn) ? 1 : 0),  $self,
    "Ignored: \"$fn\" already exists.",  "NOTE",
    @rest);

the condition expression may be anything which can be interpreted as a logical 
value:

 (!open ($fd,"<myfile"))

If $cond is defined and true, a fault defined by $tag and $msg is now active; 
it is false or undefined, that fault is now inactive.

=item B<$waslogged = Fault::Logger-E<gt>log ($msg,$type,$priority,$target,@rest)>

=item B<$waslogged = $proxy-E<gt>log ($msg,$type,$priority,$target,@rest)>

All arguments are sent to the delegate object via its log method and the 
return value of the delegate method is the return value here. If the message 
cannot be logged (the delegate returns false), the message is sent to a 
default logger and false is returned.

=item B<$firsttime = Fault::Logger-E<gt>log_once ($msg,$type,$priority,$target,@rest)>

=item B<$firsttime = $proxy-E<gt>log_once ($msg,$type,$priority,$target,@rest)>

Log a message if it has never appeared before; otherwise ignore it. Returns 
true if this is the first time; false in all other cases.

=item B<$msg = Fault::Logger-E<gt>message>

=item B<$msg = $proxy-E<gt>message>

Return the most recently logged message or else the null message if nothing 
has been logged yet or it has been explicitly cleared.

=back 4

=head1 Instance Methods

 None.

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::Delegate, Fault:Delegate::Stdout, Fault:Delegate::Stderr,
Fault:Delegate::File, Fault:Delegate::Syslog, Fault:Delegate::DB, 
Fault:Delegate::SimpleHttp, Fault::Delegate::List

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Logger.pm,v $
# Revision 1.12  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.11  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.10  2008-07-24 21:17:24  amon
# Moved all todo notes to elsewhere; made Stderr the default delegate instead of Stdout.
#
# Revision 1.9  2008-07-23 22:32:51  amon
# chomp line ends in Msg class rather than fail unconditionally due to 
# POSIX::isprint.
#
# Revision 1.8  2008-05-10 15:19:44  amon
# Minor doc changes before release
#
# Revision 1.7  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.6  2008-05-08 20:22:50  amon
# Minor bug fixes; shifted fault table and initfault from Logger to List
#
# Revision 1.5  2008-05-07 19:22:05  amon
# Last major change set for this version.
#
# Revision 1.4  2008-05-05 19:25:49  amon
# Catch any small changes before implimenting major changes
#
# Revision 1.3  2008-05-04 14:38:46  amon
# Major rework of code and docs. First cut at multiple delegates and arg
# checking. Regularized call arg and return value lists.
#
# Revision 1.2  2008-05-03 00:36:01  amon
# Changed standard arg list. Also now defaults to Stdout delegate if none is 
# supplied.
#
# Revision 1.1.1.1  2008-05-02 16:32:30  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.8  2008-04-25 10:58:13  amon
# documentation changes
#
# Revision 1.7  2008-04-20 00:58:26  amon
# Added the arg_check-* method set
#
# Revision 1.6  2008-04-18 14:07:54  amon
# Minor documentation format changes
#
# Revision 1.5  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.4  2008-04-11 18:56:35  amon
# Fixed quoting problem with formfeeds.
#
# Revision 1.3  2008-04-11 18:39:15  amon
# Implimented new standard for headers and trailers.
#
# Revision 1.2  2008-04-10 15:01:08  amon
# Added license to headers, removed claim that the documentation section still
# relates to the old doc file.
#
# Revision 1.1.1.1  2006-09-09 18:15:14  amon
# Dale's library of primitives in Perl
#
# 20041130	Dale Amon <amon@vnl.com>
#		Almost a full rewrite over the last couple days. Added
#		caller callback arg; changed name of logfile method
#		to delegate; added more arg checking; split methods into
#		public and private parts and more. Also redocumented.
#
# 20041127	Dale Amon <amon@vnl.com>
#		Lots of additions. Added callback hooks for state
#		transitions and pass throughs for args needed by syslog
#		using LogFile objects.
#
# 20041013	Dale Amon <amon@vnl.com>
#		Added crash method and support for arglist pass through.
#
# 20040813	Dale Amon <amon@vnl.com>
#		Moved to DMA:: from Archivist::
#		to make it easier to enforce layers.
#
# 20030108	Dale Amon <amon@vnl.com>
#		Changed to allow subclassing; general tidying; fixed LogFile
#		class to return t/f as assert in our log method.
#
# 20030107	Dale Amon <amon@vnl.com>
#		Created.
#
# DONE	* Before I go public I should move the target variable to at least
#         before the type. I would have to change nearly all code I have
#	  written this decade to do so. Is it worth it? Perhaps do a full
#	  version split and grandfather the old ones? Perhaps rename the
#	  new one Logger instead of DMA::Logger? [DMA ?-20080502]
#	* Add the priority field to all calls as a standard arg.
#	  [DMA20080407-20080502]
#	* Move the target to the @rest arguments. [DMA20080407-20080502]
# 	* I should check that priority contains a valid priority, that
#         and type is a single word. get_*_args are a great place to do it
#	  once and for all if I can decided what to do with an wrong one.
#	  [DMA ?-20080503]
# 	* Expand delegate to a list to allow logging to multiple locations.
#	  If I do, should I make initfault do an or of tables or keep
#	  individual tables?  [DMA20080407-20080503]
#	* Update example.pl for multiple delegates.  [DMA20080503-20080504]
#	* replace warns with ErrorHandler calls where reasonable.
#	  [DMA20080503-20080505]
#	* _delegateExists operation so I can add only if new and delete
#	  only if it exists. Question is, what does exist mean? Stdout
#	  should only have one instance; probably same with DB; but what
#	  about multiple File delegates with different output files?
#	  (Created Delegate List class. [DMA20080503-20080506]
#	* I should use a hash instead of a list for delegates and treat
#	  them as handles. Stdout could be a class object if I am worried
#	  about multiple use of it.  [DMA20080503-20080506]
#	* Can I do anything more with commonalities in arg_check methods?
#	  (Nothing left that is worth the effort.) [DMA20080503-20080506]
#	* Make sure all delegates do their arg and failure checking.
#	  [DMA20080504-20080506]
#	* Should Delegate new be able to fail and return undef if a delegate
#	  cannot be initialized? (yes) [DMA ?-20080506]
#	* Check all use of $s as it might be the class name in some 
#	  circumstances and I have changed the flow such that it will now
#	  cause problems. [DMA20080506-20080607]
#	* Message is not being saved. (Now done in _log) 
#	  [DMA20080506-20080507]
#	* Carefully check all the documentation. [DMA20080506-20080507]
#	* When I add a new delegate, should I immediately do an initfault?
#	  (Yes. I am putting all of this in Fault::Delegate::List
#	  [DMA20080503-20080508]
1;
