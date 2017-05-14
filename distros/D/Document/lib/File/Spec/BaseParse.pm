#============================== BaseParse.pm =================================
# Filename:            BaseParse.pm
# Description:         Object to parse filenames and paths.
# Programmed by:       Dale Amon <amon@islandone.org> 
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:32:45 $ 
# Version:             $Revision: 1.3 $
# License:	       LGPL 2.1, Perl Artistic or BDS
#
#=============================================================================
use strict;
use Fault::DebugPrinter;
use File::Spec::Unix;

package File::Spec::BaseParse;
use vars qw{@ISA};
@ISA = qw( File::Spec::Unix );

#=============================================================================
#                               Class Methods
#=============================================================================

sub new {
	my ($class, $file) = @_;
	my $self = bless {}, $class;

	if (defined $file) {$self->splitpath ($file);}
	else               {$self->_init;}

	return $self;
}

#=============================================================================
#                       Object Methods
#=============================================================================

sub splitpath {
	my ($self,$file) = (shift, shift);
	$self->_init;

	# Find the basic system independant file spec parts
	chomp $file;
	$self->{'pathname'} = $file;
	@$self{'volume','rootpath','filename'} = 
	  $self->SUPER::splitpath ($file);
	Fault::DebugPrinter->dbg 
	    (4, "Beginning parse for File::Spec::BaseParse");
	
	my @segments = split ('/', $self->{'rootpath'});

	# If the path only has 1 element, ie the root /, we make the basepath
	# empty and the directory "/" in hopes this will letother software 
	# work.
	#
	if ($#segments < 0) {
	  @$self{'basepath','directory'} = ("", ($self->{'rootpath'}));
	}
	else {
	  my $directory = pop @segments;
	  @$self{'basepath','directory'} = 
	    ($self->canonpath (join('/', @segments)), $directory);
	}

	# The filename is currently the tail part, so extensions will be 
	# parsed from it.
	#
	$self->{'tail'} = "filename";
	$self->{'name'} = $self->_parse_extensions_from_tail;

	return (@$self{'volume','basepath','directory',
		       'name'},(@{$self->{'extensions'}}));
}

#=============================================================================
# Set parts of pathname

sub set_volume   {my $s=shift; @$s{'volume',  '_dirty'}=(shift,1); return $s;}
sub set_rootpath {my $s=shift; @$s{'rootpath','_dirty'}=(shift,1); return $s;}
sub set_filename {my $s=shift; @$s{'filename','_dirty'}=(shift,1); return $s;}

#-----------------------------------------------------------------------------
# Set parts of rootpath.

sub set_basepath   {my $s=shift; @$s{'basepath','_dirty'}=(shift,1); 
		    return $s;}
sub set_directory  {my $s=shift; @$s{'directory','_dirty'}=(shift,1); 
		    return $s;}

#-----------------------------------------------------------------------------
# Set parts of filename.

sub set_name       {my $s=shift; @$s{'name',    '_dirty'}=(shift,1); 
		    return $s;}
sub set_extensions {my $s=shift; $s->{'_dirty'}=1; $s->{'extensions'}=[@_];
		    return $s;}

#-----------------------------------------------------------------------------

sub reset_filename {
  my $self = shift;
  my $filename = $self->{'name'};
  foreach (@{$self->{'extensions'}}) {
    $_ || next;
    $filename .= "." . $_;
  }
  return $self->{'filename'} = ($filename) ? $filename : undef;
}

#-----------------------------------------------------------------------------

sub reset_rootpath {
  my $self = shift;
  my ($rootpath,$del) = ("","");
  foreach (@$self{'basepath','directory'}) {
    $_ || next;
    $rootpath .= "$del$_"; $del = "/";
  }
  return $self->{'rootpath'} = ($rootpath) ? $rootpath : undef;
}

#-----------------------------------------------------------------------------

sub reset_pathname {
  my $self = shift;
  my ($pathname,$del) = ("","");
  foreach (@$self{'volume','rootpath','filename',}) {
    $_ || next;
    $pathname .= "$del$_"; $del = "/";
  }
  return $self->{'pathname'} = 
    ($pathname) ? $self->canonpath($pathname) : undef;
}

#-----------------------------------------------------------------------------
# Reparse pathname from scratch after reset's.

sub reparse {my $s=shift; return $s->splitpath ($s->{'pathname'});}

#=============================================================================

sub pathname  {return shift->{'pathname'};}
sub volume    {return shift->{'volume'  };}
sub rootpath  {return shift->{'rootpath'};}
sub basepath  {return shift->{'basepath'};}
sub directory {return shift->{'directory'};}
sub filename  {return shift->{'filename'};}
sub name      {return shift->{'name'};}
sub extension {return shift->{'extension'};}

#-----------------------------------------------------------------------------
# Language porting note: this is implicitly function overloading.

sub extensions {return (wantarray) ? 
		  @{shift->{'extensions'}} :
		    join ".", @{shift->{'extensions'}};}

#=============================================================================
#                       INTERNAL: Object Methods
#=============================================================================

sub _init {
	my $self = shift;
	@$self{'pathname','volume','rootpath','basepath','directory',
	       'filename',,'name','extension','extensions',
	       'fmterr','_dirty'} = 
	  ( undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,0);
	return $self;
}

#-----------------------------------------------------------------------------

sub _err {my $self = shift; $self->{'fmterr'} = shift; return $self;}

#-----------------------------------------------------------------------------

sub _parse_extensions_from_tail {
  my $self = shift;
  my ($left_lexeme, $tail_lexeme, @extensions);
  @$self{'extension','extensions'} = (undef,[]);

  defined $self->{'tail'} || return undef;

  $tail_lexeme = $self->{$self->{'tail'}};
  defined $tail_lexeme    || return undef;

  ($left_lexeme, @extensions) = split ('\.', $tail_lexeme);
  if ($#extensions > -1) {
    $self->{'extension'}  = lc ($extensions[$#extensions]);
    $self->{'extensions'} = [@extensions];
  }
  return $left_lexeme;
}

#-----------------------------------------------------------------------------

sub _append_extensions_to_tail {
  my $self = shift;
  my $exts = "." . $self->extensions;

  # Return the extensions even if there is no tail defined or if it is empty.
  #
  defined $self->{'tail'} || return $exts;
  my $tail_lexeme = $self->{$self->{'tail'}};
  defined $tail_lexeme    || return $exts;
  
  return $tail_lexeme . $exts;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 File::Spec::BaseParse - Parse a basic file name spec in a system independant way.

=head1 SYNOPSIS

 use File::Spec::BaseParse;

 $obj = File::Spec::BaseParse->new ($pathname);
 $obj = File::Spec::BaseParse->new;

 ($volume, $basepath, $directory, $name, @extensions) = $obj->splitpath ($filepath);

 $pathname     = $obj->pathname;
 $volume       = $obj->volume;
 $rootpath     = $obj->rootpath;
 $basepath     = $obj->basepath;
 $directory    = $obj->directory;
 $filename     = $obj->filename;
 $name         = $obj->name;
 @extensions   = $obj->extensions;
 $extensions   = $obj->extensions;
 $extension    = $obj->extension;
 $obj          = $obj->set_volume ($volume);
 $obj          = $obj->set_rootpath ($rootpath);
 $obj          = $obj->set_filename ($filename);
 $obj          = $obj->set_basepath  ($basepath);
 $obj          = $obj->set_directory ($directory);
 $obj          = $obj->set_name ($name);
 $obj          = $obj->set_extensions (@extensions);
 $filename     = $obj->reset_filename;
 $pathname     = $obj->reset_pathname;
 $rootpath     = $obj->reset_rootpath; 
 ($volume, $basepath, $directory, $filename) = $obj->reparse;

=head1 Inheritance

 UNIVERSAL
   File::Spec::Unix
     File::Spec::BaseParse

=head1 Description

Split a file pathname into (mostly) system independent parts via the parent
class File::Spec::Unix. The resultant rootpath is additionally split into a
basepath and directory, and the filename into name and extensions.

For example, /my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz would
be split up as:

 volume:      undef
 basepath:    /my/base
 directory:   Cards
 filename:    19901225-XMAS-Title-Subtitle-note.tar.gz
 name:        19901225-XMAS-Title-Subtitle-note
 extensions:  gz
 extensions:  tar gz

At the moment the directory is split in a non-system -independent way.

[Not doing much with _dirty flag yet. Set it in all set's, clear it on _init.
Doesn't matter on resets because they won't make any changes unless the ivars
they used were changed, in which case it was touched already.  Could do lazy
evaluation if I chose to. Then I  could dump all the reset and reparse methods
 right down through all the child classes.]

[Should initialization of unused fields default to undef as it does now, or
should it be null strings,  ""? The undef's seem to be working well enough,
but  it is worth reconsidering this point.]

=head1 Examples

 use File::Spec::BaseParse;
 my $baz       = File::Spec::BaseParse->new;
 my @list      = $baz->splitpath
                ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $foo       = File::Spec::BaseParse->new
                ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $pathname  = $foo->pathname;
 my $volume    = $foo->volume;
 my $rootpath  = $foo->rootpath;
 my $basepath  = $foo->basepath;
 my $directory = $foo->directory;
 my $filename  = $foo->filename;

 $foo->set_volume     ("C:/");
 $foo->set_rootpath   ("/root/Cards/" );
 $foo->set_filename   ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.ps")
 my $path      = $foo->reset_pathname;
 my @parts     = $foo->reparse;

 $foo->set_basepath   ("/my/base");
 $foo->set_directory  ("Cards");
 my $rootpath  = $foo->reset_rootpath;
 my $path      = $foo->reset_pathname;
 my @parts     = $foo->reparse;

 $foo->set_name       ("SomethingSimpler");
 $foo->set_extensions ("tar", gz);
 my $filename  = $foo->reset_filename;
 my $rootpath  = $foo->reset_rootpath;
 my $path      = $foo->reset_pathname;
 my @parts     = $foo->reparse;

=head1 Class Variables

 None.

=head1 Instance Variables

 pathname      Unmodified version of the pathname string.
 volume        Volume name string as returned by parent class.
 rootpath      Path string as returned by the parent class. We split it into
               basepath and directory.
 basepath      rootpath string less the rightmost subdirectory. It may be a
               null string if rootpath is / because the / will be assigned to
               directory.
 directory     The rightmost subdirectory of rootpath.
 filename      The filename string as returned by the parent class.
 name          The portion of the filename left of the first dot.
 extensions    A list of dot separated elements right of the first dot.
 extension     The rightmost element of the list of extensions.
 tail          The ivar name of the parsed item containing the rightmost 
               portion of the original name.

=head1 Class Methods

=over 4

=item B<$obj = File::Spec::BaseParse-E<gt>new ($pathname)>

Create a new object for $pathname. Returns the new object. Might someday
return undef on failure... but just now I can't think of anything that is
illegal as a Unix filename so it doesn't fail yet.

=item B<$obj = File::Spec::BaseParse-E<gt>new>

Create a new object with an undef pathname.  Use this when the need is for
an object to act as a generic filepath name parser / syntax checker.

=back 4

=head1 Instance Methods

=over 4

=item B<$basepath = $obj-E<gt>basepath>

Return the base path string.

=item B<$directory = $obj-E<gt>directory>

Return the directory string.

=item B<$extension = $obj-E<gt>extension>

Return the rightmost extension or undef if none.

=item B<@extensions = $obj-E<gt>extensions>

=item B<$extensions   = $obj-E<gt>extensions>

Return the extensions as a list in array context ("tar","gz") or as a string
in a scalar context  ("tar.gz").  undef if there are no extensions.

=item B<$filename = $obj-E<gt>filename>

Return the filename string.

=item B<$name = $obj-E<gt>name>

Return the name string, the portion of a filename left of the first dot.

=item B<$pathname = $obj-E<gt>pathname>

Return the original, full path name string.

=item B<$filename = $obj-E<gt>reset_filename>

Regenerate filename from parts:

	name + extensions -> filename

=item B<$pathname = $obj-E<gt>reset_pathname >

Regenerate pathname from parts:

	volume + rootpath + filename -> pathname

=item B<($volume, $basepath, $directory, $filename) = $obj-E<gt>reparse >

Reparse the full pathname.  Does a splitpath on the current contents of the
pathname ivar. Use this method after a a group of set and reset commands to
confirm the modified filepath is valid. Returns the same values as 
splitpath.

=item B<$rootpath = $obj-E<gt>reset_rootpath >

Regenerate rootpath from parts:

	basepath + directory -> rootpath

=item B<$rootpath = $obj-E<gt>rootpath>

Return the root path string.

=item B<$obj = $obj-E<gt>set_basepath  ($basepath)>

Unconditionally set the basepath ivar.

=item B<$obj = $obj-E<gt>set_directory ($directory)>

Unconditionally set the directory ivar.

=item B<$obj = $obj-E<gt>set_extensions (@extensions)>

Unconditionally set the extensions list of the filename.

=item B<$obj = $obj-E<gt>set_filename ($filename)>

Unconditionally set the filename ivar.

=item B<$obj = $obj-E<gt>set_name ($name)>

Unconditionally set the body of the name.

=item B<$obj = $obj-E<gt>set_rootpath ($rootpath)>

Unconditionally set the rootpath ivar.

=item B<$obj = $obj-E<gt>set_volume ($volume)>

Unconditionally set the volume ivar.

=item B<($volume, $basepath, $directory, $name, @extensions) = $obj-E<gt>splitpath ($filepath)>

Returns all the elements of the pathname as a list. Undef or blank $filepaths
are allowed and leave the object in the init state. Completely reinitializes
the object for the name $filepath. Would return scalar undef on failure if I
could think of anything that could fail...

=item B<$volume = $obj-E<gt>volume>

Return the volume name string.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

=over 4

=item B<$obj= $obj-E<gt>_init>

Internal initializer.

This method is for the subclass initializer chaining and should not be used
otherwise.

=item B<$obj = $obj-E<gt>_append_extensions_to_tail>

Internal parse helper function. Examines 'tail' ivar to see if it is defined;
if it is, the contents are used as the name of a second ivar. That ivar
should contain the rightmost portion of the original filename. The extensions
are appended to that and returned as the value.

It sets all fields to undef or zero as appropriate. This ensures all 
required fields exist, even if we do not store to them later.

This method is for the subclass convenience and should not be used otherwise.

Subclasses use this method internally, but it is not intended for use 
outside of the family as it were.

=item B<$obj = $obj-E<gt>_err ($msg)>

Internal error handling. Doesn't print format error problems at the point of
occurence. We also do not want to die or log at that point. So we just save
it until we are ready to deal with it. 

This method is for the subclass convenience  and should not be used otherwise.

Subclasses use this method internally, but it is not intended for use outside
of the family as it were.

=item B<$tailext = $obj-E<gt>_parse_extensions_from_tail>

Break a string up into dot delimited lexemes. The leftmost string is
returned as value and assumed to not be an extension; the rest of the string
is stored as 'extensions'; the rightmost extension is stored as 'extension'.
If there are no extensions, both are undef.

'tail' will always be set to the name of the rightmost syntactic entity 
found thus far. Extensions will thus be parsed off the last, smallest, 
rightmost entity of which we are aware.

Returns the portion of tail string left of first dot or the entire string if 
no dots. It will be an empty string if dot is the first character.

=back 4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

File::Spec::Unix, Fault::DebugPrinter

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: BaseParse.pm,v $
# Revision 1.3  2008-08-28 23:32:45  amon
# perldoc section regularization.
#
# Revision 1.2  2008-08-16 17:49:06  amon
# Update source format, documentation; switch to Fault package
#
# Revision 1.1.1.1  2004-08-29 16:02:48  amon
# File Spec extensions for doc name formats.
#
# 20040820      Dale Amon <amon@islandone.org>
#		Changed File::Spec:ArchiveBase to File::Spec::BaseParse.
#		Changed 'category' to the more general 'directory', as
#		it really is just the leftmost directory; 'basepath' is
#		the rest of the path before that directory.
#
# 20040815      Dale Amon <amon@islandone.org>
#		Changed File::Spec:Archivist to File::Spec::ArchiveBase
#
# 20021208      Dale Amon <amon@vnl.com>
#		Hacked it apart into a Class hierarchy.
#
# 20021121      Dale Amon <amon@vnl.com>
#               Created FileSpecArchive.
#
1;
