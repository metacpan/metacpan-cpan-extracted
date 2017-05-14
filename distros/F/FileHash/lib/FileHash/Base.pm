#================================= Base.pm ===================================
# Filename:  	       Base.pm
# Description:         Generalized hash by full path of file information.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:35:28 $ 
# Version:             $Revision: 1.10 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Logger;
use Fault::DebugPrinter;
use File::Spec;
use FileHash::Entry;
use FileHash::FormatString;
use Cwd qw(abs_path);

package FileHash::Base;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          INTERNAL OPS                                    
#=============================================================================

sub _leaf {
  my ($self,$dev,$directory,$file)  = @_;
  my $entry           = FileHash::Entry->alloc;
  my $path            = File::Spec->catfile($dev,$directory,$file);

  return $entry->initFromStat ($path);
}

#-----------------------------------------------------------------------------

sub _branch {
  my ($self,$dev,$directory,$file,$depth) = @_;
  my $path  = File::Spec->catfile($dev,$directory,$file);
  
  if (-d "$path" and ! -l "$path") {
    my ($fh,$new);

    Fault::Logger->assertion_check
	(!(opendir $fh, "$path"),undef,"Can not open '$path': $!") 
	  or return $self;

    # Readdir returns a null list if there are no files.
    $depth++;
    my @dirlist = readdir ($fh);
    closedir $fh;
    
    foreach $new (@dirlist) {
      next if ($new eq ".");
      next if ($new eq "..");
      $self->_branch ($dev,File::Spec->catfile($directory,$file),$new,$depth);
    }
    $depth--;
  }
  else {
    my $entry      = $self->_leaf ($dev,$directory,$file);
    defined $entry or return undef;

    $self->_store ($self->_genKey ($entry),$entry);
  }
  return $self;
}

#=============================================================================

sub _store {
  my ($self,$key,$val) = @_;

  if (! exists $self->{'filehash'}->{$key}) {
    $self->{'filehash'}->{$key} = [$val];
    Fault::DebugPrinter->dbg (2,"NEW       KEY <$key>");
  }
  else {
    Fault::DebugPrinter->dbg (2,"DUPLICATE KEY <$key>");
    push @{$self->{'filehash'}->{$key}}, $val;
  }
  my $path = $val->path;
  Fault::DebugPrinter->dbg   (3,"         FILE <$path>");
  return $self;
}

#-----------------------------------------------------------------------------

sub _genKey
  {Fault::Logger->crash ("Subclass must impliment: _genKey");}

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub alloc ($) {
  my ($class) = @_;
  my $self = bless {}, $class;
  $self->{'filehash'} = {};
  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================
#		             Init methods
#-----------------------------------------------------------------------------
sub init           ($)   {shift;}
sub initFromLines  ($$@) {shift->addFromLines  (@_);}
sub initFromFile   ($$$) {shift->addFromFile   (@_);}
sub initFromTree   ($$)  {shift->addFromTree   (@_);}
sub initFromObject ($$)  {shift->addFromObject (@_);}
sub initFromDump   ($$)  {shift->addFromDump   (@_);}

#=============================================================================
#		             add methods
#-----------------------------------------------------------------------------
# The FileHash::Entry object will check for invalid values in @lines.

sub addFromLines ($$@) {
  my ($self,$formatline,@lines) = @_;

  if ($::DEBUG) {
    Fault::Logger->arg_check_noref ($formatline,"formatline") or return undef;
  }

  my $fmt = FileHash::FormatString->alloc;
  $fmt->init ($formatline) or return undef;

  $self->{'format'} = $fmt;
  foreach (@lines) {
    next if (/^\w*$/);

    my $entry = FileHash::Entry->alloc;
    $entry->initFromLine ($self->{'format'},$_) or next;

    $self->_store ($self->_genKey ($entry),$entry);
  }
  return $self;
}

#-----------------------------------------------------------------------------

sub addFromFile ($$$) {
  my ($self,$formatline,$listfname) = @_;
  my $fh;

  if ($::DEBUG) {
    Fault::Logger->arg_check_noref ($formatline,"formatline") or return undef;
    Fault::Logger->arg_check_noref ($listfname, "listfname" ) or return undef;
  }

  Fault::Logger->assertion_check
      (!(open $fh, "<$listfname"),undef,"Can not open '$listfname': $!") 
	or return undef;

  # Readline returns a null list if there are no lines.
  my @lines = readline $fh;

  return $self->addFromLines ($formatline,@lines);
}

#-----------------------------------------------------------------------------

sub addFromTree ($$) {
  my ($self,$path) = @_;

  if ($::DEBUG) {
    Fault::Logger->arg_check_noref ($path,"path") or return undef;
  }

  my ($dev,$directories,$file) = 
    File::Spec->splitpath(Cwd::abs_path($path));
  
  $self->_branch ($dev,$directories,$file, 0);
  return $self;
}

#-----------------------------------------------------------------------------

sub addFromObject ($$) {
  my ($self,$old) = @_;

  if ($::DEBUG) {
    Fault::Logger->arg_check_isa ($old,"FileHash::Base","oldfilehash")
	or return undef;
  }

  foreach my $i (values %{$old->{'filehash'}}) {
    foreach my $j (@$i) {
      $self->_store ($self->_genKey ($j),$j);
    }
  }
  return $self;
}

#-----------------------------------------------------------------------------

sub addFromDump ($$) {
  my ($self,$path)      = @_;
  my ($fh,$entry,$s,$vers) = undef;

  if ($::DEBUG) {
    Fault::Logger->arg_check_noref ($path,"path") or return undef;
  }

  Fault::Logger->assertion_check
      (!(open $fh, "<$path"),undef,"Can not open '$path': $!") 
	or return undef;

  $_ = (<$fh>);
  if (/^Version:/) {($s,$vers) = split;}
  else {
    Fault::Logger->log
	("No Format version number found in report file header: '$path'");
    close $fh;
    return undef;
  }

  while (1) {
      my $entry = FileHash::Entry->alloc;
      $entry->addFromDump($fh) or last;

      $self->_store ($self->_genKey ($entry),$entry);
    }
  close $fh;
  return $self;
}

#=============================================================================
#                            Unary operators
#=============================================================================

sub identical ($) {
  my ($fha) = @_;
  my $class      = ref $fha;
  my ($j,$k,$v1);
  
  my $fhb = $class->alloc; 
  $fhb->init or return undef;
  
  my $a = $fha->{'filehash'};
  foreach $v1 (values %$a) {
    if ($#$v1 > 0) {
      foreach $j (@$v1) {$fhb->_store ($fhb->_genKey ($j),$j);}
    }
  }
  return $fhb;
}

#-----------------------------------------------------------------------------

sub unique ($) {
  my ($fha) = @_;
  my $class      = ref $fha;
  my ($j,$k,$v1);
  
  my $fhb = $class->alloc; 
  $fhb->init or return undef;
  
  my $a = $fha->{'filehash'};
  foreach $v1 (values %$a) {
    if ($#$v1 == 0) {
      foreach $j (@$v1) {$fhb->_store ($fhb->_genKey ($j),$j);}
    }
  }
  return $fhb;
}

#=============================================================================
#                            Binary operators
#=============================================================================

sub xor ($$) {
  my ($fha,$fhb) = @_;
  my $class      = ref $fha;
  my ($j, $k,$v1,$v2);

  if ($::DEBUG) {
      Fault::Logger->arg_check_isa ($fhb,$class,"fhb") or return undef;
  }

  my $fhc = $class->alloc; 
  $fhc->init or return undef;

  my ($a,$b) = ($fha->{'filehash'},$fhb->{'filehash'});
  while (($k,$v1) = each %$a) {
      if (!exists $b->{$k}) {
	  foreach $j (@$v1) {$fhc->_store ($fhc->_genKey ($j),$j);}
      }
  }
  while (($k,$v2) = each %$b) {
      if (!exists $a->{$k}) {
	  foreach $j (@$v2) {$fhc->_store ($fhc->_genKey ($j),$j);}
      }
  }
  return $fhc;
}

#-----------------------------------------------------------------------------

sub and ($$) {
  my ($fha,$fhb) = @_;
  my $class      = ref $fha;
  my ($j,$k,$v1,$v2);

  if ($::DEBUG) {
      Fault::Logger->arg_check_isa ($fhb,$class,"fhb") or return undef;
  }

  my $fhc = $class->alloc; 
  $fhc->init or return undef;

  my ($a,$b) = ($fha->{'filehash'},$fhb->{'filehash'});
  while (($k,$v1) = each %$a) {
      if (exists $b->{$k}) {
	  my $v2  = $b->{$k};
	  foreach $j (@$v1) {$fhc->_store ($fhc->_genKey ($j),$j);}
	  foreach $j (@$v2) {$fhc->_store ($fhc->_genKey ($j),$j);}
      }
  }
  return $fhc;
}

#-----------------------------------------------------------------------------

sub andnot ($$) {
  my ($fha,$fhb) = @_;
  my $class      = ref $fha;
  my ($j,$k,$v1,$v2);

  if ($::DEBUG) {
      Fault::Logger->arg_check_isa ($fhb,$class,"fhb") or return undef;
  }

  my $fhc = $class->alloc; 
  $fhc->init or return undef;

  my ($a,$b) = ($fha->{'filehash'},$fhb->{'filehash'});
  while (($k,$v1) = each %$a) {
      if (!exists $b->{$k}) {
	  foreach $j (@$v1) {$fhc->_store ($fhc->_genKey ($j),$j);}
      }
  }
  return $fhc;
}

#=============================================================================

sub dump ($$) {
  my ($self,$dumpfile) = @_;
  my $fh;

  if ($::DEBUG) {
    Fault::Logger->arg_check_noref ($dumpfile,"dumpfile") or return undef;
  }

  Fault::Logger->assertion_check
      (!(open $fh, ">$dumpfile"),undef,"Can not open '$dumpfile': $!") 
	or return undef;

  if (!printf $fh "Version: " . FileHash::Entry->dumpversion . "\n") {
    Fault::Logger->log ("Failed to print dumpfile header: $!");
    close $fh;
    return undef;
  }

  foreach my $i (values %{$self->{'filehash'}}) {
    foreach my $j (@$i) {$j->fprint ($fh);}
  }

  close $fh;
  return $self;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 FileHash::Base - Abstract superclass for FileHashes.

=head1 SYNOPSIS

 use FileHash;
 $obj = FileHash::Base->alloc;

 $obj = $obj->init;
 $obj = $obj->initFromLines  ($formatline,@lines);
 $obj = $obj->initFromFile   ($formatline,$datafilepath);
 $obj = $obj->initFromTree   ($rootdir);
 $obj = $obj->initFromObject ($obj2);
 $obj = $obj->initFromDump   ($path);

 $obj = $obj->addFromLines   ($formatline,@lines);
 $obj = $obj->addFromFile    ($formatline,$datafilepath);
 $obj = $obj->addFromTree    ($rootdir);
 $obj = $obj->addFromObject  ($obj2);
 $obj = $obj->addFromDump    ($path);

 $fhb = $fha->identical;
 $fhb = $fha->unique;

 $fhc = $fha->and            ($fhb);
 $fhc = $fha->andnot         ($fhb);
 $fhc = $fha->xor            ($fhb);

 $obj = $obj->dump           ($dumpfile);

=head1 Inheritance

 UNIVERSAL

=head1 Description

This is an abstract superclass for containers of lists of file metadata.
It is not directly useable and will execute a Fault if you attempt it.

FileHash::Name and FileHash::Content inherit most of their behavior from
here with the exception of hash key selection.

=head1 Examples

 See subclasses.

=head1 Class Variables

 None.

=head1 Instance Variables

 filehash	Pointer to a hash of arrays of FileHash::Entry objects
		which contain all the file metadata discovered found
		when the FileHash object was initialized. Entries for files 
		with identical keys hash into the same array, making for
		a very efficient sort.

=head1 Class Methods

=over 4

=item B<$obj = FileHash::Base-E<gt>alloc>

Allocate an empty instance of FileHash::Base. This is for inheritance
only and should not be used. Subclasses could override but there is
probably no reason to do so unless they add ivars. None do at present.

=head1 Instance Methods

Unless otherwise specified, instance methods return self on success and
undef on failure.

=over 4

=item B<$fhc = $fha-E<gt>and ($fhb)>

Create a file hash containing the groups of files found in both 
filehash a and b. 

a and b must be of the same FileHash subclass and the newly created
c will be off that type also.

=item B<$fhc = $fha-E<gt>andnot ($fhb)>

Create a file hash containing the groups of files found in filehash 
a but not in filehash b. 

a and b must be of the same FileHash subclass and the newly created
c will be off that type also.

If you want not a and b, just reverse the args; not a and not b is
obviously nonsensical as we are testing keys of a against keys of
b. 

=item B<$obj = $obj-E<gt>addFromDump ($dumpfile)>

Use a dump file to recreate hash entries and add them to a FileHash
object. 

The first line of the file must contain the text:

	Version: x.yy

=item B<$obj = $obj-E<gt>addFromFile  ($format,$datafilepath)>

Use the format line to create a FileHash::FormatString object. The 
format object is used to parse each of the lines in a file which 
contains lines of text data. Each line in the file is assumed to 
contain data about one file which is to be added to the FileHash.

=item B<$obj = $obj-E<gt>addFromLines ($format,@lines)>

Use the format line to create a FileHash:FormatString object. The 
format object is used to parse each of the lines in a list. Each 
line contains data about one file which is to be added to the FileHash.

=item B<$obj = $obj-E<gt>addFromObject ($obj2)>

Add data to a filehash from another FileHash, $obj2. This is useful for 
merging two objects. The subclasses need not be the same because the
Entries are inserted by re-hashing into the target object.

	my $a = FileHash::Name->alloc;
	$a->initFromTree ("/root");
	$a->addFromTree  ("/home/me");

=item B<$obj = $obj-E<gt>addFromTree ($rootdir)>

Entries are added to the hash via a recursive descent through a directory 
tree. Each file is a 'leaf node' and is represented by an array record in 
the hash. If two files have the same hash key, the are likely identical 
so the records for them are placed together in an array under that hask key.

=item B<$obj = $obj-E<gt>dump ($dumpfile)>

Dump FileHash::Entry objects sequentially, one to a line, to the specified 
filename. 

The first line of the file contains the FileHash::Entry dump file format 
version number in this format:

	Version: x.yy

=item B<$fhb = $fha-E<gt>identical>

Return a FileHash containing the contents of hash keys which have more
than one member. If the keys are md5,length this represents all files
with the same content; if they keys are name it represents all files
with the same name.

=item B<$obj = $obj-E<gt>init>

A noop at present. If you need an empty object, use this after alloc
to make sure that if init is needed in the future, it will be carried
out.

=item B<$obj = $obj-E<gt>initFromDump ($dumpfile)>

Use a dump file to recreate hash entries in a freshly alloc'd FileHash
object. 

The first line of the file must contain the text:

	Version: x.yy

=item B<$obj = $obj-E<gt>initFromFile  ($format,$datafilepath)>

Initialize a freshly alloc'd FileHash. It uses the format line 
to init a FileHash::FormatString object. The format object is used to parse
each of the lines in a file which contains lines of text data. Each line 
in the file is assumed to contain data about one file.

=item B<$obj = $obj-E<gt>initFromLines ($format,@lines)>

Initialize a freshly formatted FileHash. It uses the format line 
to create a FileHash:FormatString object. The format object is used to parse 
each of the lines in a list. Each line contains data about one file.

=item B<$obj = $obj-E<gt>initFromObject ($obj2)>

Initialize the newly alloc'd object using data from another FileHash, $obj2. 
This is useful for changing from hashing by name to hashing by content or
vice versa:

	my $a = FileHash::Name->alloc;
	my $b = FileHash::Content->alloc;
	$a->initFromTree ("/root");
	$b->initFromObject ($a);

=item B<$obj = $obj-E<gt>initFromTree ($rootdir)>

Initialize a freshly alloc'd FileHash. The hash is filled via a 
recursive descent through a directory tree. Each file is a 
'leaf node' and is represented by an array record in the hash. If
two files have the same hash key, the are likely identical so the records
for them are placed together in an array under that hask key.

=item B<$fhb = $fha-E<gt>unique>

Return a FileHash containing the contents of hash keys which have only
one member. These are files for which no other file has the same content
if the key is md5,length; or the same name if the key is the name.

=item B<$fhc = $fha-E<gt>xor ($fhb)>

Create a filehash c which contains all of the groups of files which
are only in fha or fhb but not both.

a and b must be of the same FileHash subclass and the newly created
c will be off that type also.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

=item B<$key = $obj-E<gt>_genKey($entry)>

Create an appropriate hash key. Each subclass must override this
stub method as it does nothing except print a warning message
and crash the program.

=head1 Errors and Warnings

 Lots.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

  File::Spec, Cwd, FileHash::Entry, FileHash::FormatString, Fault::Logger.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Base.pm,v $
# Revision 1.10  2008-08-28 23:35:28  amon
# perldoc section regularization.
#
# Revision 1.9  2008-08-09 20:25:13  amon
# Documentation error fixed.
#
# Revision 1.8  2008-08-09 12:56:01  amon
# Used wrong method name. Fixed
#
# Revision 1.7  2008-08-04 12:12:20  amon
# Added unary and binary ops; made init methods synonums for add methods.
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
# 20080722	Dale Amon <amon@vnl.com>
#		Renamed FileHash.pm to Base.pm so it is FileHash::Base.
# 20080717	Dale Amon <amon@vnl.com>
#		Split FilenameHash, formerly Directory class, into FileHash
#		FileHash::Name and FileHash::Content.
# 20080625	Dale Amon <amon@vnl.com>
#		Created.
1;
