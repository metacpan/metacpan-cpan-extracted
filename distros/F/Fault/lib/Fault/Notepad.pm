#=============================== Notepad.pm ==================================
# Filename:  	       Notepad.pm
# Description:         A notepad for random text messages.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:20:19 $ 
# Version:             $Revision: 1.7 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Msg;
use Fault::Logger;

package Fault::Notepad;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub new ($) {
  my ($class)       = @_;
  my $self          = bless {}, $class;
  $self->{'notes'}  = [];
  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub add ($$) {
  my ($s,$n) = @_; 

  if ($::DEBUG) {Fault::Logger->arg_check_noref ($n,"Textline") or return $s;}

  push @{$s->{'notes'}}, Fault::Msg->new ($n,'NOTE','info');
  return $s;
}

#-----------------------------------------------------------------------------

sub addObject ($$) {
  my ($s,$msg) = @_; 

  if ($::DEBUG) {Fault::Logger->arg_check_isa ($msg,"Fault::Msg") 
      or return $s;}

  push @{$s->{'notes'}}, $msg;
  return $s;
}

#-----------------------------------------------------------------------------

sub merge ($$) {
  my ($s,$s2) = @_;

  if ($::DEBUG) {
    Fault::Logger->arg_check_isa ($s2,"Notepad","notepad2") or return $s;
  }
  push @{$s->{'notes'}}, @{$s2->{'notes'}};
  return $s;
}

#-----------------------------------------------------------------------------

sub count ($) {my ($s) = @_; $#{$s->{'notes'}}+1;}

sub print ($) {shift->fprint (*STDOUT);}

sub fprint ($\*) {
  my ($s,$fh) = @_; foreach (@{$s->{'notes'}}) {print $fh $_->msg . "\n";} $s;}

sub sprint ($) {
  my ($s) = @_; my $str=""; 
  foreach (@{$s->{'notes'}}) {$str .= sprintf $_->msg . "\n";} $str;}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Fault::Notepad - A notepad for random text messages.

=head1 SYNOPSIS

 use Fault::Notepad;
 $obj  = Fault::Notepad->new;
 $obj  = $obj->add       ($text);
 $obj  = $obj->addObject ($msg);
 $obj  = $obj->merge     ($obj2);
 $obj  = $obj->print;
 $cnt  = $obj->count;
 $obj  = $obj->fprint    ($fh);
 $str  = $obj->sprint;

=head1 Inheritance

 UNIVERSAL

=head1 Description

A notepad is a container for random text messages. Notes are added to a 
list in the sequence recieved and once written are not modifiable.

This is a very early form of the class and it does very little at present
other than append Fault::Msg objects to it's internal list and dump text
from them on demand.

It is a container for text generated deep in a program which will allow it
to be collected and returned to the top level or wherever it may be useful.

=head1 Examples

 use Fault::Notepad;
 use Fault::Msg;
 my $obj  = Fault::Notepad->new;
 my $obj2 = Fault::Notepad->new;
 my $msg  = Fault::Msg->("abridging freedom of speech...\n");

         $obj->add        ("Congress shall pass no law ");
         $obj2->addObject ($msg);
         $obj->merge      ($obj2);
         $obj->print;

         open $fh, ">notepad.tmp";
         $obj->fprint     ($fh);
         close $fh;

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$obj = Fault::Notepad-E<gt>new>

Create instances of Notepad.

=head1 Instance Methods

=over 4

=item B<$obj = $obj-E<gt>add ($note)>

Append a textual note to the notepad. 

=item B<$obj = $obj-E<gt>add ($obj)>

Append an Fault::Msg object containing a textual note to the notepad. 
the current time; if the object has digital signatures, create one.

=item B<$cnt = $obj-E<gt>count>

Returns a count of the items on the notepad.

=item B<$obj = $obj-E<gt>fprint ($fh)>

Print contents of Notepad verbatim to file.

=item B<$obj = $obj-E<gt>merge ($other)>

Append the contents of the argument notepad object to this notepad. 

=item B<$obj = $obj-E<gt>print>

Print contents of Notepad verbatim to stdout.

=item B<$str = $obj-E<gt>sprint>

Print contents of Notepad verbatim to a string.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 Fault::Logger, Fault::Msg.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Notepad.pm,v $
# Revision 1.7  2008-08-28 23:20:19  amon
# perldoc section regularization.
#
# Revision 1.6  2008-08-17 21:56:37  amon
# Make all titles fit CPAN standard.
#
# Revision 1.5  2008-07-28 10:57:37  amon
# Dropped last of tsag/dsig; new addObject method; sprint bugfix; newlines added to prints.
#
# Revision 1.4  2008-07-24 21:17:24  amon
# Moved all todo notes to elsewhere; made Stderr the default delegate instead 
# of Stdout.
#
# Revision 1.3  2008-07-24 19:27:51  amon
# Fix edit error in Notepad.
#
# Revision 1.2  2008-07-24 19:11:29  amon
# Notepad now uses Fault::Msg class which moves all the timestamp and 
# digitalsig issues to Msg.
#
# Revision 1.1  2008-07-22 14:32:17  amon
# Added Notepad and Delegate::Stderr classes
#
# 20080715  Dale Amon <amon@vnl.com>
#	    Created.
1;
