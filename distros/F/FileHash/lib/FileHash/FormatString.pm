#============================= FormatString.pm ===============================
# Filename:  	       FormatString.pm
# Description:         Format lines to describe directory text lines.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:35:28 $ 
# Version:             $Revision: 1.7 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use File::Spec;
use HTTP::Date;
use Fault::Notepad;

package FileHash::FormatString;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          INTERNAL OPS                                    
#=============================================================================

my %FieldNames = 
  ('pathQuoted'		 => 1,	'path'		 => 1,
   'deviceQuoted'	 => 1,	'device'	 => 1,
   'directoryQuoted'	 => 1,	'directory'	 => 1,
   'fileQuoted'		 => 1,	'file'		 => 1,
   'mode'		 => 1,	'modeOctal'	 => 1,	'modeChars'	 => 1,
   'atime'		 => 1,	'atimeQuoted'	 => 1,
   'atimeDate'		 => 1,	'atimeTime'	 => 1,
   'ctime'		 => 1,	'ctimeQuoted'	 => 1,
   'ctimeDate'		 => 1,	'ctimeTime'	 => 1,
   'mtime'		 => 1,	'mtimeQuoted'	 => 1,
   'mtimeDate'		 => 1,	'mtimeTime'	 => 1,
   'uidName'		 => 1,	'uid'		 => 1,
   'gidName'		 => 1,	'gid'		 => 1,
   'hardlinks'		 => 1,
   'sizeBytes'		 => 1,
   'inode'		 => 1,
   'blocksAllocated'	 => 1,
   'blocksizePreference' => 1,
   'deviceSpecialId'	 => 1,
   'deviceNumber'	 => 1,
   'md5sum'		 => 1,
   'SKIP'		 => 1
);

#=============================================================================
#				Path ops
#=============================================================================

sub _selectBestString ($$$$$) {
  my ($s,$a,$b,$argnames,$out) = @_;

  $s->{'notepad'}->add 
    ("$argnames both present and are different: $a ne $b\n") 
      if ((defined $a and defined $b and ($a ne $b)));

  return (defined $a) ? $a : ((defined $b) ? $b : undef);
}

#-----------------------------------------------------------------------------

sub _bestPath ($$$) {
  my ($self,$in,$out) = @_;

  my $dev      = $self->_selectBestString
    (@$in{'deviceQuoted',   'device'},    "deviceQuoted and Device", $out);

  my $dir      = $self->_selectBestString
    (@$in{'directoryQuoted','directory'}, "directoryQuoted and Directory",
     $out);

  my $file     = $self->_selectBestString
    (@$in{'fileQuoted',     'file'},      "fileQuoted and File",     $out);

  my $fullpath = $self->_selectBestString
    (@$in{'pathQuoted',     'path'},      "pathQuoted and Path",     $out);

  my $catpath  = undef;
  if (defined $dir or defined $file) {
    defined $dir  or ($dir  = "");
    defined $file or ($file = "");
    $catpath   = File::Spec->catpath($dev,$dir,$file);
  }

  my $val      = $self->_selectBestString
    ($fullpath,$catpath, "Path or pathQuoted and constructed path",  $out);

  # splitpath will now force device to "" instead of undef as well.
  #
  return (File::Spec->splitpath($val));
}

#=============================================================================
#				File Mode ops
#=============================================================================

my %TypeNames = 
  (
   'c'		 => 0020000,
   'd'		 => 0040000,
   'b'		 => 0060000,
   '-'		 => 0100000,
   'l'		 => 0120000,
   's'		 => 0140000,
   'p'		 => 0160000
);

sub _string2mode ($$$) {
  my ($s,$modestr,$out) = @_;

  # Coding trick to get rid of leading and trailing whitespace.
  $_ = $modestr; ($modestr) = split;

  if (length $modestr != 10) {
    $s->{'notepad'}->add
      ("Modestring ignored. It must be 10 characters long: \'$modestr\'");
    return undef;
  }

  my ($type,$sticky,$sgid,$suid) = 
    ($modestr =~ 
     /([cdblsp-])[r-][w-]([xtT-])[r-][w-]([xsS-])[r-][w-]([xsS-])/);

  if (!defined $type) {
    $s->{'notepad'}->add ("Invalid mode string: \'$modestr\'");
    return undef;
  }

  my $typeval = $TypeNames{$type};
  my $mode    = lc (substr $modestr, 1);
     $mode    =~ tr/\-rwxSsTt/01/;

  return (
    $typeval |
      (((lc $suid) eq "s") ? 01000 : 0) |
	(((lc $sgid) eq "s") ? 02000 : 0) |
	  (((lc $sticky) eq "t") ? 04000 : 0) |
	    oct "0b${mode}");
}

#-----------------------------------------------------------------------------

sub _bestMode ($$$) {
  my ($s,$in,$out)          = @_;
  my ($mode1,$mode2,$mode3) = @$in{'mode','modeOctal','modeChars'};
  ($mode2 = oct $mode2)                     if (defined $mode2);
  ($mode3 = $s->_string2mode ($mode3,$out)) if (defined $mode3);

  my $mode = $s->_selectBestNumber
    ($mode2,$mode3, "modeOctal and modeChars",         $out);

  my $best = $s->_selectBestNumber
    ($mode1, $mode, "mode and modeOctal or modeChars", $out);

  return $best;
}

#=============================================================================
#				File Time ops
#=============================================================================

sub _convertQuoted ($$$$) {
  my ($s,$qtime,$str,$out) = @_;
  my $t                    = undef;
	       
  if (defined $qtime) {
    $t = HTTP::Date::str2time($qtime);
    $s->{'notepad'}->add ("Could not parse ${str}Quoted: \'$qtime\'") 
      if (!defined $t);
  }
  return $t;
}

#-----------------------------------------------------------------------------

sub _convertQuotedParts ($$$$) {
  my ($s,$qdate,$qtime,$str,$out) = @_;
  my $t                           = undef;

  if (defined $qdate or defined $qtime) {
    $t = HTTP::Date::str2time (((defined $qdate) ? "$qdate " : "") . 
			       ((defined $qtime) ?  $qtime   : ""));

    $s->{'notepad'}->add ("Could not parse ${str}Date + ${str}Time: " .
			"\'$qdate\' \'$qtime\'")
      if (!defined $t);    
  }
  return $t;
}

#-----------------------------------------------------------------------------

sub _selectBestNumber ($$$$$) {
  my ($s,$a,$b,$argnames,$out) = @_;

  $s->{'notepad'}->add ("$argnames both present and are different: $a != $b\n") 
    if ((defined $a and defined $b and ($a ne $b)));

  return (defined $a) ? $a : ((defined $b) ? $b : undef);
}

#-----------------------------------------------------------------------------

sub _getTime ($$$$$$) {
  my ($s,$t1,$qtime,$time3a,$time3b,$str,$out) = @_;
  my ($best,$t2,$t3);

  $t2 = $s->_convertQuoted      ($qtime,         $str,$out);
  $t3 = $s->_convertQuotedParts ($time3a,$time3b,$str,$out);

  my $time      = $s->_selectBestNumber
    ($t2,$t3,     "${str}TimeQuoted and ${str}Date + ${str}Time", $out);

  return ($s->_selectBestNumber
	  ($time, $t1, "${str}Time and a ${str}Quoted form", 	  $out));
}

#-----------------------------------------------------------------------------

sub _bestAtime ($$$) {
  my ($self,$in,$out) = @_;
  $self->_getTime(@$in{'atimeQuoted','atime','atimeDate','atimeTime'},
		  "atime",$out);
}

sub _bestCtime ($$$) {
  my ($self,$in,$out) = @_;
  $self->_getTime(@$in{'ctimeQuoted','ctime','ctimeDate','ctimeTime'},
		  "ctime",$out);
}

sub _bestMtime ($$$) {
  my ($self,$in,$out) = @_;
  $self->_getTime(@$in{'mtimeQuoted','mtime','mtimeDate','mtimeTime'},
		  "mtime",$out);
}

#=============================================================================
#    Uninterpreted fields. Some day I might add validation checking here.
#=============================================================================

sub _validateUID             ($$) {my ($s,$p) = @_; (@$p{'uid','uidName'}); }
sub _validateGID             ($$) {my ($s,$p) = @_; (@$p{'gid','gidName'}); }

sub _validateSize            ($$) {my ($s,$p) = @_; $p->{'sizeBytes'};      }
sub _validateInode           ($$) {my ($s,$p) = @_; $p->{'inode'};          }
sub _validateBlocksAllocated ($$) {my ($s,$p) = @_; $p->{'blocksAllocated'};}
sub _validateDeviceSpecialId ($$) {my ($s,$p) = @_; $p->{'deviceSpecialId'};}
sub _validateDeviceNumber    ($$) {my ($s,$p) = @_; $p->{'deviceNumber'};   }
sub _validateMD5SUM          ($$) {my ($s,$p) = @_; $p->{'md5sum'};         }
sub _validateHardLinks       ($$) {my ($s,$p) = @_; $p->{'hardlinks'};      }

sub _validateBlocksizePreference ($$) {my ($s,$p) = @_;
				                $p->{'blocksizePreference'};}
#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub alloc ($$) {
  my ($class,$line)                   = @_;
  my $self                            = bless {}, $class;
  @$self{'fields','format','notepad'} = undef;
  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub init ($$) {
  my ($self,$line) = @_;

  if ($::DEBUG) {
    Fault::Logger->arg_check_noref ($line,"formatline") or return undef;
  }
  
  my @format  = split ' ',$line;
  my $fields  = $#format+1;

  # If the format line is empty, add a skip that will eat entire the line.
  if ($fields == 0) {@format = ("SKIP"); $fields++;}

  @$self{'fields','reqd','format','notepad'} = ($fields, $fields, [], 
						Fault::Notepad->new);

  foreach (@format) { 
    if (defined $FieldNames{$_}) {
      push @{$self->{'format'}}, $_;
    }
    else {
      $self->{'notepad'}->add ("Invalid Fieldname in Format: $_\n");
      push @{$self->{'format'}}, 'SKIP';
    }
  }

  # If the last field is a SKIP, data is not required to be present at
  # that location.
  #
  if (${$self->{'format'}}[$#format] eq 'SKIP') {$self->{'reqd'}--;}
  return $self;
}

#-----------------------------------------------------------------------------
# The lexemes list arg will get checked in the various routines.
# NOTE: It will be up to the validate routines to detect if it contains 
# refs or other non text?

sub parse ($\@) {
  my ($self,@lexemes) = @_;
  my $actual_words    = $#lexemes+1;
  my ($in,$out);

  @$in{keys %FieldNames} = undef;
  $out->{'notepad'}      = Fault::Notepad->new;

  # Check for less than reqd fields as it is okay to be missing
  # a trailing SKIP field.
  #
  Fault::Logger->assertion_check
      ($actual_words < $self->{'reqd'},
       undef,"Not enough items in line to satisfy format: $_")
	or return undef;

  # Assign lexemes to their matching field name in the input hash
  @$in{@{$self->{'format'}}} = (@lexemes);

  @$out{'device','directory','file',
	'mode','atime','ctime','mtime',
	'uid','uidName','gid','gidName',
	'sizeBytes','inode','hardlinks',
	'blocksAllocated','blocksizePreference',
	'deviceSpecialId','deviceNumber','md5sum'} = 
	  ($self->_bestPath                    ($in),
	   $self->_bestMode                    ($in),
	   $self->_bestAtime                   ($in),
	   $self->_bestCtime                   ($in),
	   $self->_bestMtime                   ($in),
	   $self->_validateUID                 ($in),
	   $self->_validateGID                 ($in),
	   $self->_validateSize                ($in),
	   $self->_validateInode               ($in),
	   $self->_validateHardLinks           ($in),
	   $self->_validateBlocksAllocated     ($in),
	   $self->_validateBlocksizePreference ($in),
	   $self->_validateDeviceSpecialId     ($in),
	   $self->_validateDeviceNumber        ($in),
	   $self->_validateMD5SUM              ($in)
	  );

  return $out;
}

#-----------------------------------------------------------------------------

sub fields ($) {shift->{'fields'};}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 FileHash::FormatString - Supports parsing of formatted lines of file data.

=head1 SYNOPSIS

 use FileHash::Formatstring;
 $obj  = FileHash::FormatString->alloc;

 $obj  = $obj->init  ($formatline);
 $hash = $obj->parse (@lexemes);
 $cnt  = $obj->fields;

=head1 Inheritance

 UNIVERSAL

=head1 Description

This is an internal class used by FileHashes.

Format strings are used to map a positionally significant list of
lexemes to a set of field names. 

If the format line is empty, the format will default to a single
SKIP field which will absorb an entire line of input during parse.

It was created primarily to make it easy to read assorted 
dumps of metadata about files that might be hanging around in one's 
system and which might help to define what files used to be in that 
directory you just deleted...

=head1 Field Names

The following are the field names which may appear in a format string.

 pathQuoted		"C:/home/amon/Photo for Dale 00000.jpg"
 path			C:/home/amon/Photo_for_Dale_00000.jpg
 deviceQuoted		"C:"
 device			C:
 directoryQuoted	"/home/amon"
 directory		/home/amon
 fileQuoted		"Photo for Dale 00000.jpg"
 file			Photo_for_Dale_00000.jpg
 mode			33152
 modeChars		-rw-------
 modeOctal		0600
 atime			1214479354
 atimeQuoted		"2008-06-26 12:22"
 atimeDate		2008-06-26
 atimeTime		12:22
 ctime			1203083422
 ctimeQuoted		"2008-02-15 13:50"
 ctimeDate		2008-02-15
 ctimeTime		13:50
 mtime			1124835415
 mtimeQuoted		"2005-08-23 23:16"
 mtimeDate		2005-08-23
 mtimeTime		23:16
 uidName		amon
 uid			1000
 gidName		amon
 gid			1000
 hardlinks		1 
 sizeBytes		661340
 inode			2163352
 blocksAllocated	1304
 blocksizePreference	4096
 deviceSpecialId	0
 deviceNumber		771
 md5sum			2d6431f79028879f7aa2976e8222e76e
 SKIP			arbitraryword

Any space delimited item which does not match one of these items 
exactly, down to the capitalization, is replaced with the no op 
field name 'SKIP'. Later, during parsing, this will cause the
corresponding item in a list of lexemes to be ignored, ie dumped
into the 'SKIP' bucket.

If field names are repeated in a field string, only the last instance
will be meaningful. Parsed values for the earlier tokens are
overwritten by later ones. This is also true of 'SKIP' tokens, including
ones that are added as replacements for unknown field names.

If there is likely to be junk at the end of the line, a single SKIP at
the end will absorb all of the remaing text to the end of the line.

If more than one possibility is available for a given bit of
information about a file, all should have the same value, but only
the 'best' will be selected. The prioritization is done thusly:

For the path name of the file

 1 pathQuoted
 2 Path
 3 1 deviceQuoted  1 directoryQuoted  1 fileQuoted
   2 device        2 directory        2 file

The end result will be strings for device,directory and file, and the
null string for any that are missing.

For atime, ctime and mtime:

 1 *time
 2 *timeQuoted
 3 1 *timeDate  1 *timeTime

For the mode value:

 1 mode
 2 modeOctal
 3 modeChars

If the original line contains incomplete path data, it may
be supplied by the calling object pre-pending a pathQuoted or
directoryQuoted. If deviceQuoted is not null on the file system
and is missing, it should be included.

=head1 Examples

 use FileHash::FormatString;
 my $fmt  = "modeChars hardlinks uidName gidName sizeBytes mtimeDate mtimeTime file";
 my $line = "-rwxr-xr-x 1 root root       262 2003-08-23 15:58 20030823-ipsec1";
 my $a    = FileHash::FormatString->alloc;

 $a->init ($fmt);
 my @lexemes = split $line,$a->fields;
 $hash = $a->parse (@lexemes);

=head1 Class Variables

 None.

=head1 Instance Variables

 fields		Number of lexemes required for this line format.
 format		List of field names to match sequentially to lexemes.
 notepad	Notepad object used to record the unexpected.

=head1 Class Methods

=over 4

=item B<$obj = FileHash::FormatString-E<gt>alloc>

Allocate an empty FormatString object. 

=head1 Instance Methods

=over 4

=item B<$cnt = $obj-E<gt>fields>

Returns the number of format fields, including SKIP tokens, expected by 
this object.

=item B<$obj = $obj-E<gt>init ($formatline)>

Initialize a FormatString object. It has one required argument, a format
line which contains field names from the list given earlier. 

For example, a format line useable with a current Linux 'ls -l' output
line is:

 "modeChars hardlinks uidName gidName sizeBytes mtimeDate mtimeTime file"

=item B<$hash = $obj-E<gt>parse (@lexemes)>

Match the format field names one to one with the list of lexemes and
then return a hash with the 'best data' from those fields in cases where
different fields should contain the same information in different forms.

The returned hash uses field names suitable for direct insertion in a 
FileHash::Entry object.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 Lots.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 File::Spec, HTTP::Date, Fault::Notepad, Fault::Logger

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: FormatString.pm,v $
# Revision 1.7  2008-08-28 23:35:28  amon
# perldoc section regularization.
#
# Revision 1.6  2008-07-27 15:16:17  amon
# Wrote lexical parse for Entry; error checking on eval and other minor issues.
#
# Revision 1.5  2008-07-25 14:30:42  amon
# Documentation improvements and corrections.
#
# Revision 1.4  2008-07-24 20:19:43  amon
# Just in case I missed anything.
#
# Revision 1.3  2008-07-24 13:35:26  amon
# switch to NeXT style alloc/init format for FileHash and Entry classes.
#
# Revision 1.2  2008-07-23 21:12:24  amon
# Moved notes out of file headers; a few doc updates; added assertion checks;
# minor bug fixes.
#
# 20080706	Dale Amon <amon@vnl.com>
#	  	Created. Used some code from Directory::Entry class
1;
