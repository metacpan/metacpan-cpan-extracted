#============================== Delegate.pm ==================================
# Filename:  	       Delegate.pm
# Description:         Abstract Superclass for Logger Delegates.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:20:19 $ 
# Version:             $Revision: 1.8 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Msg;

package Fault::Delegate;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          INTERNAL METHODS
#=============================================================================
# Subclass may override.

sub _write      ($) {0;}
sub _connect    ($) {1;}
sub _disconnect ($) {1;}

#-----------------------------------------------------------------------------
# Subclass may use.

sub test ($) {
    my $s = shift;
    my $c = ref $s;
    my $v = 0;

    if ($s->_connect) {
	$v = $s->log(Fault::Msg->new("Initialized $c logger",'NOTE','info'));
    }
    if (!$v) {$s->warn("Failed to fully initialize $c logger");}
    $s->_disconnect;
    return $v;
}

#-----------------------------------------------------------------------------
# Subclass may use.

sub warn ($$) {
    my ($s,$m) = @_;
    my $p      = (defined $::PROCESS_NAME) ? $::PROCESS_NAME : $0;
    Fault::ErrorHandler->warn ("$p: $m\n");
}

#=============================================================================
#                            CLASS METHODS
#=============================================================================
# Subclass may override.

sub new ($) {
    my $class = shift;
    my $s     = bless {},$class; 

    return ($s->test) ? $s : undef;
}

#=============================================================================
#                          SUBCLASS MAY OVERRIDE
#=============================================================================
# Subclass may override.

sub log ($$) {
    my ($self,$msg) = @_;
    my $val         = 0;

    if ($self->_connect) {$val = $self->_write ($msg);}
    $self->_disconnect;
    return $val;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Fault::Delegate - Abstract superclass of all Delegates.

=head1 SYNOPSIS

 use Fault::Delegate::MyDelegate;
 $self = Fault::Delegate::MyDelegate->new;
 $bool = $self->log($msg);

 $bool = $self->test;
         $self->warn ("A warning message");

=head1 Inheritance

 UNIVERSAL
   Fault::Delegate

=head1 Description

This is an abstract superclass from which Logger delegate subclasses may
inherit common code.

A Logger delegate manages a a logging connection of some sort. It is not 
used directly by a user; it is passed to Fault::logger for use as a proxy 
by which output messages are printed, syslogged, placed in a database, sent 
to a web site or whatever else the delegate does.

By doing it this way, the logging behavior of the system may be changed at any 
time simply by changing the delegate. This could even be done 
dynamically, switching where log messages go at runtime.

=head1 Delegate Protocol

A delegate must at the very least impliment the log method to be considered
a delegate. Beyond that, if it is to impliment the fault protocol, it should
at least impliment the trans01 and trans10 methods and should if possible
also impliment the initfaults method.

If the delegate has any ivars of its own and must do any special 
initialization it will also need to override or inherit from the new
class method. The subclass is responsible for arg checking all of its args
to ensure they exist if required and are precisely the correct type if
found. This requirement applies only to the new method since it is the only
part of the delegate protocal that is directly exposed to the user. All other
methods are called only via Fault::Logger, which does all of the arg checking
and defaulting before calling a subclass method.

If the delegate has no private arguments, @rest can be ignored; if it does
not use the $target that can also be ignored. If $target is used, it is a
subclass responsibility to make sure it is not undef, not a scalar and
is a member of an acceptable class. 

The $msg object will always contain a message, type and priority. If one of 
them was missing from a Fault::Logger method call, reasonable defaults will 
have been generated before any subclass protocol methods were called. 
The subclass may ignore or modify them as it choses although it is recommend 
it either use them or as is or skip them unless there is a really good reason 
to override the values passed to it from the Logger object.

No delegate protocol method should ever allow a 'die' to occur. If it is
even concievably possible, the potentially offensive code should be 
protected by an eval statement. If the eval fails, the method should return
false.

Under no circumstance should a delegate make an 'up-call' to Fault::Logger.
This would have the potential to generate infinite loops. If local error
messages or diagnostics need to be generated, use warn or print if you
must and preferably Fault:;ErrorHandler or Fault::DebugPrinter if you can.

Any method which causes a line to be printed to screen or file should
use the Fault::Msg object method $msg->stamped_log_line to generate a 
line like this:

 $date $time UTC> $process: $type($priority): $message

=over 4

=item B<$okay = Delegate::MyDelegate-E<gt>new (@rest)>

Subclass may override. It is the class constructor. The default method returns
an object of the calling class with no ivars. It should test its logger
connection to make sure it is functioning. If there are bad arguments or
the connection cannot be made, return undef.

=item B<@list = $self-E<gt>initfaults>

A subclass may impliment this method if it is able to recover persistant
fault table data from a previous program execution. It is a callback
used by Logger when it initializes it's in-memory fault table. If this
method is not implimented that table will be initialized as empty.

=item B<$okay = $self-E<gt>log ($msg,$target,@rest)>

=item B<$okay = $self-E<gt>log ($msg,$target)>

=item B<$okay = $self-E<gt>log ($msg)>

Subclass must override. It is the absolute minimum requirement for a delegate
class that it be able to accept a log message and do something with
it. 

It should return true if that something succeeded.

=item B<$zero = $self-E<gt>trans00 ($msg,$target,@rest)>

=item B<$zero = $self-E<gt>trans00 ($msg,$target)>

=item B<$zero = $self-E<gt>trans00 ($msg)>

A subclass may impliment this method if it wishes to do something every time
a fault clear occurs. It is called when a message clear occurs on a
message that is not in the fault table.

I have to this date never found a need for it but it is available for 
completeness.

It should always returns 0.

=item B<$zero = $self-E<gt>trans01 ($msg,$target,@rest)>

=item B<$zero = $self-E<gt>trans01 ($msg,$target)>

=item B<$zero = $self-E<gt>trans01 ($msg)>

A subclass may impliment this method if it wishes to do something the
first time a fault raise occurs. It is called when a fault raise occurs 
on a message that is not already in the fault table.

This method is part of the minimal subset required to impliment fault
handling.

It should always returns 0.

=item B<$zero = $self-E<gt>trans10 ($msg,$target,@rest)>

=item B<$zero = $self-E<gt>trans10 ($msg,$target)>

=item B<$zero = $self-E<gt>trans10 ($msg)>

A subclass may impliment this method if it wishes to do something the
first time a fault clear occurs. It is called when a faul clear occurs 
on a message that exists in the fault table.

This method is part of the minimal subset required to impliment fault
handling.

It should always returns 0.

=item B<$zero = $self-E<gt>trans11 ($msg,$target,@rest)>

=item B<$zero = $self-E<gt>trans11 ($msg,$target)>

=item B<$zero = $self-E<gt>trans11 ($msg)>

A subclass may impliment this method if it wishes to do something every time
a fault raise occurs. It is called when a message raise occurs on a
message that is already in the fault table.

I have to this date never found a need for it but it is available for 
completeness.

It should always returns 0.

=back 4

=head1 Examples

 None. This is an abstract class. You must use a subclass.

 [See Fault::Logger for a detailed example.]

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$self = Fault::Delegate::LogFile-E<gt>new>

Create a Delegate object. Classes without any args can inherit this class
as is. Others should override, but may use the low level family methods
to simplify coding.

=back 4

=head1 Instance Methods

=over 4

=item B<$self = Fault::Delegate::LogFile-E<gt>log($msg)>

Log a message using subclass provided overrides to the low level protocol. If
a subclass has only the $msg argument, this method can be used. If it must
deal with extra args, it will need to override this method but can use it
as a template.

It returns true if the message was logged successfully.

=back 4

=head1 Private Class Methods

=over 4

 None.

=back 4

=head1 Private Instance Methods

=over 4

=item B<$bool = $self-E<gt>_write ($msg)>

=item B<$bool = $self-E<gt>_connect>

=item B<$bool = $self-E<gt>_disconnect>

Impliments a noop internal family protocol which subclasses may override and
use if they wish to default most behavior to this parent class. Study the
code to understand how to use them.

=item B<$bool = $self-E<gt>test>

Executes a _connect, a log write and a _disconnect. It returns true if
this succeeds. This is useful in personalized subclass new methods.

=item B<$bool = $self-E<gt>warn($line)>

Issue a local warn output in a standardized format. Useful anywhere in
a subclass where errors are detected. If a subclass has an error it
probably cannot successfully log as it is supposed to so it should use
this as a fall back so there is a debug information available on the 
problem.

=back 4

=head1 Errors and Warnings

Local warning messages are printed if the logging mechanism cannot be reached
or has any problems whatever. You cannot log to a logger that is not working!

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 Fault::Logger

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Delegate.pm,v $
# Revision 1.8  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.7  2008-05-08 20:22:50  amon
# Minor bug fixes; shifted fault table and initfault from Logger to List
#
# Revision 1.6  2008-05-07 18:38:20  amon
# Documentation fixes.
#
# Revision 1.5  2008-05-07 18:30:13  amon
# Moved much more inheritable code up from subclasses. More docs.
#
# Revision 1.4  2008-05-05 19:25:49  amon
# Catch any small changes before implimenting major changes
#
# Revision 1.3  2008-05-04 14:36:44  amon
# Tidied up code and docs; get_log_args and get_fault_args reduced to getargs;
# beefed up new method and added _connect and _disconnect.
#
# Revision 1.2  2008-05-03 00:33:14  amon
# Changed standard arg list
#
# Revision 1.1.1.1  2008-05-02 16:58:40  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.3  2008-04-25 10:58:13  amon
# documentation changes
#
# Revision 1.2  2008-04-18 14:07:54  amon
# Minor documentation format changes
#
# Revision 1.1  2008-04-18 11:36:20  amon
# Wrote logger delegate abstract superclass to simplify the code in all the 
# delegate classes.
#
# 20080415 Dale Amon <amon@vnl.com>
#	   Created.
# DONE	* get_log_args and get_fault_args are now identical. Delete one?
#	  (yes. Just get_args instead.) [DMA20080503-20080504]
1;
