#============================= DebugPrinter.pm ===============================
# Filename:             DebugPrinter.pm
# Description:          A Debug print controller.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:20:19 $ 
# Version:              $Revision: 1.5 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;

package Fault::DebugPrinter;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================

my $DEBUGPRINTER = undef;

sub new {
    my ($class, $debug) = @_;
    $DEBUGPRINTER || ($DEBUGPRINTER = bless {}, $class);
    $DEBUGPRINTER->{'debug'} = (defined $debug) ? $debug : 0;
    return $DEBUGPRINTER;
}

#------------------------------------------------------------------------------

sub dbg1 {
    my ($class,$msg) = @_;
    defined $msg  || ($msg = "<Null diagnostic message>");
    chomp $msg;
    $DEBUGPRINTER || $class->new;
    if ($DEBUGPRINTER->{'debug'}) {print "$msg\n"; return 1;}
    return 0;
}

#------------------------------------------------------------------------------

sub dbg {
    my ($class,$lvl,$msg) = @_;
    defined $lvl  || ($lvl = 1);
    defined $msg  || ($msg = "<Null diagnostic message>");
    $DEBUGPRINTER || $class->new;
    $DEBUGPRINTER->{'debug'} >= $lvl || (return 0);
    return print "$msg\n"; 
}

#------------------------------------------------------------------------------

sub level {
    my ($class,$v) = @_;
    $DEBUGPRINTER || $class->new;
    defined $v    || (return $DEBUGPRINTER->{'debug'}); 
    return $DEBUGPRINTER->{'debug'} = $v; 
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 Fault::DebugPrinter - A Debug print controller with levels.

=head1 SYNOPSIS

 use Fault::DebugPrinter;
 $class_object = Fault::DebugPrinter->new   ($level);
 $class_object = $class_object->new         ($level);
 $class_object = Fault::DebugPrinter->new;
 $class_object = $class_object->new;
 $didprint     = Fault::DebugPrinter->dbg1  ($msg);
 $didprint     = $class_object->dbg1        ($msg);
 $didprint     = Fault::DebugPrinter->dbg   ($level,$msg);
 $didprint     = $class_object->dbg         ($level,$msg);
 $curlvl       = Fault::DebugPrinter->level ($level);
 $curlvl       = $class_object->level       ($level);
 $curlvl       = Fault::DebugPrinter->level;
 $curlvl       = $class_object->level;

=head1 Inheritance

 UNIVERSAL

=head1 Description

This Class does not have instance objects, only a single 'Class Object'. It 
is always referenced under the Class name. It supplies a simple mechanism for 
run time selection of how much Diagnostic message detail will be displayed. 
By setting the level to zero, all Diagnostic printouts are disabled. It can 
be used either in a mode that emulates a simple enable/disable of diagnostics
or with multiple levels with more and more detail printed at each higher 
level. It is entirely at the user's discretion.

=head1 Examples

 use Fault::DebugPrinter;
 my $classobj      = Fault::DebugPrinter->new (1);

 my $didprint      = Fault::DebugPrinter->dbg1  ("This will print");
    $didprint      = Fault::DebugPrinter->dbg   (2, "This will not");

 my $curlvl        = Fault::DebugPrinter->level;
    $curlvl        = $classobj->level           ($curlvl+1); 
    $didprint      = Fault::DebugPrinter->dbg   (2, "This will now");

    $classobj      = Fault::DebugPrinter->new;
    $didprint      = Fault::DebugPrinter->dbg1  ("This is Disabled.");
    $curlvl        = Fault::DebugPrinter->level (1);
    $didprint      = Fault::DebugPrinter->dbg1  ("This is Enabled.");

=head1 Class Variables

 level        Highest level of Diagnostic message that will be printed.

=head1 Class Methods

=over 4

=item B<$class_object = Fault::DebugPrinter-E<gt>new ($level)>

=item B<$class_object = $class_object-E<gt>new       ($level)>

=item B<$class_object = Fault::DebugPrinter-E<gt>new>

=item B<$class_object = $class_object-E<gt>new>

Generate the DebugPrinter object if it doesn't already exist; otherwise just 
return the existing class object.

$level will turn diagnostic printing on for messages with a debug level above
the specified it or off it is zero. If the argument is not present or undef 
the current level is set to zero so that, diagnostic printing is disabled.

=item B<$didprint = Fault::DebugPrinter-E<gt>dbg1 ($msg)>

=item B<$didprint = $class_object-E<gt>dbg1       ($msg)>

Single argument Diagnostic printer method. It prints $msg to stdout and 
returns true if the current debug level is greater than zero. If the $msg 
argument was missing or undef, it prints "<Null diagnostic message>" so you 
at least know it tried.

=item B<$didprint = Fault::DebugPrinter-E<gt>dbg ($level,$msg)>

=item B<$didprint = $class_object-E<gt>dbg       ($level,$msg)>

Dual argument Diagnostic printer method. It prints $msg to stdout and returns
true if the current debug level is greater than zero and at least equal to the 
integer value contained in $level. If the $level argument is missing or undef,
it is defaulted to Level 1. If the $msg argument was missing or undef, it 
prints "<Null diagnostic message>" so you at least know it tried.

=item B<$curlvl = Fault::DebugPrinter-E<gt>level ($level)>

=item B<$curlvl = $class_object-E<gt>level       ($level)>

=item B<$curlvl = Fault::DebugPrinter-E<gt>level>

=item B<$curlvl = $class_object-E<gt>level>

Set the current diagnostic level to $level. If the $level argument is 
missing or undef, the current level is unchanged.  The no-argument format 
thus doubles as a 'read current diagnostic level' command.

=back 4

=head1 Instance Methods

 None

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: DebugPrinter.pm,v $
# Revision 1.5  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.4  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.3  2008-05-07 17:43:05  amon
# Documentation changes
#
# Revision 1.2  2008-05-04 14:34:12  amon
# Tidied up code and docs.
#
# Revision 1.1.1.1  2008-05-02 16:35:05  amon
# Fault and Log System. Pared off of DMA base lib.
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
# Revision 1.1.1.1  2004-08-30 01:14:44  amon
# Dale's library of primitives in Perl
#
# 20040813	Dale Amon <amon@vnl.com>
#		Moved to DMA:: from Archivist::
#		to make it easier to enforce layers.
#
# 20030108	Dale Amon <amon@vnl.com>
#		Created.
1;
