#================================ TocFile.pm =================================
# Filename:            TocFile.pm
# Description:         Manage a Table of contents file.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::Logger;
use Fault::DebugPrinter;
use Fault::ErrorHandler;
use DMA::Version;
use DMA::FSM;
use Document::Toc;
use Document::PageId;

package Document::TocFile;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

# .toc file format version this module was designed for.
#
my ($MAJOR,$MINOR) = (0,2);
my $ParseVersion   = DMA::Version->new("%d.%02d",'(\d*).(\d\d)',2,
					     $MAJOR,$MINOR);

#=============================================================================
#				Class Methods
#=============================================================================

sub open {
  # Subclasses can override the argument list definition this way
  my $self                         = bless {}, shift;
  my ($dir,$path,$dates,$document) = $self->_setdirobj ( @_ );

  # Basic initialization of Ivars
  @$self{'filepath', 'contents', 
	 'toc_version','toc_major','toc_minor',
	 'document_title_section','document_dates',
	 'toc_title_section','toc_dates',
	 '_init','_dirty'} = 
    ($path, [], 
     undef, undef,undef,
     $document,$dates,
     undef,undef,
     0,0);

  if ($dir) {
    my $toc = $self->{'filepath'} = $path . "/.toc";
    if (-f $toc) {$self->_read  || (return undef);
		  @$self{'_init','_dirty'} = (1,0);
		  return $self;}

    # Force the creation of an (if necessary) empty .toc file
    # Use document date and name if it is new.
    #
    @$self{'document_dates','document_title_section',
	   'toc_dates','toc_title_section',
	   'toc_version',
	   'toc_major','toc_minor',
	   '_init','_dirty'} = 
	       ($dates, $document,
		$dates, $document,
		$ParseVersion->version,
		$ParseVersion->list->[0],$ParseVersion->list->[1],
		1,1);
    return $self;
  }
  return undef;
}

#-----------------------------------------------------------------------------

sub flush {
  my ($self) = @_;

  Fault::DebugPrinter->dbg (1, "TocFile->flush: Flush tocfile to disk");

  # Update the format version number to the current one just before 
  # writing the output file.
  if ($ParseVersion->version != $self->version) {
    Fault::Logger->log ("Updating TocFile from Format Version " . 
		      $self->version . " to " .
		      $ParseVersion->version);
    @$self{'toc_version',
	   'toc_major','toc_minor',
	   '_dirty'} = 
      ($ParseVersion->version,
       $ParseVersion->list->[0],$ParseVersion->list->[1],
       1);
  }
  return ($self->_write);
}

#-----------------------------------------------------------------------------
# Flush this object to the .toc file on the file system if this object is 
# deemed satisfactory and has not already been flushed. Usually called from
# the Perl GC.

sub DESTROY {my ($self) = @_; $self->{'_init'} && $self->flush;  return $self;}

#=============================================================================
#			Object Methods
#=============================================================================

sub merge {
  my ($self, $toc) = @_;

  (ref($toc))                   || (return undef);
  ($toc->isa ('Document::Toc')) || (return undef);

  foreach my $record (@{$self->{'contents'}}) {
    my ($pagenum, $title, @categories) = @$record;
    
    if (!$toc->addPages ($pagenum)) {
      $self->_err ("Invalid page number in .toc file [$pagenum]");
    }

    # Look for the blank title escape "--"
    if (defined $title) {
      if ($title eq "--") {$title = "";}
      $toc->addPageTitleCategories ($pagenum, $title, @categories);
    }
  }
  return $toc;
}

#-----------------------------------------------------------------------------

sub putFrom {
  my ($self, $toc) = @_;

    Fault::DebugPrinter->dbg
	(1, "TocFile->putFrom: Overwrite tocfile records from $toc");

  (ref($toc))                   || (return undef);
  ($toc->isa ('Document::Toc')) || (return undef);

  # Replace the existing contents with the .toc object data
  $self->{'contents'} = [];
  foreach my $p ($toc->pages) {
    my $cnt = 0;
    foreach my $t ($toc->pageTitles ($p)) {
      my (@c) = $toc->pageTitleCategories($p,$t);
      if ($t eq "") {$t = "--"};
      push @{$self->{'contents'}}, [$p, $t, @c];
      $cnt++;
    }
    ($cnt>0) || push @{$self->{'contents'}}, [$p, undef];
  }

  $self->{'_dirty'} = 1;
  return $toc;
}

#-----------------------------------------------------------------------------

sub mergeFrom {
  my ($self, $toc) = @_;

  Fault::DebugPrinter->dbg (1, "TocFile->mergeFrom: $toc");

  $self->merge ($toc) || (return undef);
  return ($self->putFrom ($toc));
}

#-----------------------------------------------------------------------------

sub document      {return shift->{'document_title_section'};}
sub documentdates {return shift->{'document_dates'};}
sub version       {return shift->{'toc_version'};}
sub major         {return shift->{'toc_major'};}
sub minor         {return shift->{'toc_minor'};}
sub dates         {return shift->{'toc_dates'};}
sub title         {return shift->{'toc_title'};}
sub filepath      {return shift->{'filepath'};}

#=============================================================================
#			   Internal Methods
#=============================================================================
#		      LexAn State Machine functions
#=============================================================================
# Confirm we have a valid version number line.

sub _haveVersion {
  my ($lexeme, $bb) = @_;
  my $version       = $bb->{'vers_obj'};

  if (!$version->setVersion($lexeme))
    { $bb->_err ("Missing or misformatted version: [$lexeme]");
      return (0, $lexeme);
    }
  return (1, $lexeme);
}

#-----------------------------------------------------------------------------
# Save the version early because it has to be here or we're 
# totally in never-never land anyway since we'd not know what format
# to use or whether this is even *our* .toc file!

sub _goodVersion {
  my ($lexeme, $bb) = @_;
  my $version       = $bb->{'vers_obj'};

  @$bb{'toc_version','toc_major','toc_minor'} = 
    ($version->version,$version->list->[0],
     $version->list->[1]);

  # At a future date we will use this to select different input parsers based
  # on the major version so that we can retain enough backward compatibility 
  # to read in old formats so we can rewrite the .toc file in the latest 
  # format.
  #
  if ($bb->{'toc_major'} gt $ParseVersion->list->[0])
    { $bb->_err
	("Cannot interpret a V" .
	 $ParseVersion->version . " .toc file format with a V" .
	 $bb->version . " parser");
      return (0, $lexeme);
    }
  return (1, $lexeme);
}

#-----------------------------------------------------------------------------
# Confirm we have a valid document name line.

sub _haveDocName {
  my ($lexeme, $bb) = @_;

  # In subclasses docspec is an object; here it is just the text contained in
  # the current record.
  # 
  my $docspec = $bb->_validate_documentname ($lexeme);
  if (!defined $docspec) 
    { $bb->_err("Document title error: [$lexeme]");
      return (0, $lexeme);
    }
  @$bb{'toc_title_section','toc_dates'} = 
    ($bb->_split_documentname($docspec));

  # We have a documpent spec and we now have the critical two first lines that
  # allow us to declare we have succesfully opened a .toc file.
  #
  @$bb{'docspec','have_toc'} = ($docspec,1);
  return (1, $lexeme);
}

#-----------------------------------------------------------------------------
# Confirm we have a valid page description line and if so to parse it into 
# fields and stash it in our contents object.
#

sub _getPageLine {
  my ($lexeme, $bb) = @_;
  my $tmp;
  my ($pagenum, $title, @categories) = split (' ', $lexeme);

  my ($start,$end) = split ('-', $pagenum);
  if (!$start) {
    $bb->_err ("Document pagenumber missing: [$lexeme]");
    return (0, $lexeme);}

  if (!Document::PageId->new ($start)) {
    $bb->_err ("Document pagenumber error: [$lexeme]");
    return (0, $lexeme);}
  
  if ($end && !Document::PageId->new ($end)) {
    $bb->_err ("Document end page number error: [$lexeme]");
    return (0, $lexeme);}
  
  # This is an escape for storing blank titles
  if ($title eq "--") {$title = "";}
  else {
    # In subclasses docspec is an object; here it is just the text contained 
    # in the document title record.
    #
    my $docspec = $bb->{'docspec'};
    if (! $bb->_validate_pagetitle ($docspec, $start, $end, $title)) {
      $bb->_err ("Document title error: [$lexeme]");
      return (0, $lexeme);}
  }
  
  push @{$bb->{'contents'}}, [$pagenum, $title, @categories];
  return (1, $lexeme);
}

#-----------------------------------------------------------------------------

sub _noop {my ($lexeme, $bb) = @_; return (1,$lexeme);}

#=============================================================================
# Read using state machine

sub _read {
  my ($self) = @_;
  my ($fd, @toc,@lexemes);
  my $fst = 
    {
     'S0' => ["E0","SAME", \&_haveVersion, "S1","SAME","E0","SAME"],
     'S1' => ["E0","SAME", \&_goodVersion, "S2","NEXT","E0","SAME"],
     'S2' => ["E0","SAME", \&_haveDocName, "S3","NEXT","E0","SAME"],
     'S3' => ["D0","SAME", \&_getPageLine, "S3","NEXT","S3","NEXT"],
     'E0' => ["E0","ERR",  \&_noop,         "","","",""],
     'D0' => ["D0","DONE", \&_noop,         "","","",""],
    };  

  if (!CORE::open ($fd, "<" . $self->{'filepath'})) {
    Fault::ErrorHandler->warn ("Failed to open .toc file!");
    return 0;
  }

  # These files should not be huge so it's faster to get it all in one big 
  # read to avoid I/O blocking.
  #
  @toc = <$fd>;
  close $fd;

  $self->{'vers_obj'} = DMA::Version->new("%d.%02d",'(\d*).(\d\d)',2);
  $self->{'pub_obj'}  = undef;

  if (!defined $self->{'vers_obj'})
    { Fault::ErrorHandler->die 
	("Fatal error while creating empty DMA::Version object");
      return 0;
    }

  # This line screws up emacs formatting. Other than that, skip blank lines
  # and comments, and remove newline from the end if present.
  for ( @toc ) { !(/^\s*$|^\s*#/) || next; chomp $_; push @lexemes, $_; }

  # Parse status is fail until noted otherwise.
  $self->{'have_toc'} = 0;  
  my @remaining = DMA::FSM::FSM ( $fst, $self, @lexemes );
  my $status = $self->{'have_toc'};
  delete @$self{'have_toc','pub_obj','vers_obj','state','docspec'};

  return ($status);
}

#-----------------------------------------------------------------------------

sub _write {
  my ($self) = @_;
  my $fd;
  my $tocfile   = $self->{'filepath'};
  my $tmpfile   = "$tocfile.tmp";

  $self->{'_init'}  || (return 0);
  $self->{'_dirty'} || (return 1);

  # First write the new values to a tmp file.
  if (!CORE::open ($fd, ">$tmpfile")) {
        Fault::ErrorHandler->warn("Failed to open temp file $tmpfile! $!");
    return 0;
  }

  my ($v,$p) = ($ParseVersion->version, $self->_docname);
  
  if (!printf $fd "$v\n") {
        Fault::ErrorHandler->warn 
	    ("Failed to write version record [$v] to $tmpfile: $!");
    return 0;
  }

  if (!printf $fd "$p\n") {
        Fault::ErrorHandler->warn 
	    ("Failed to write document record [$p] to $tmpfile: $!");
    return 0;
  }

  # Convert it all to text records
  my @list;
  foreach my $record (@{$self->{'contents'}}) {
    my ($p, $t, @c) = @$record;
    defined $p || next;
    push @list, ((defined $t) ? "$p $t " . join " ", @c : $p)
  }

  # Now sort and print them. I'd not do this if I expected lists longer
  # than a few hundred lines.
  #
  foreach my $r (sort @list) {
    if (!printf $fd "$r\n") {
          Fault::ErrorHandler->warn 
	      ("Failed to write page record [$r] to $tmpfile: $!");
      return 0;
    }
  }

  if (!close $fd) {
    Fault::ErrorHandler->warn ("Failed to close $tmpfile: $!");
    return 0;
  }

  # Now finalize the changes.
  if (system ("mv","$tmpfile","$tocfile") != 0) {
        Fault::ErrorHandler->warn 
	    ("Failed to move $tmpfile to $tocfile: $!"); 
	return 0;
  }

  $self->{'_dirty'}=0;
  return 1;
}

#-----------------------------------------------------------------------------
# Work around a missing date so we can use this even on undated files.
# Returns document_title_section or document_dates-document_title_section if 
# possible.

sub _docname {
  my $self = shift;
  return $self->{'document_dates'} ? 
    $self->{'document_dates'} . "-" . 
      $self->{'document_title_section'} :
	$self->{'document_title_section'};
}

#-----------------------------------------------------------------------------
# 		open method input list overrides
#-----------------------------------------------------------------------------

sub _setdirobj {
  my ($self, $dir, $date, $name) = @_;
  $dir || (Fault::ErrorHandler->warn
	   ("Missing document directory path or object"), return undef);

  $date || (Fault::ErrorHandler->warn
	   ("Missing document date section"), return undef);

  $name || (Fault::ErrorHandler->warn
	   ("Missing document title section"), return undef);

  (!ref($dir))    || ($dir  = undef);
  return ($dir, "$dir/$date-$name", $date, $name);
}

#-----------------------------------------------------------------------------
# _read method overrides.

sub _validate_documentname {my ($self, $record)  = @_; return $record;}
sub _split_documentname    {my ($self, $docspec) = @_; return ($docspec, "");}

#-----------------------------------------------------------------------------

sub _validate_pagetitle
  { my ($self, $docspec, $start, $end, $title) = @_; return 1;}

sub _err {my ($self, $str) = @_; Fault::ErrorHandler->warn ($str);}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::TocFile - Manage a Table of contents file.

=head1 SYNOPSIS

 use Document::TocFile;

 $obj      = Document:TocFile->open ($path, $date, $title)
 $obj      = $obj->flush
 $toc      = $obj->merge     ($toc)
 $toc      = $obj->putFrom   ($toc)
 $toc      = $obj->mergeFrom ($toc)
 $version  = $obj->version
 $major    = $obj->major
 $minor    = $obj->minor
 $title    = $obj->title
 $dates    = $obj->dates
 $filepath = $obj->filepath
 $title    = $obj->document
 $dates    = $obj->documentdates

=head1 Inheritance

 UNIVERSAL

=head1 Description

This Class manages a table of contents file. The file is always named .toc
and contains formatted records of the following syntax (TocFile Format 
Version 0.02):

	0.02
	<dates>-<document_title_section>
	<pageid> <pagetitle_section> <categorylist>

where the first two lines are required. There may be zero or more occurrences
of the page lines. A category list is just a list of keywords:

	015  TheCatCameBack-ANewLook   Physics Cosmology Space

The Toc format version number will allow us to cleanly upgrade to more
sophisticated file structuring designs in the future. It is the first
item in the .toc file, on a line by itself so a parser may immediately
decide if it will be able to parse the remainder of the file. The minor 
version number is to be incremented if changes are such that a previous
parser will simply not see the additions or changes (changes are upward
compatible); if a change affects the ability of the previous parser to keep
on keepin' on, the major version number is incremented (changes are not
upward compatible). Parsers for a new major version should be able to read
and upgrade all previous versions of the .toc file, perhaps by selection off
the major version number.

=head2 To Do

There is absolutely no protection against more than one application working
with the same .toc file at the same time. This is an area for future
improvement. The same is true of .log and .config files.

=head1 Examples

 use Document::Toc;
 use Document::TocFile;

 my ($path,$date,$title)  = ("~/test","20040902","LinuxJournal-i126");
 my $toc                  = Document::Toc->new ();
 my $foo                  = Document:TocFile->open ($path,$date,$title);

 my $docname_string       = $foo->title;
 my $date_string          = $foo->dates;
 my $version_string       = $foo->version;
 my $major_version_number = $foo->major;
 my $minor_version_number = $foo->minor;
 my $filepath             = $foo->filepath
 my $doctitle             = $foo->document
 my $docdates             = $foo->documentdates
 my $merged_toc           = $foo->merge     ($toc);
 my $flg                  = $foo->flush
    $toc                  = $foo->putFrom   ($merged_toc);
    $toc                  = $foo->merge     ($toc)
    $toc                  = $foo->mergeFrom ($toc)

=head1 Class Variables

 None.

=head1 Instance Variables

 filepath                Full pathname of the .toc file suitable for open and
                         close.
 document_dates          Document date string taken from the filepath.
 document_title_section  Document name string taken from the filepath..
 contents                Array of arrays to hold all the lines of the table of
                         contents data read from the .toc.
 toc_version             Version string taken from the  .toc file.
 toc_major               First element of version string from .toc
 toc_minor               Second element of version string from .toc.
 toc_dates               Document date string taken from the .toc file.
 toc_title_section       Document name string taken from the  .toc file.

=head1 Class Methods

=over 4

=item B<$obj = Document:TocFile-E<gt>open ($path, $date, $title)>

Generate an object to manage the interface with a .toc file in a directory 
named /$path/$date-$title/. The arguments are:

	path to document directory, eg. /home/mypubs/thisdocument/
	document dates              eg. 20040813 
	document-title-section      eg. LinuxManual-PenguinsRule

If there is no .toc file, an 'empty' with just:

	0.02
	$date-$title

in it.. If the file already exists, it is read and if it has a version number
this object knows about, the data is parsed into an internal format. When the
.toc file is next updated, it will be re-written in the Toc File Format Version
used by this object.

The open  method returns undef if it is unable to build a valid document path
name from the input argument list.

=back 4

=head1 Instance Methods

=over 4

=item B<$dates = $obj-E<gt>dates>

Return the date string from the .toc file document name, eg "19991225"

=item B<$title = $obj-E<gt>document>

Return the document title from the input args eg:

 "ReportOnInternationalSecurity-TheThreatModel"

=item B<$dates = $obj-E<gt>documentdates>

Return the date string from the input args, eg "19991225"

=item B<$filepath = $obj-E<gt>filepath>

Return the full pathname of the .toc file, suitable for file open, close, 
etc, eg:

 "/archive/19991225-ReportOnInternationalSecurity-TheThreatModel/.toc"

=item B<$obj  = $obj-E<gt>flush>

Write a new .toc file from the stored data. Writes to a .toc.tmp first then
moves it to .toc. Any error at any point terminates the close before
overwriting the .toc. Only if the system 'mv' itself fails in a race could
.toc be damaged.

flush can be issued any number of times, but will do nothing unless the
contents has changed. 

If the version of this class is different from the version on the .toc, a
rewrite is forced.

If there is no .toc file, a write is forced so that at the very least there
will always be a file with version and document title records in any directory
for which a Document::TocFile object is created.

Flush is called by the DESTROY method, so if our contents have changed in any
of the ways noted above, the .toc file will be rewritten.

[If a reason is found that requires prevention of this behavior, a simple
code modification is to add a method to clear the internal _init flag ivar.]

=item B<$major = $obj-E<gt>major>

Return the major version part of the .toc files' format version number.

=item B<$toc  = $obj-E<gt>merge ($toc)>

Merge the internally stored contents of the .toc file into the supplied
Document::Toc object.  Undef  on failure.

=item B<$toc = $obj-E<gt>mergeFrom ($toc)>

Overwrite page records in the contents array by merging the current contents
with those from the supplied Document::Toc object. Does not rewrite the 
.toc file itself.

=item B<$minor = $obj-E<gt>minor>

Return the minor version part of the .toc files' format version number.

=item B<$toc = $obj-E<gt>putFrom ($toc)>

Replace the internally stored contents of the .toc file with the data from
the supplied Document::Toc object. Does not rewrite the .toc file itself.

Returns undef on failure.

=item B<$title = $obj-E<gt>title>

Return the document title from the associated .toc file eg:

 "ReportOnInternationalSecurity-TheThreatModel"

=item B<$version  = $obj-E<gt>version>

Return the .toc files' format version number string.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

=over 4

=item B<$obj-E<gt>_err ($msg)>

Print a warning message.

=item B<$flg = $obj-E<gt>_read>

Read the and parse the .toc file from a publication directory. Return true
on success; undef if the major version stored in the file is greater than
the major version of this Class or other problems  are found with the file
format.

=item B<($path, $pathname, $dates, $title) = $obj-E<gt>_setdirobj ($path, $dates, $title )>

Subclass may override. Shuffles the input argument list and returns  them in
a list along with a $pathname of  $dir/$date-$name. Why? This is a tricky way
to let subclasses override the open method's input argument list.

Open's entire argument list is passed to this method, uninterpreted. So
whether open takes one  argument or three is entirely dependent what this
method looks for. 

=item B<($toc_title, $toc_dates)  = $obj-E<gt>_split_documentname ($toc_title)>

This method customizes the  behavior of the the .toc file read operation in
the open method. Subclass may override. The first output value is just a copy
of the input argument; the second, the date,  is a null string. This might
change if I decided to do some low level parsing here. Yes, it could use a
File::Spec, but it is intentionally staying as simple an independent as
possible. Child classes will use File::Spec::* when they override this method.

=item B<$documentname = $obj-E<gt>_validate_documentname ($documentname)>

This method customizes the  behavior of the the .toc file read operation in
the open method. Subclass may override. Just moves the input arg to the
output.

=item B<$flg = $obj-E<gt>_validate_pagetitle ($document_title, $stargpage, $endpage, $document_title)>

This method customizes the  behavior of the the .toc file read operation in
the open method. Subclass may override. Always returns true.

=item B<$flg = $obj-E<gt>_write>

Write an updated .toc file to a publication directory with extreme care and 
paranoia. First write a temp file, then copy it over top of the old .toc 
once we're sure all is cool.

If object has not been initialized, fail.

If it has not changed, succeed immediately. Otherwise flush it to disk and
clear _dirty flag.

Returns true on success, false if *all* data does not end up in .toc

=back 4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::Logger, Fault::DebugPrinter, Fault::ErrorHandler, DMA::Version, 
DMA::FSM, Document::Toc, Document::PageId, DMA::ISODate

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: TocFile.pm,v $
# Revision 1.5  2008-08-28 23:26:17  amon
# perldoc section regularization.
#
# Revision 1.4  2008-08-13 21:04:32  amon
# Third phase of reformatting to current standard.
#
# Revision 1.3  2008-08-13 20:56:53  amon
# Second phase of reformatting to current standard.
#
# Revision 1.2  2008-08-13 14:50:02  amon
# First phase of reformatting to current standard.
#
# Revision 1.1.1.1  2004-09-02 13:08:02  amon
# Manages a Document directory
#
# 20040831	Dale Amon <amon@islandone.org>
#		Changing this base class to assume document titles rather
#		than Publication names. I am using it for both cases so
#		I really need the generality. It now uses FSM, my new
#		Finite State Machine class.
#
# 20040813	Dale Amon <amon@islandone.org>
#		Split it into a base class and subclass to make it easier
#		to use in simple applications:
#			Document::TocFile	string args
#			Archivist::TocFile	complex object for arg
#
# 20030107	Dale Amon <amon@vnl.com>
#		Added "--" token to file format to stand in for blank titles.
#		Bumped format version to 0.02
#
# 20021223	Dale Amon <amon@vnl.com>
#		Major rewrite to make it deal only with the file and to
#		be able to fill/merge data with an external .toc file
#		on request rather than managing both the internal and
#		external representations of the .toc simultaneously.
#
# 20021216	Dale Amon <amon@vnl.com>
#		Created. Format version 0.01
1;
