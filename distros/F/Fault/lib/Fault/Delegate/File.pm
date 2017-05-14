#================================ File.pm ====================================
# Filename:             File.pm
# Description:          File logger delegate.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:20:19 $ 
# Version:              $Revision: 1.9 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Delegate;
use Fault::Msg;
use Fault::ErrorHandler;

package Fault::Delegate::File;
use vars qw{@ISA};
@ISA = qw( Fault::Delegate );

#=============================================================================
#                      Family internal methods
#=============================================================================

sub _write ($$) {
    my ($self,$msg) = @_;
    my $str         = $msg->stamped_log_line;
    my $fh          = $self->{'fd'};

    if (!print $fh ("$str\n")) {
	$self->warn 
	    ("Failed log write: \'$str\' to \'$self->{'filepath'}\': $!"); 
	  return 0;
      }
    return 1;
}

#-----------------------------------------------------------------------------

sub _connect ($) {
    my $self = shift;
    my $path = $self->{'filepath'};

    return 1 if (defined $self->{'fd'});

    if (!open ($self->{'fd'}, ">>$path")) {
	$self->warn ("Failed to open log file at \'$path\': $!"); 
	  return 0;
      }
    if (!$self->{'init'}) {
	my $msg = Fault::Msg->new
	    ("Initialized log file $self->{'filepath'}",'INFO','notice');
	$self->{'init'} = 1 if ($self->_write ($msg));
    }
    return 1;
}

#-----------------------------------------------------------------------------

sub _disconnect ($) {
    my ($self) = shift; 
    if ($self->{'fd'}) {close $self->{'fd'}; $self->{'fd'} = undef; }
    return 1;
}

#=============================================================================
#	                     CLASS METHODS
#=============================================================================

sub new ($$) {
    my ($class,$filepath) = @_;
    my $self              = bless {}, $class;

    if (!defined $filepath or (ref $filepath) or !POSIX::isprint $filepath) {
	$self->warn
	    ("Fail: filepath string is invalid or undefined!");
	return undef;
    }
    @$self{'filepath','init'} = ($filepath,0);

    return ($self->test) ? $self : undef;
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

 Fault::Delegate::File - File logger delegate.

=head1 SYNOPSIS

 use Fault::Delegate::File;
 $self = Fault::Delegate::File->new ($filepath);
 $okay = $self->log                 ($msg);

=head1 Inheritance

 UNIVERSAL
   Fault::Delegate
     Fault::Delegate::File

=head1 Description

This is a delegate that writes log messages to a specified file. The file must
be writeable to the calling program.

Fault::Delegate::File satisfies the minimum requirements of the 
Fault::Delegate logger delegate protocol.

=head1 Examples

 use Fault::Delegate::File;
 use Fault::Logger;
 use Fault::Msg;

 my $msg       = Fault::Msg                 ("Arf!");
 my $baz       = Fault::Delegate::File->new ("/tmp/mylogfile");
 my $waslogged = $baz->log                  ($msg);

                 Fault::Logger->new         ($baz);
 my $waslogged = Fault::Logger->log         ("Bow! Wow!");

 [See Fault::Logger for a detailed example.]

=head1 Instance Variables

 filepath	Full path to the log file.
 init           True if the log file has been successfully opened at
                least once.
 fd             Transient storage for filehandle.

=head1 Class Methods

=over 4

=item B<$delegate = Fault::Delegate::File-E<gt>new ($filepath)>

Create a logger delegate object that writes log messages to the designated
file. 

A warning is issued if there is no $filepath argument and in that case
undef is returned to indicate that a delegate could not be created.

If the initialization message cannot be written a warning is issued and 
undef is returned.

=back 4

=head1 Logger Protocol Instance Methods

=over 4

=item B<$okay = $self-E<gt>log ($msg)>

Prints a time-stamped message to the associated log file using information
taken from Fault::Msg object $msg:

       $date $time UTC> $processname: $type($priority): $msg\n

for example:

       20021207 223010 UTC> MyProcess: NOTE(notice): Nothing happened again.\n

and return true if we succeeded in doing so. 

=back 4

=head1 Private Class Methods

None.

=head1 Private Instance Methods

=over 4

=item B<$bool = $self-E<gt>_write ($msg)>

=item B<$bool = $self-E<gt>_connect>

=item B<$bool = $self-E<gt>_disconnect>

Impliments the above overrides to the internal family protocol utilized by 
the Fault:Delegate log and test methods.

=back 4

=head1 Errors and Warnings

Local warning messages are issued if the db file cannot be opened or has 
any problems whatever. 

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::Logger, Fault::Delegate, Fault::Msg,
Fault::ErrorHandler

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: File.pm,v $
# Revision 1.9  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.8  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.7  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.6  2008-05-08 20:22:50  amon
# Minor bug fixes; shifted fault table and initfault from Logger to List
#
# Revision 1.5  2008-05-07 18:14:55  amon
# Simplification and standardization. Much more is inherited from Fault::Delegate.
#
# Revision 1.4  2008-05-05 19:25:49  amon
# Catch any small changes before implimenting major changes
#
# Revision 1.3  2008-05-04 14:44:18  amon
# Updates to perl doc; minor code changes.
#
# Revision 1.2  2008-05-03 00:56:57  amon
# Changed standard argument ordering.
#
# Revision 1.1.1.1  2008-05-02 16:37:39  amon
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
#		a very simple delegate that prints to a file.
1;
