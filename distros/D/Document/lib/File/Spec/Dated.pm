#================================ Dated.pm ===================================
# Filename:            Dated.pm
# Description:         Object to parse File::Spec::Dated archive filenames.
# Programmed by:       Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:32:45 $ 
# Version:             $Revision: 1.3 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::ErrorHandler;
use Fault::DebugPrinter;
use DMA::ISODate;
use DMA::FSM;
use File::Spec::BaseParse;

package File::Spec::Dated;
use vars qw{@ISA};
@ISA = qw( File::Spec::BaseParse );

#=============================================================================
#                       Object Methods
#=============================================================================
# Local Lexical Analyzers for splitpath method.

sub _nullFilename {
  my ($lexeme, $bb) = @_;
  Fault::ErrorHandler->warn ("Impossible state: Missing first lexeme");
  $bb->{'tail'} = "startdate";
  return (1,$lexeme);
}

sub _getFirstDate {
  my ($lexeme, $bb) = @_;

  # This is a a hack because my printer needs a toner cartridge and ISODate 
  # parsing is too much of bother to attempt solely on screen. It catches the
  # special case of '<date>.<extentions>'
  #
  my ($lpar, $rpar) = ($lexeme =~ /^(.*)(\..*)?$/);

  my $date = DMA::ISODate->new($lpar);
  if ($date) {
    @$bb{'startdate','tail'} = ($date->get,"startdate"); return (1,$rpar);}
  $bb->_err("Filename does not begin with an ISO date"); return (0,$lexeme);
}

sub _endsWithStartDate {
  my ($lexeme, $bb) = @_;
  $bb->_err("Name truncated after start date"); return (1,$lexeme);}

sub _getSecondDate {
  my ($lexeme, $bb) = @_;	  

  # This is a a hack because my printer needs a toner cartridge and ISODate 
  # parsing is too much of bother to attempt solely on screen. It catches the 
  # special case of '<date>.<extentions>'
  #
  my ($lpar, $rpar) = ($lexeme =~ /^(.*)(\..*)$/);
  my $date = DMA::ISODate->new($lexeme);
  if ($date) {@$bb{'enddate','tail'} 
		= ($date->get,"enddate"); return (1,$rpar);}
  return (0,$lexeme);
}

sub _noBody
 {my ($lexeme, $bb) = @_; $bb->_err("No name_body section found"); 
  return (1,undef);}

sub _getFirstBody
 {my ($lexeme, $bb) = @_; 
  @$bb{'name_body','tail'} = ($lexeme,"name_body"); return (1,undef);}

sub _getBody
 {my ($lexeme, $bb) = @_; 
  $bb->{'name_body'} .= "-" . $lexeme;
  $bb->{'tail'} = "name_body"; 
  return (1,undef);
}

sub _noop {my ($lexeme, $bb) = @_; return (1,$lexeme);}

#-----------------------------------------------------------------------------

sub splitpath {
  my ($self,$file) = (shift, shift);
  my ($hasdots,$root,@extensions,$lexeme);

  my $fst = 
    { 'S0' => ["E0","SAME", \&_getFirstDate,      "S1","TSTL","S2","SAME"],
      'S1' => ["D1","SAME", \&_getSecondDate,     "S2","TSTL","S2","SAME"],
      'S2' => ["D2","SAME", \&_getFirstBody,      "S3","NEXT","S3","NEXT"],
      'S3' => ["D0","SAME", \&_getBody,           "S3","NEXT","S3","NEXT"],
      'D0' => ["D0","DONE", \&_noop,              "","","",""],
      'E0' => ["E0","FAIL", \&_nullFilename,      "","","",""],
      'D1' => ["D1","DONE", \&_endsWithStartDate, "","","",""],
      'D2' => ["D2","DONE", \&_noBody,            "","","",""],
    };  

  $self->SUPER::splitpath ($file);
  Fault::DebugPrinter->dbg (4, "Beginning parse for File::Spec::Dated");

  # This is just a fast way to get name + extensions. I could have used 
  # _append_extensions_to_tail.
  #
  $self->{'name'} = $self->{'filename'};

  # Reparse the filename. We are more persnickity about extensions at this 
  # level: it is not an extension unless it occurs after the last "-" in the
  # name.  
  #
  my @lexlst = split (/-/, $self->{'name'});

  my @remaining = DMA::FSM::FSM ( $fst, $self, @lexlst);
  delete $self->{'state'};

  # If name_body was the tailpart, see if it has trailing extensions. If the 
  # tailpart were dates, there could not have been anything leftover.
  #
  {$_ = $self->{'tail'};
   if (/name_body/) {
     my $lpar = $self->_parse_extensions_from_tail;
     $self->{$_} = ($lpar) ? $lpar : undef;
     $self->reset_name;
   }
 }

  return (@$self{'volume','basepath','directory',
		 'startdate','enddate','name_body'},
	  (@{$self->{'extensions'}}));
}

#-----------------------------------------------------------------------------
# Set parts of name

sub set_startdate  {my $s=shift; @$s{'startdate','_dirty'}=(shift,1); 
		    return $s;}

sub set_enddate    {my $s=shift; @$s{'enddate',  '_dirty'}=(shift,1);
		    return $s;}

sub set_name_body  {my $s=shift; @$s{'name_body','_dirty'}=(shift,1);
		    return $s;}

#-----------------------------------------------------------------------------

sub reset_name {
  my $self = shift;
  my ($name,$del) = ("","");
  foreach (@$self{'startdate','enddate','name_body'}) {
    $_ || next;
    $name .= "$del$_"; $del = "-";
  }
  return $self->{'name'} = ($name) ? $name : undef;
}

#-----------------------------------------------------------------------------

sub startdate  {return shift->{'startdate'};}
sub enddate    {return shift->{'enddate'};}
sub name_body  {return shift->{'name_body'};}

#-----------------------------------------------------------------------------

sub dates {
  my $self = shift;
  my ($beg,$end) = ($self->{'startdate'}, $self->{'enddate'});
  defined $beg || (return undef);
  defined $end || (return $beg);
                   return $beg . "-" . $end;
}

#-----------------------------------------------------------------------------

sub undated_filename {
  my $self         = shift;
  my $extensions   = $self->extensions;
  return $self->{'name_body'} . (($extensions) ? ".$extensions" : "");
}

#=============================================================================
#                       INTERNAL: Object Methods
#=============================================================================

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  @$self{'startdate','enddate','name_body','extension','extensions'} = 
    ( undef,undef,undef,undef,[] );
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 File::Spec::Dated - Object to parse dated archive filenames.

=head1 SYNOPSIS

 use File::Spec::Dated;

 ($volume, $basepath, $directory, $startdate, $enddate, $name_body, @extensions) = $self->splitpath ($filepath);

 $startdate = $self->startdate;
 $enddate   = $self->enddate;
 $dates     = $self->dates;
 $undated   = $self->undated_filename;
 $name_body = $self->name_body;
 $self      = $self->set_startdate ($startdate);
 $self      = $self->set_enddate ($enddate);
 $self      = $self->set_name_body ($name_body);
 $name      = $self->reset_name;


=head1 Inheritance

 UNIVERSAL
   File::Spec::Unix
     File::Spec::BaseParse
       File::Spec::Dated

=head1 Description

Split a filename path into segments used by virtually all archiver
applications. This includes the segmentation done by the File::Spec:Archivist
plus a further breakdown of the filename part it returns.

For example, if the filename were 19901225-XMAS-Title-Subtitle-note.tar.gz
would be further split as:

 startdate:         19991225
 enddate:           undef
 name_body:         XMAS-Title-Subtitle-note
 extensions:        (tar gz)
 extension:         gz

Extensions are re-parsed here with more constraints on what is considered an
extension. It must not only be dot delimited, but also be left of the
last - i the filename. Eve so, there is still an ambiguity problem  to be
dealt with here and in child classes. We cannot always be certain that an
extension really is an extension. For example, if the filename were  
DATE-XYZ.ABC, it could be parsed in a number of ways:

          name_body:         XYZ
          extension:         ABC

or
          name_body:         XYZ.ABC

The later may seem unlikely, but here are examples showing that it isn't:

 19991225-XMAS-CardGenerator-V1.1
 19991225-XMAS-ACarol-p100.1a

=head1 Examples

 use File::Spec::Dated;
 my $baz        = File::Spec::Dated->new;
 my @list       = $baz->splitpath
                  ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $foo        = File::Spec::Dated->new
                  ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $startdate  = $foo->startdate;
 my $enddate    = $foo->enddate;
 my $dates      = $foo->dates;
 my $undated    = $obj->undated_filename;
 my $name_body  = $foo->name_body;
 my @extensions = $foo->extensions;
 my $extensions = $foo->extensions;
 my $extension  = $foo->extension;

 $foo->set_startdate  ("19901225120000");
 $foo->set_enddate    ("20001225120000");
 $foo->set_name_body  ("XMAS-Title-Subtitle-note");
 $foo->set_extensions ("jpeg" );
 my $name       = $foo->reset_name;
 my $filename   = $foo->reset_filename;
 my $filepath   = $foo->reset_pathname;
 my @parts      = $foo->reparse;

 $foo->set_extensions ("tar","gz");
 $filename      = $foo->reset_filename;
 $filepath      = $foo->reset_pathname;
 @parts         = $foo->reparse;

=head1 Class Variables

 None.

=head1 Instance Variables

 startdate         The starting date string.
 enddate           The ending date string.
 name_body         The "body" portion of the filename.
 extensions        A list, left to right, of all file extensions found.
 extension         Last or rightmost of the file extensions found.

=head1 Class Methods

 None.

=head1 Instance Methods

=over 4

=item B<$dates = $obj-E<gt>dates>

Return a $dates string suitable for use in an index or table of contents,
eg "19991225", "19991225103015", "19991225-20000101" or
"19991225103000-19991225113000".

Returns undef if there is no date information associated with this filespec.

=item B<$enddate = $obj-E<gt>enddate>

Return the end date string or undef if none.

=item B<$name_body = $obj-E<gt>name_body>

Return the name_body or undef if none.

=item B<$name = $obj-E<gt>reset_name>

Regenerate name from parts:

	startdate + enddate + name_body -> name

=item B<$obj = $obj-E<gt>set_enddate ($enddate)>

Unconditionally set the end date of the filename.

=item B<$obj = $obj-E<gt>set_name_body ($name_body)>

Unconditionally set the name_body of the filename.

=item B<$obj = $obj-E<gt>set_startdate ($startdate)>

Unconditionally set the start date of the filename.

=item B<($volume, $basepath, $directory, $startdate, $enddate, $name_body, @extensions) = $obj-E<gt>splitpath ($filepath)>

Parses the filename into:

	firstdate{-lastdate}{-name_body}{.extensions}

and returns all the elements of the pathname and filename as a list. 
Completely reinitializes the object for the name $filepath. Chains to parent 
class method.

=item B<$startdate = $obj-E<gt>startdate>

Return the start date string  or undef if none.

=item B<$undated = $obj-E<gt>undated_filename>

If a filename has dates on the left, return the remainder; if there is no
date part do nothing. 

For example, whether the original filename is 20040817-filename.tar.gz or 
just filename.tar.gz it will return filename.tar.gz. This is useful in 
applications which deal with both Archivist and non-Archivist filenames 
and which may need to shift a file back and forth between the two universes.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

=over 4

=item B<$obj = $obj-E<gt>_init>

Internal initializer. Chains to parent class method.

This method is for the subclass initializer chaining and should not be used
otherwise.

=back 4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::ErrorHandler, Fault::DebugPrinter, DMA::ISODate, DMA::FSM, File::Spec::BaseParse

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Dated.pm,v $
# Revision 1.3  2008-08-28 23:32:45  amon
# perldoc section regularization.
#
# Revision 1.2  2008-08-16 17:49:06  amon
# Update source format, documentation; switch to Fault package
#
# Revision 1.1.1.1  2004-09-17 16:52:34  amon
# File Spec extensions for doc name formats.
#
# 20040917      Dale Amon <amon@islandone.org>
#		Added undated_filename method.
#
# 20040821      Dale Amon <amon@islandone.org>
#		Switched to Finite State Machine for parsing.
#
# 20040820      Dale Amon <amon@islandone.org>
#		Modified the name of the parent to File::Spec::BaseParse.
#
# 20040815      Dale Amon <amon@islandone.org>
#		Changed from Archivist::FileSpec to File::Spec::Dated.
#
# 20021208      Dale Amon <amon@vnl.com>
#		Hacked it apart into a Class hierarchy.
#
# 20021121      Dale Amon <amon@vnl.com>
#               Created.
#
1;
