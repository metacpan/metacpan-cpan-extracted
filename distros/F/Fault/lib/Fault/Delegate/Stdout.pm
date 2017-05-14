#================================ Stdout.pm ===================================
# Filename:             Stdout.pm
# Description:          Stdout print logger delegate.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-30 19:22:27 $ 
# Version:              $Revision: 1.7 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::DebugPrinter;
use Fault::Delegate;
use Fault::Msg;

package Fault::Delegate::Stdout;
use vars qw{@ISA};
@ISA = qw( Fault::Delegate );

#=============================================================================
#                      Family internal methods
#=============================================================================
# Warn is used here because if you can't even print to stdout you are probably
# effed so you might as well punt directly to Perl and see if it can do any 
# better!

sub _write ($$) {
    my ($self,$msg) = @_;    
    my $line        = $msg->stamped_log_line;

    if (!print "$line\n") {
	warn ("$0: Failed to log message to stdout: \'$line\'!\n");
	return 0;
    }
    return 1;
}

#-----------------------------------------------------------------------------
# Override so we only print annoying init message on the terminal if we are
# debugging.

sub test ($) {
  my $s = shift;
  (Fault::DebugPrinter->level > 0) ? $s->SUPER::test : 1;
}

#=============================================================================
#		      Primary Logger Callback Methods
#=============================================================================
# Utilizes Fault::Delegate parent methods with subclass overrides seen above.

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 Fault::Delegate::Stdout - Print logger delegate.

=head1 SYNOPSIS

 use Fault::Delegate::Stdout;
 $self = Fault::Delegate::Stdout->new;
 $okay = $self->log ($msg);
 $bool = $self->test;

=head1 Inheritance

 UNIVERSAL
   Fault::Delegate
     Fault::Delegate::Stdout

=head1 Description

This is a Logger delegate that writes all the log messages to stdout. It is
Logger's default delegate if no other is given. It is also a pretty good
one to start with when you are trying to understand how this system works.

It satisfies the absolute minimum requirements of the Fault::Delegate logger 
delegate protocol.

=head1 Examples

 use Fault::Delegate::Stdout;
 use Fault::Logger;
 use Fault::Msg;

 my $msg       = Fault::Msg                   ("Arf!");
 my $baz       = Fault::Delegate::Stdout->new ("/tmp/mylogfile");
 my $waslogged = $baz->log                    ($msg);

                 Fault::Logger->new           ($baz);
 my $waslogged = Fault::Logger->log           ("Bow! Wow!");

=head1 Instance Variables

None.

=head1 Class Methods

=over 4

=item B<$delegate = Fault::Delegate::Stdout-E<gt>new>

Create a logger delegate object that prints log messages to stdout. Prints
a warning message and returns undef on failure.

=back 4

=head1 Logger Protocol Instance Methods

=over 4

=item B<$okay = $self-E<gt>log ($msg)>

Print a time-stamped message to stdout using information
taken from Fault::Msg object $msg in the format:

      $date $time UTC> $process: $type($priority): $msg\n

for example:

      20021207 223010 UTC> MyProcess: NOTE(notice): Nothing happened today.\n

Return true if the message was printed.

=back 4

=head1 Private Class Methods

None.

=head1 Private Instance Methods

=over 4

=item B<$bool = $self-E<gt>test>

If the debug level has been set to at least one in Fault::DebugPrinter,
it executes the test method of the parent, Fault::Delegate class. Otherwise
it always returns true. This was added so that an annoying initial message
from the Fault system will not be printed on a terminal unless it is
actually wanted for debugging purposees.

=item B<$bool = $self-E<gt>test>

Executes a _connect, a log write and a _disconnect. It returns true if
this succeeds. This is useful in personalized subclass new methods.

=item B<$bool = $self-E<gt>_write ($msg)>

Impliments the above override to the internal family protocol utilized by 
the Fault:Delegate log and test methods.

=back 4

=head1 Errors and Warnings

Local warning messages are issued if the sys logger cannot be reached or has 
any problems whatever. 

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::Logger, Fault::Delegate, Fault::Msg

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Stdout.pm,v $
# Revision 1.7  2008-08-30 19:22:27  amon
# Prevent test method from printing to terminal unless debugging.
#
# Revision 1.6  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.5  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.4  2008-05-07 18:14:55  amon
# Simplification and standardization. Much more is inherited from 
# Fault::Delegate.
#
# Revision 1.3  2008-05-04 14:40:56  amon
# Updates to perl doc; dropped subclass new method..
#
# Revision 1.2  2008-05-03 00:56:57  amon
# Changed standard argument ordering.
#
# Revision 1.1.1.1  2008-05-02 16:36:35  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.7  2008-04-18 11:34:39  amon
# Wrote logger delegate abstract superclass to simplify the code in all the 
# delegate classes.
#
# Revision 1.6  2008-04-11 22:25:23  amon
# Add blank line after cut.
#
# Revision 1.5  2008-04-11 21:17:33  amon
# Removed my  = 0; my  = 1/; from log method. No idea why it was there as 
# is not used.
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
#		a very simple delegate that just prints.
1;
