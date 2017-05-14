#================================ Entry.pm ===================================
# Filename:  	       Entry.pm
# Description:         Container for data about a file.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:35:28 $ 
# Version:             $Revision: 1.8 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use File::Spec;
use Digest::MD5;
use Fault::Logger;
use Fault::Notepad;
use FileHash::FormatString;
use Data::Dumper;

package FileHash::Entry;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

# Update this number if the format of the entry dump is changed.
#
my $FileHashEntryVersion = "0.05";

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub alloc ($$) {
  my ($class) = @_;
  my $self    = bless {}, $class;
  @$self{'device','directory','file',
	 'md5sum',
	 'deviceNumber','inode','mode','hardlinks',
	 'uid','uidName','gid','gidName',
	 'deviceSpecialId','sizeBytes',
	 'atime','mtime','ctime',
	 'blocksizePreference','blocksAllocated','notepad'} = undef;
  return $self;
}

sub dumpversion ($) {$FileHashEntryVersion;}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub init ($$) {
  my ($self,$path) = @_;

  if ($::DEBUG) {Fault::Logger->arg_check_noref ($path,"path") 
      or return undef;}

  my ($dev,$dir,$file) = File::Spec->splitpath ($path);

  @$self{'device','directory','file','notepad'} = 
	   ($dev,$dir,$file,Fault::Notepad->new);

  return $self;
}

#-----------------------------------------------------------------------------
# Arg check responsibility is passed on to the init method.

sub initFromStat ($$) {
  my $self     = shift;
                 $self->init(@_);
  my $filename = $self->path;

  my (@stat);
  if (@stat = lstat($filename)) {
    @$self{'deviceNumber','inode','mode','hardlinks',
	   'uid','gid','deviceSpecialId','sizeBytes',
	   'atime','mtime','ctime',
	   'blocksizePreference','blocksAllocated'} = (@stat);

    # md5sum can only handle plain files, use 0 for md5sum otherwise.
    $self->{'md5sum'} = 0;
    if (-f $filename) {
      if (open(FILE, $filename)) {
	binmode FILE;
	$self->{'md5sum'} = Digest::MD5->new->addfile(*FILE)->hexdigest;
	close(FILE);
      }
    }
    else {
      $self->{'notepad'}->add ("Can not open '$filename' for hashing: $!\n");
    }
  }
  else {
    $self->{'notepad'}->add ("Can not lstat '$filename': $!\n");
  }
  return $self;
}

#-----------------------------------------------------------------------------

sub initFromLine ($$$) {
  my ($self,$format,$line) = @_;
  $self->{'notepad'}       = Fault::Notepad->new;

  if ($::DEBUG) {
    Fault::Logger->arg_check_isa ($format,"FileHash::FormatString","format")
	or return undef;
    Fault::Logger->arg_check_noref ($line,"line")
	or return undef;
  }

  chomp $line;
  my @string       = $self->_lexical_parse ($line,$format->fields);
  my $vals         = $format->parse (@string);

  # This way we can skip lines that do not match our format. It's a silly
  # cheat for working with files with headers and we'll need something
  # better.
  defined $vals or return undef;

  @$self{'device','directory','file',
	 'md5sum',
	 'deviceNumber','inode','mode','hardlinks',
	 'uid','uidName','gid','gidName',
	 'deviceSpecialId','sizeBytes',
	 'atime','mtime','ctime',
	 'blocksizePreference','blocksAllocated'} = 
	   (@$vals{'device','directory','file',
		   'md5sum',
		   'deviceNumber','inode','mode','hardlinks',
		   'uid','uidName','gid','gidName',
		   'deviceSpecialId','sizeBytes',
		   'atime','mtime','ctime',
		   'blocksizePreference','blocksAllocated'}
	   );

  $self->{'notepad'}->merge ($vals->{'notepad'});
  return $self;
}

#-----------------------------------------------------------------------------
# NOTE: eval could fail if we opened the wrong file. Need to check it.

sub initFromDump ($\*) {
  my ($self,$fh)     = @_;
  $self->{'notepad'} = Fault::Notepad->new;

  if ($::DEBUG) {
    Fault::Logger->arg_check_isa ($fh,"IO:Handle","filehandle")
	or return undef;
  }

  # Lines are of the form: 
  #    $entry = bless( {'mode' => 33188, ... }, 'FileHash::Entry' );
  #
  my $entry;
  my $line = readline $fh;
  defined $line or return undef;

  if (! eval $line) {
    Fault::Logger->log ("Eval on dump file line failed: $@");
    return undef;
  }

  # Initiatlize self from the input data
  @$self{keys %$entry} = (values %$entry);
  return $self;
}

#-----------------------------------------------------------------------------

sub _lexical_parse ($$$) {
  my ($class,$string,$fields) = @_;
  my ($quote, @pass2);

  my @pass1 = split /((?<!\\)["'])/,$string;

  foreach my $i (@pass1) {
    my $needed = $fields - ($#pass2+1);

    # The rest of the line goes in the last lexeme.
    if ($needed == 0) {$pass2[$#pass2] .= $i;}
    else {
      if (!defined $quote) {

 	# Start a quoted section
	if (length $i == 1 and ($i eq '"' or $i eq "'")) {
	  $quote = $i;
	  push @pass2, ("");
	}

	# Split nonquoted sections.
	else {push @pass2, (split " ", $i, $needed);}
      }

      # Append everything inside a quoted section.
      else {
	if ($quote eq $i) {$quote           = undef;}
	else              {$pass2[$#pass2] .= $i;   }
      }
    }
  }
  return @pass2;
}

#=============================================================================

sub print ($)   {my $s = shift; $s->fprint (*STDOUT); $s;}
sub dump  ($\*) {my $s = shift; $s->fprint (@_); $s;}

#-----------------------------------------------------------------------------

sub sprint ($) {
  my $self = shift;
  my $dd = Data::Dumper->new ([$self], ["self"]);
  $dd->Indent(0);
  return $dd->dump;
}

#-----------------------------------------------------------------------------

sub fprint ($\*) {
  my ($self,$fh) = @_;

  # NOTE: NEED A fault_check_isglob method

  my $dd = Data::Dumper->new ([$self], ["entry"]);
  $dd->Indent(0);

  my $ok = printf $fh "%s\n",$dd->Dump;
  $ok or Fault::Logger->log_once ("Failed to print to dumpfile: $!");

  return $self;
}

#=============================================================================

sub path ($) {
  my $s = shift; 
  return File::Spec->catpath (@$s{'device','directory','file'});
}

#-----------------------------------------------------------------------------
#     Return values for printing or hashing: "" or 0 on undef for hashing.
#-----------------------------------------------------------------------------

sub device              ($) {my $s=shift; 
			     (defined $s->{'device'}) 
			       ? $s->{'device'}    : "";}

sub directory           ($) {my $s=shift; 
			     (defined $s->{'directory'}) 
			       ? $s->{'device'}    : "";}

sub file                ($) {my $s=shift; 
			     (defined $s->{'file'}) 
			       ? $s->{'file'}      : "";}

sub md5sum              ($) {my $s=shift; 
			     (defined $s->{'md5sum'})
			       ? $s->{'md5sum'}    : 0;}

sub sizeBytes           ($) {my $s=shift; 
			     (defined $s->{'sizeBytes'})
			       ? $s->{'sizeBytes'} : 0;}

sub atime               ($) {my $s=shift; 
			     (defined $s->{'atime'})
			       ? $s->{'atime'}     : 0;}

sub mtime               ($) {my $s=shift; 
			     (defined $s->{'mtime'})
			       ? $s->{'mtime'}     : 0;}

sub ctime               ($) {my $s=shift; 
			     (defined $s->{'ctime'})
			       ? $s->{'ctime'}     : 0;}

#-----------------------------------------------------------------------------
#	      Values for printing, return "undef" string if undef.
#-----------------------------------------------------------------------------
sub deviceNumber        ($) {my $s=shift; 
			     (defined $s->{'deviceNumber'}) 
			       ? $s->{'deviceNumber'}        : "undef";}

sub inode               ($) {my $s=shift; 
			     (defined $s->{'inode'})
			       ? $s->{'inode'}               : "undef";}

sub mode                ($) {my $s=shift; 
			     (defined $s->{'mode'})
			       ? $s->{'mode'}                : "undef";}

sub hardlinks           ($) {my $s=shift; 
			     (defined $s->{'hardlinks'})
			       ? $s->{'hardlinks'}           : "undef";}

sub uid                 ($) {my $s=shift; 
			     (defined $s->{'uid'}) 
			       ? $s->{'uid'}                 : "undef";}

sub uidName             ($) {my $s=shift; 
			     (defined $s->{'uidName'})
			       ? $s->{'uidName'}             : "undef";}

sub gid                 ($) {my $s=shift; 
			     (defined $s->{'gid'})
			       ? $s->{'gid'}                 : "undef";}

sub gidName             ($) {my $s=shift; 
			     (defined $s->{'gidName'}) 
			       ? $s->{'gidName'}             : "undef";}

sub deviceSpecialId     ($) {my $s=shift; 
			     (defined $s->{'deviceSpecialId'}) 
			       ? $s->{'deviceSpecialId'}     : "undef";}

sub blocksizePreference ($) {my $s=shift; 
			     (defined $s->{'blocksizePreference'})
			       ? $s->{'blocksizePreference'} : "undef";}

sub blocksAllocated     ($) {my $s=shift; 
			     (defined $s->{'blocksAllocated'})
			       ? $s->{'blocksAllocated'}     : "undef";}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 FileHash::Entry - Container for data about a file.

=head1 SYNOPSIS

 use FileHash::Entry;
 $obj  = FileHash::Entry->alloc;
 $ver  = FileHash::Entry->dumpversion;

 $obj  = $obj->init         ($path);
 $obj  = $obj->initFromStat ($path);
 $obj  = $obj->initFromLine ($format,$line);
 $obj  = $obj->initFromDump ($fh);


 $str  = $obj->sprint;
 $obj  = $obj->print;
 $obj  = $obj->fprint($fh);
 $obj  = $obj->dump  ($fh);

 $path = $obj->path;

 $atime               = $obj->atime;
 $blocksizePreference = $obj->blocksizePreference;
 $blocksAllocated     = $obj->blocksAllocated;
 $ctime               = $obj->ctime;
 $device              = $obj->device;
 $deviceNumber        = $obj->deviceNumber;
 $deviceSpecialId     = $obj->deviceSpecialId;
 $directory           = $obj->directory;
 $file                = $obj->file;
 $gid                 = $obj->gid;
 $gidName             = $obj->gidName;
 $hardlinks           = $obj->hardlinks;
 $inode               = $obj->inode;
 $md5sum              = $obj->md5sum;
 $mode                = $obj->mode;
 $mtime               = $obj->mtime;
 $sizeBytes           = $obj->sizeBytes;
 $uid                 = $obj->uid;
 $uidName             = $obj->uidName;

=head1 Inheritance
 UNIVERSAL

=head1 Description

This is an internal class used by FileHashes.

Entry objects are containers for information about files collected
from various sources.

=head1 Examples

 use FileHash::Entry;

 # Create an entry by collecting metadata about a live file.
 my $a = FileHash::Entry->alloc;
 $a->initFromStat ("/root/myfile");

 # Create another Entry by parsing a line of data.
 my $f = FileHash::FormatString->alloc;
 $f->init ("path md5sum sizeBytes");
 my $b = FileHash::Entry->alloc;
 $b->initFromLine ($f, "/root/myfile 0bdebef6bc59cabe489442ef9ddecf5f 10050");

 # Dump the object data to a file.
 open $fh, ">mydump";
 $b->dump ($fh);
 close $fh;

 # Reload the dumped object data.
 my $c = FileHash::Entry->alloc;
 open $fh, "<mydump";
 $c->initFromDump ($fh);
 close $fh;

 # print data on the console.
 $c->print;
 
=head1 Class Variables

 None.

=head1 Instance Variables

In most cases an item will be undef if it is not available via the
source of information used to create the FileHash::Entry. 

 device			File device portion of file path, non Unix systems.
 directory		File directory portion of file path.
 file			File name portion of file path.
 deviceNumber		Device number.
 sizeBytes		Size of file in bytes.
 uid			User id number.
 uidName		User name in ascii.
 gid			Group id number.
 gidName		Group name in ascii.
 mode			File access mode integer.
 atime			Access time in nonleap seconds since 19700101 UTC.
 mtime			Modify time in nonleap seconds since 19700101 UTC.
 ctime			Create time in nonleap seconds since 19700101 UTC.
 inode			File Inode number.
 hardlinks		Number of hard links to file.
 deviceSpecialId	Device special id, integer.
 blocksizePreference	Preferred block size in bytes.
 blocksAllocated	Number of blocks allocated to the file.
 md5sum			md5sum of file content.
 notepad		A Notepad object to record unusual events.

=head1 Class Methods

=over 4

=item B<$obj = FileHash::Entry-E<gt>alloc>

Allocate an empty FileHash Entry object.

=item B<$ver = FileHash::Entry-E<gt>dumpversion>

Return the FileHash Entry dump format version id.

=back 4

=head1 Instance Methods for printing

=over 4

=item B<$atime = $obj-E<gt>atime>

Return the file atime or 0 if not known.

=item B<$blocksizePreference = $obj-E<gt>blocksizePreference>

Return the file blocksizePreference or "undef" if not known.

=item B<$blocksAllocated = $obj-E<gt>blocksAllocated>

Return the file blocksAllocated or "undef" if not known.

=item B<$ctime = $obj-E<gt>ctime>

Return the file ctime or 0 if not known.

=item B<$device = $obj-E<gt>device>

Return the file device or "" if not known.

=item B<$deviceNumber = $obj-E<gt>deviceNumber>

Return the file deviceNumber or "undef" if not known.

=item B<$deviceSpecialId = $obj-E<gt>deviceSpecialId>

Return the file deviceSpecialId or "undef" if not known.

=item B<$directory = $obj-E<gt>directory>

Return the file directory or "" if not known.

=item B<$file = $obj-E<gt>file>

Return the file name or "" if not known.

=item B<$gid = $obj-E<gt>gid>

Return the file gid or "undef" if not known.

=item B<$gidName = $obj-E<gt>gidName>

return the file gidName or "undef" if not known.

=item B<$hardlinks = $obj-E<gt>hardlinks>

Return the file hardlinks or "undef" if not known.

=item B<$inode = $obj-E<gt>inode>

Return the file inodes or "undef" if not known.

=item B<$md5sum = $obj-E<gt>md5sum>

Return the file md5sum or "undef" if not known.

=item B<$mode = $obj-E<gt>mode>

Return the file mode or "undef" if not known.

=item B<$mtime = $obj-E<gt>mtime>

Return the file mtime or 0 if not known.

=item B<$sizeBytes = $obj-E<gt>sizeBytes>

Return the file size in bytes or 0 if not known.

=item B<$uid = $obj-E<gt>uid>

Return the file uid or "undef" if not known.

=item B<$uidName = $obj-E<gt>uidName>

Return the file uidName or "undef" if not known.

=back 4

=head1 Instance Methods

=over 4

=item B<$obj = $obj-E<gt>dump($fh)>

Dump contents of the file data entry to one line in the specified file 
defined by the opened file handle $fh.

Synonym for fprint.

=item B<$obj = $obj-E<gt>fprint($fh)>

Dump contents of the file data entry to one line in the specified file 
defined by the opened file handle $fh.

Synonym for dump.

=item B<$obj = $obj-E<gt>init ($path)>

Initialize a FileHash Entry object to contain the path name.

=item B<$obj = $obj-E<gt>initFromDump ($fh)>

Replace the alloc'd object with one recreated from a line of dump 
file data.

=item B<$obj = $obj-E<gt>initFromLine ($format,$line)>

Create a FileHash Entry from the information parsed out of a line
of text. A format object defines what information is contained in
that line.

=item B<$obj = $obj-E<gt>initFromStat ($path)>

Initialized an object with metadata collected via a 'stat' and 'md5sum' 
applied to the file at $path.

=item B<$obj = $obj-E<gt>path>

Return the full path name.

=item B<$obj = $obj-E<gt>print>

Dump contents of the file data entry as one line on stdout.

=item B<$str = $obj-E<gt>sprint>

Dump contents of the file data entry as a string. The string is 
not terminated by a newline.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

=item B<@lexemes = $obj-E<gt>_lexical_parse ($line,$fields)>

This is the point at which the field data is split it needs to handle a 
mix of blank delimited fields and quoted fields. If want to parse
lines of code here, you'll just have to write your own subclass and
override this method. 

=head1 Errors and Warnings

 Lots.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 File::Spec, Digest::MD5, Fault::Notepad, Fault::Logger, 
 FileHash::FormatString, Data::Dumper.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Entry.pm,v $
# Revision 1.8  2008-08-28 23:35:28  amon
# perldoc section regularization.
#
# Revision 1.7  2008-08-09 12:56:42  amon
# Added parens to fix math error.
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
# 20080625	Dale Amon <amon@vnl.com>
# 		Created.
1;
