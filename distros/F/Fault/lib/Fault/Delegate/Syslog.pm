#================================ Syslog.pm ==================================
# Filename:             Syslog.pm
# Description:          Syslog logger delegate.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:20:19 $ 
# Version:              $Revision: 1.9 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Sys::Syslog;
use Fault::Delegate;
use Fault::ErrorHandler;
use Fault::Msg;

package Fault::Delegate::Syslog;
use vars qw{@ISA};
@ISA = qw( Fault::Delegate );

#=============================================================================
#                      Family internal methods
#=============================================================================

sub _write ($$) {
    my ($self, $msg) = @_;
    my $m            = $msg->unstamped_log_line;

    if (!Sys::Syslog::syslog ($msg->priority, $m)) {
	($self->warn ("Failed log write: \'$m\' to syslog!")); return 0;}
    return 1;
}

#-----------------------------------------------------------------------------

sub _connect ($) {
    my $self = shift;
    if (!$self->{'init'}) {
	if (!Sys::Syslog::openlog ("", 'cons,ndelay,pid,perror,user','user')) {
	    return 0;
	}
	my $msg = Fault::Msg->new ("Initialized syslog",'INFO','notice');
	$self->{'init'} = 1 if ($self->_write ($msg));
    }
    return 1;
}

#=============================================================================
#		      Logger Delegate Protocol
#=============================================================================
# Utilizes Fault::Delegate parent methods with subclass overrides seen above.

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 Fault::Delegate::Syslog - Syslog delegate.

=head1 SYNOPSIS

 use Fault::Delegate::Syslog;
 $self = Fault::Delegate::Syslog->new;
 $okay = $self->log ($msg);

=head1 Inheritance

 UNIVERSAL
   Fault::Delegate
     Fault::Delegate::Syslog

=head1 Description

This is a delegate that writes log messages to the syslog. Syslogging must be
accessible to the calling program. 

Fault::Delegate::Syslog satisfies the minimum requirements of the
Fault::Delegate logger delegate protocol.

=head1 Examples

 use Fault::Delegate::Syslog;
 use Fault::Msg;
 use Fault::Logger;

 my $msg       = Fault::Msg                   ("Arf!");
 my $baz       = Fault::Delegate::Syslog->new;
 my $waslogged = $baz->log                    ($msg);

                 Fault::Logger->new           ($baz);
 my $waslogged = Fault::Logger->log           ("Bow! Wow!");

 [See Fault::Logger for a detailed example.]

=head1 Instance Variables

 init     True if a syslog connection was succesfully initialized.

=head1 Class Methods

=over 4

=item B<$delegate = Fault::Delegate::Syslog-E<gt>new>

Create a logger delegate object that writes log messages to syslog.
A warning is issued if the program cannot initialize and write a startup
message to syslog.

Returns undef if it fails to set up the syslog connection.

=back 4

=head1 Logger Protocol Instance Methods

=over 4

=item B<$didlog = $self-E<gt>log ($msgobj)>

Send the information contained in $msgobj to syslog at the $priority contained
by it and return true if we succeeded in doing so. The message is formatted 
so that it will appear in the log like this:

 Apr 17 18:00:36 localhost UnspecifiedProcess[12638]: NOTE(notice): Testing syslogger again

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

=over 4

=item B<$bool = $self-E<gt>_write ($msg)>

=item B<$bool = $self-E<gt>_connect>

Impliments the above overrides to the internal family protocol utilized by 
the Fault:Delegate log and test methods.

=back 4

=head1 Errors and Warnings

Local warning messages are issued if the sys logger cannot be reached or has 
any problems whatever. 

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::Logger, Fault::Delegate, Fault::Msg, Sys::Syslog
Fault::ErrorHandler

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Syslog.pm,v $
# Revision 1.9  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.8  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.7  2008-07-24 21:17:24  amon
# Moved all todo notes to elsewhere; made Stderr the default delegate instead of Stdout.
#
# Revision 1.6  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.5  2008-05-07 18:14:55  amon
# Simplification and standardization. Much more is inherited from Fault::Delegate.
#
# Revision 1.4  2008-05-05 19:25:49  amon
# Catch any small changes before implimenting major changes
#
# Revision 1.3  2008-05-04 14:42:02  amon
# Updates to perl doc; dropped subclass new method..
#
# Revision 1.2  2008-05-03 00:56:57  amon
# Changed standard argument ordering.
#
# Revision 1.1.1.1  2008-05-02 16:36:01  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.6  2008-04-18 11:34:39  amon
# Wrote logger delegate abstract superclass to simplify the code in all the 
# delegate classes.
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
# 20041203      Dale Amon <amon@vnl.com>
#               Modified old Document::LogFile code into
#		a very simple delegate that prints to syslog.
#
1;
