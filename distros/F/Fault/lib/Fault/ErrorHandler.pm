#============================= ErrorHandler.pm ===============================
# Filename:             ErrorHandler.pm
# Description:          An error handler.
# Original Author:      Dale M. Amon
# Revised by:           $Author: amon $ 
# Date:                 $Date: 2008-08-28 23:20:19 $ 
# Version:              $Revision: 1.6 $
# License:		LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;

package Fault::ErrorHandler;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================
my $ERRORHANDLER = undef;

sub new {
  my ($class) = @_;
  $ERRORHANDLER || ($ERRORHANDLER = bless {}, $class);
  return $ERRORHANDLER;
}

#------------------------------------------------------------------------------

sub warn {
  my ($class,$msg) = @_;
  defined $msg  || ($msg = "<Null warning message>");
  chomp $msg;
  $ERRORHANDLER || $class->new;
  warn "$msg\n";
  return 1;
}

#------------------------------------------------------------------------------

sub die {
  my ($class,$msg) = @_;
  defined $msg  || ($msg = "<Null warning message>");
  chomp $msg;
  $ERRORHANDLER || $class->new;
  die "$msg\n";
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documentation section with the 'perldoc' cmd.

=head1 NAME

 Fault::ErrorHandler - A base error handler class.

=head1 SYNOPSIS

 use Fault::ErrorHandler;
 $class_object = Fault::ErrorHandler->new;
 $flg          = Fault::ErrorHandler->warn ($msg);
 $flg          = $class_object->warn       ($msg);
                 Fault::ErrorHandler->die  ($msg);
                 $class_object->die        ($msg);

=head1 Inheritance

 Base Class

=head1 Description

This Class does not have instance objects, only a single 'Class Object'. It 
is always referenced under the Class name. This makes it very easy for code 
at any level or location within a system to send error messages in a 
predetermined manner. While this particular class is just a cover for Perl 
warn and die, one could subclass it to do just about anything..

At the moment this class may seem trivial, however the intention is to add
code that will detect and use other methods of warn and die, such as Gtk
dialog panels, if they are present. I will impliment that when I find my
round tuit(*)

* Round tuits were invented by Paula Shubock of CMU in the early 1980's. The 
first was a yellow circle with a centered calligraphic 'tuit'!

=head1 Examples

 use Fault::ErrorHandler;
 my $classobj      = Fault::ErrorHandler->new;
 my $didwarn       = Fault::ErrorHandler->warn ("Dont do that!");
 my $didwarn       = $classobj->warn           ("Stop it!");
                     Fault::ErrorHandler->die  ("ARRRGGH!!!");
                     $classobj->die            ("R.I.P");
 
=head1 Instance Variables

None.

=head1 Class Methods

=over 4

=item B<$class_object = Fault::ErrorHandler-E<gt>new>

Generate the ErrorHandler object if it doesn't exist; otherwise just return 
the existing class object.

=item B<$flg = Fault::ErrorHandler-E<gt>warn ($msg)>

=item B<$flg = $class_object-E<gt>warn       ($msg)>

Issue the specified warning message and return true if successful. If there
is no message, it prints "<Null warning message>". 

=item B<Fault::ErrorHandler-E<gt>die ($msg)>

=item B<$class_object-E<gt>die       ($msg)>

Issue the specified die message and then commit hari-kari. If there is no 
message, it prints "<Null warning message>". 

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

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: ErrorHandler.pm,v $
# Revision 1.6  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.5  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.4  2008-05-09 18:24:55  amon
# Bugs and changes due to pre-release testing
#
# Revision 1.3  2008-05-07 17:43:05  amon
# Documentation changes
#
# Revision 1.2  2008-05-04 14:34:12  amon
# Tidied up code and docs.
#
# Revision 1.1.1.1  2008-05-02 16:34:37  amon
# Fault and Log System. Pared off of DMA base lib.
#
# Revision 1.7  2008-04-18 14:07:54  amon
# Minor documentation format changes
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
# Revision 1.1.1.1  2004-08-29 21:31:53  amon
# Dale's library of primitives in Perl
#
# 20040813	Dale Amon <amon@vnl.com>
#		Moved to DMA:: from Archivist::
#		to make it easier to enforce layers.
#
# 20030108	Dale Amon <amon@vnl.com>
#		Created.
1;
