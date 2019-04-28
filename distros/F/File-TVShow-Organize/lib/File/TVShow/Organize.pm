package File::TVShow::Organize;

use strict;
use warnings;
use Carp;
use File::Path qw(make_path);
use File::Copy;
use File::TVShow::Info;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.32';

# Preloaded methods go here.

sub new
{
  my ($class, $args) = @_;
  my $self = {
        #default data and states. Other data is created and stored during
        #program execution
        countries => "(UK|US)",
        delete => 0,
        verbose => 0,
        recursion => 0,
        seasonFolder => 1,
        exceptionListSource => $args->{Exceptions} || undef,
             };

  bless $self, $class;

  ## Additional constructor code goes here.

  if (!defined $self->{exceptionListSource}) {
  ## Do nothing
  } else {
    # create an array of pairs seperated by | character
    my @list1 = split /\|/, $self->{exceptionListSource};
    # now split each item in the array with by the : character use the first
    # value as the key and the second as value
    foreach my $item(@list1) {
      my ($key, $value) = split(/:/, $item);
      $self->{_exceptionList}{$key} = $value;
    }
  }
  return $self;
}

sub countries {

  # Set and get countries in case you want to change or add to the defaults
  # use | as your separator
  my ($self, $countries) = @_;
  $self->{countries} = $countries if defined $countries;
  return $self->{countries};
}

sub show_folder {
  # Set and get path for where new shows are to be stored in the file system
  my ($self, $path) = @_;
  if (defined $path) {
    if ((-e $path) and (-d $path)) {
      $self->{showFolder} = $path;
      # Append / if missing from path
      if ($self->{showFolder} !~ m/.*\/$/) {
        $self->{showFolder} = $self->{showFolder} . '/';
      }
    } else {
      $self->{showFolder} = undef;
    }
  }
  return $self->{showFolder};
}

sub new_show_folder {
  # Set and get path to find new files to be moved from live
  my ($self, $path) = @_;
  if (defined $path) {
    if ((-e $path) and (-d $path)) {
      $self->{newShowFolder} = $path;
      # Append / if missing from path
      if ($self->{newShowFolder} !~ m/.*\/$/) {
        $self->{newShowFolder} = $self->{newShowFolder} . '/';
      }
    } else {
      $self->{newShowFolder} = undef;
    }
  }
  return $self->{newShowFolder};
}

sub create_show_hash {

  my ($self) = @_;

  # exit loudly if the path has not been defined by the time this is called
  croak unless defined($self->{showFolder});

  # Get the root path of the TV Show folder
  my $directory = $self->show_folder();
  my $showNameHolder;

  opendir(DIR, $directory) or die $!;
  while (my $file = readdir(DIR)) {
    next if ($file =~ m/^\./); # skip hidden files and folders
    chomp($file); # trim and end of line character
    # create the inital hash strings are converted to lower case so
    # "Doctor Who (2005)" becomes
    # "doctor who (2005)" key="doctor who (2005), path="Doctor Who (2005)
    $self->{shows}{lc($file)}{path} = $file;
    # hanle if there is US or UK in the show name
    if ($file =~ m/\s\(?$self->{countries}\)?$/i) {
      $showNameHolder = $file;
      # name minus country in $1 country in $2
      $showNameHolder =~ s/(.*) \(?($self->{countries})\)?/$1/gi;
      #catinate them together again with () around country
      #This is now another key to the same path
      $self->{shows}{lc($showNameHolder . " ($2)")}{path} = $file;
      # create a key to the same path again with out country unless one has
      # been already defined by another show
      # this handles something like "Prey" which has a "Prey US" version
      # and "Prey UK"
      $self->{shows}{lc($showNameHolder)}{path} = $file unless (exists $self->{shows}{lc($showNameHolder)});
    }
    # Handle shows with Year extensions in the same manner has UK|USA
    if ($file =~ m/\s\(?\d{4}\)?$/i) {
      $showNameHolder = $file;
      $showNameHolder =~ s/(.*) \(?(\d\d\d\d)\)?/$1/gi;
      $self->{shows}{lc($showNameHolder . " ($2)")}{path} = $file;
      $self->{shows}{lc($showNameHolder . " $2")}{path} = $file;
      $self->{shows}{lc($showNameHolder)}{path} = $file unless
        (exists $self->{shows}{lc($showNameHolder)});
    }
  }
  closedir(DIR);
  # Does this need to return anything or can it just return $self
  return $self->{shows};

}

sub clear_show_hash {
  my ($self) = @_;

  $self->{shows} = ();
  return $self;
}

sub show_path {

  # Access the shows hash and return the correct directory path for the show
  # name as passed to the funtion
  my ($self, $show) = @_;
  return $self->{shows}{lc($show)}{path};
}

sub process_new_shows {

  my ($self, $curr_dir) = @_;
  $curr_dir = $self->new_show_folder() unless defined($curr_dir);

  my $destination;

  opendir(DIR, $curr_dir) or die $!;
  while (my $file = readdir(DIR)) {
    $destination = undef;
    ## Skip hiddenfiles
    next if ($file =~ m/^\./);
    ## Trim the file name incase of end of line marker
    chomp($file);
    ## Skip files that have been processed before. They have had .done appended
    # to to them.
    next if ($file =~ m/\.done$/);
    if (!$self->recursion) {
      next if -d $self->new_show_folder() . $file; ## Skip non-Files
    } else {
      $self->process_new_shows($curr_dir . $file . "/") if -d $curr_dir . $file;
    };
    # next if ($file !~ m/s\d\de\d\d/i); # skip if SXXEXX is not present in file name
    my $showData;
    # Extract show name, Season and Episode
    #$showData = Video::Filename::new($file);
    $showData = File::TVShow::Info->new($file);
    next if !$showData->is_tv_show();
    # Apply special handling if the show is in the _exceptionList
    if (exists $self->{_exceptionList}{$showData->{organize_name}}) { ##Handle special cases like "S.W.A.T"
      # Replace the original name value with the one found in _exceptionList
      $showData->{organize_name} = $self->{_exceptionList}{$showData->{organize_name}};
    } else {
      # Handle normally using '.' as the space marker name "Somthing.this" becomes "Something this"
      # Strip periods from name.
      $showData->{organize_name} =~ s/\./ /g;
    }

    # If we don't have a show_path skip. Probably an unhandled show name
    # store it in the UnhandledFileNames hash for reporting later.
    if (!defined $self->show_path($showData->{organize_name})) {
      $self->{UnhandledFileNames}{$file} = $showData->{organize_name};
      next;
    }
    # Create the path string for storing the file in the right place
    $destination = $self->show_folder() . $self->show_path($showData->{organize_name});
    # if this is true. Update the $destination and create the season subfolder if required.
    # if this is false. Do not append the season folder. files should just be stored in the root of the show folder.
    if($self->season_folder()) {
      $destination = $self->create_season_folder($destination, int($showData->{season}));
    };
    # Import the file. This will use rsync to copy the file into place and either rename or delete.
    # see move_show() for implementation details
    $self->move_show($destination, $curr_dir, $file);
  }
  close(DIR);
  return;
  #return $self;
}

sub were_there_errors {

  my ($self) = @_;

  # Check if there has been any files that Video::Filename could not handle
  # Check that the hash UnHandledFileNames has actually been created before
  # checking that is is not empty or you will get an error.
  if ((defined $self->{UnhandledFileNames}) && (keys $self->{UnhandledFileNames})) {
    print "\nThere were unhandled files in the directory\n";
    print "consider adding them to the exceptionList\n###\n";
    foreach my $key (keys $self->{UnhandledFileNames}) {
      print "### " .  $key . " ==> " . $self->{UnhandledFileNames}{$key} . "\n";
    }
    print "###\n";
  }

  return $self;
}

sub delete {

  my ($self, $delete) = @_;

  return $self->{delete} if(@_ == 1);

  if (($delete =~ m/[[:alpha:]]/) || ($delete != 0) && ($delete != 1)) {
    print STDERR "Invalid arguments passed. Value not updated\n";
    return undef;
  } else {
    if ($delete == 1) {
      $self->{delete} = 1;
    } elsif ($delete == 0) {
      $self->{delete} = 0;
    }

    # This return seems like its on a branch of code that is of litle use.
    # Unless the return is checked on being set.

    return $self->{delete};
  }
}

sub recursion {

  my ($self, $recursion) = @_;

  return $self->{recursion} if(@_ == 1);

  if (($recursion =~ m/[[:alpha:]]/) || ($recursion != 0) && ($recursion != 1)) {
    print STDERR "Invalid arguments passed. Value not updated\n";
    return undef;
  } else {
    if ($recursion == 1) {
      $self->{recursion} = 1;
    } elsif ($recursion == 0) {
      $self->{recursion} = 0;
    }

    # This return seems like its on a branch of code that is of litle use.
    # Unless the return is checked on being set.
    return $self->{recursion};
  }
}

sub verbose {
   my ($self, $verbose) = @_;

  return $self->{verbose} if(@_ == 1);

  if (($verbose =~ m/[[:alpha:]]/) || ($verbose != 0) && ($verbose != 1)) {
    print STDERR "\n### Invalid arguments passed. Value not updated\n";
    return undef;
  } else {
    if ($verbose == 1) {
      $self->{verbose} = 1;
    } elsif ($verbose == 0) {
      $self->{verbose} = 0;
    }
    # This return seems like its on a branch of code that is of litle use.
    # Unless the return is checked on being set.

    return $self->{verbose};
  }
}

sub season_folder {
   my ($self, $seasonFolder) = @_;

  return $self->{seasonFolder} if(@_ == 1);

  if (($seasonFolder =~ m/[[:alpha:]]/) || ($seasonFolder != 0) && ($seasonFolder != 1)) {
    print STDERR "\n### Invalid arguments passed. Value not updated\n";
    return undef;
  } else {
    if ($seasonFolder == 1) {
      $self->{seasonFolder} = 1;
    } elsif ($seasonFolder == 0) {
      $self->{seasonFolder} = 0;
    }
    # This return seems like its on a branch of code that is of litle use.
    # Unless the return is checked on being set.
    return $self->{seasonFolder};
  }
}

sub create_season_folder {

  my ($self, $_path, $season) = @_;

  my $path = $_path .  '/';

  if ($season == 0) {
    $path = $path . 'Specials'
  } else {
    $path = $path . 'Season' . $season;
  }
  # Show Season folder being created if verbose mode is true.
  if($self->verbose) {
    make_path($path, { verbose => 1 }) unless -e $path;
  } else {
    # Verbose mode is false so work silently.
    make_path($path) unless -e $path;
  }
  return $path;
}


sub move_show {

  my ($self, $destination, $source, $file) = @_;

  # If the destination folder or source filder are not defined or no file is
  # passed exit with errors
  carp "Destination not passed." unless defined($destination);
  carp "Source not passed." unless defined($source);
  carp "File not passed." unless defined($file);

  # rewrite paths so they are rsync friendly. This means escape spaces and
  # other special characters.
  ($destination, $source) = _rsync_prep ($destination,$source);

  # create the command string to be used in system() call
  # Set --progress if verbose is true
  my $command = "rsync -ta ";
  $command = $command . "--progress " if ($self->verbose);
  $command = $command . $source . $file . " " . $destination;

  system($command);

  if($? == 0) {
    # If delete is true unlink file.
    if($self->delete) {
      unlink($source . $file);
    } else {
      # delete is false so merely rename the file by appending .done
      move($source . $file, $source . $file . ".done")
    }
  } else {
    #report failed processing? Error on rsync command return code
    print "## Something went very wrong. Rsync failed for some reason.\n";
    print "## rsync err $?\n";
  }
  return $self;

}

# This interal sub-routine prepares paths for use with external rsynch command
# Need to escape special characters
sub _rsync_prep  {

  my ($dest, $source) = @_;

  # escape spaces and () characters to work with the rsync command.
  $dest =~ s/\(/\\(/g;
  $dest =~ s/\)/\\)/g;
  $dest =~ s/ /\\ /g;
  $dest = $dest . "/";

  $source =~ s/ /\\ /g;
  #$source = $source . "/";

  return $dest, $source;
}

1;


__END__

=head1 NAME


File::TVShow::Organize - Perl module to move TVShow Files into their
matching Show Folder on a media server.

=head1 SYNOPSIS

  use File::TVShow::Organize;

  our $exceptionList = "S.W.A.T.2017:S.W.A.T 2017|Other:other";

  my $obj = File::TVShow::Organize->new();

  $obj->new_show_folder("/tmp/");
  $obj->show_folder("/absolute/path/to/TV Shows");

  if((!defined $obj->new_show_folder()) || (!defined $obj->show_folder())) {
    print "Verify your paths. Something in wrong\n";
    exit;
  }

  # Create a hash for matching file name to Folders
  $obj->create_show_hash();

  # Delete files are processing.
  $obj->delete(1);

  # Don't create sub Season folders under the root show name folder.
  # Instead just dump them all into the root folder
  $obj->season_folder(0);

  # Batch process a folder containing TVShow files
  $obj->process_new_shows();

  # Report any file names which could not be handled automatically.
  $obj->were_there_errors();

  #end of program


=head1 DESCRIPTION


This module moves TV show files from the folder where they currently exist into the correct folder based on
show name and season.

    Folder structure: /base/folder/Castle -> Season1 -> Castle.S01E01.avi
                                             Season2 -> Castle.S02E01.avi
                                             Specials -> Castle.S00E01.avi

This season folder behaviour can be disabled by calling season_folder(0). In this case
all files are simply placed under Castle without sorting into season folders.

Source files are renamed or deleted upon successful relocation.
This depends on the state of delete(). The default is to rename the files and not to delete.
See delete() for more details.

Possible uses might include moving the files from an original rip directory and moving them into the correct
folder structure for media servers such as Plex or Kodi. Another use might be to sort shows that are already
in a single folder and to move them to a season by season or Special folder struture for better folder
management.

This module does not examine file encodings and only parses the initial file naming. "name.SXXEXX.*" anything after
SXXEXX is ignored with the exception that files ending in ".done" are also ignored by the module. These files will
have already been successfully processed in previous executions of code using this module.


Works on Mac OS and *nix systems.

=head1 Methods

=head2 new

  Arguments: None or { Exeptions => 'MatchCase:DesiredValue'}

  $obj = File::TVShow::Organize->new();

  $obj = File::TVShow::Organize->new({ Exceptions =>
    'MatchCase:DesiredValue' })

  This subroutine creates a new object of type File::TVShow::Organize

  If Exceptions is passed to the method we load this data into a hash
  for later use to handle naming complications.

  E.G file: S.W.A.T.2017.S01E01.avi is not handled correctly by Video::Filename
  so we need to know to handle this differently. Exceptions is an optional
  parameter and can be left out when calling new().
  Currently Exceptions is a scalar string.
  Its format is "MatchCase:DesiredValue|MatchCase:DesiredValue"

=head2 countries

  Arguments: String: Note the format below is used as part of a regex
              check in the module.
             As such () should always be included at the start and end of the
              string.

  $obj->countries("(US|UK|AU)");
  $obj->countries();

  This subroutine sets the countries internal value and returns it.

  Default value: (UK|US)


  This allows the system to match against programs names such as
  Agent X US / Agent X (US) / Agent X and reference the same single folder

=head2 show_folder

  Arguments: None or String

  Set the path return undef is the path is invalid
  $obj->show_folder("/path/to/folder");

  Return the path to the folder
  $obj->show_folder();

  Always confirm this does not return undef before using.
  undef will be returned if the path is invalid.

  Also a valid "path/to/folder" will always return with the "/" having been
  appended. "path/to/folder/"

  This is where the TV Show Folder resides on the file system.

  If the path is invalid this would leave the internal value as being undef.


=head2 new_show_folder

  Arguments: None or String

  Set the path return undef is the path is invalid
  $obj->new_show_folder("/path/to/folder");

  Return the path to the folder
  $obj->new_show_folder();

  Always confirm this does not return undef before using.
  undef will be returned if the path is invalid.

  Also a valid "path/to/folder" will always return with the "/" having been
  appened. "path/to/folder/"

  This is where new files to be add to the TV Show store reside on the
  file system.

=head2 create_show_hash

  Arguments: None

  $obj->create_show_hash;

  This function creates a hash of show names with the correct path to store
  data based on the directories that are found in showFolder.

  Examples:
	Life on Mars (US) creates 3 keys which point to the same folder
					key: life on mars (us) => folder: Life on Mars (US)
					key: life on mars us   => folder: Life on Mars (US)
					key: life on mars      => folder: Life on Mars (US)

	However if there already exists a folder: "Life on Mars" and a folder "Life on Mars (US)"
	the following hash key:folder pairs will be created. Note that the folderis differ
					key: life on mars      => folder: Life on Mars
					key: life on mars (us) => folder: Life on Mars (US)
					key: life on mars us   => folder: Life on Mars (US)

  As such file naming relating to country of origin is important if you are
  moving versions of the same show based on country.

=head2 clear_show_hash

  Arguments: None

  This function clears the ShowHash data so that create_show_hash can be run
  again before or after a folder change which might occur if show_folder() were
  to be set to a new folder.

=head2 show_path

  Arguments: String

  $obj->show_path("Life on Mars US") returns the name of the folder "Life on Mars (US)"
  or undef if "Life on Mars US" does not exist as a key.

  No key will be found if there was no folder found when $obj->create_show_hash was called.

  Example:

  my $file = Video::Filename::new("Life.on.Mars.(US).S01E01.avi", { spaces => '.' });

  # $file->{name} now contains "Life on Mars (US)"
  # $file->{season} now contains "01"

  my $dest = "/path/to/basefolder/" . $obj->show_path($file->{name});
  result => $dest now cotains "/path/to/basefolder/Life on Mars (US)/"

  $dest = $obj->create_season_folder($dest,$file->{season});
  result => $dest now contains "/path/to/basefolder/Life on Mars (US)/Season1/"

=head2 process_new_shows

  Arguments: None

  $obj->process_new_shows();


  This function requires that $obj->show_folder("/absolute/path") and
  $obj->new_show_folder("/absoute/path") have already been called as their paths
  will be used in this function call.

  This is the main process for batch processing of a folder of show files.
  Hidden files, files ending in ".done" as well as directories are excluded
  from being processed.

  This function will process a single folder and no deeper if recursion is not
  enabled.
  If recursion is enabled it will process any sub folders that it finds from
  the initial folder.

=head2 move_show

  Arguments: String, String, String
  The first arguement is the folder where the file is to be moved into
  The Second argument is the source folder where the new show file currently
  exists.
  The third argument is the file which is to be moved.

  $obj->move_show("/absolute/path/to/destintaion/folder/",
  "absolute/path/to/source/folder/", "file");

  This function does the heavy lifting of actually moving the show file into
  the determined folder.
  This function is called by process_new_shows which does the work to
  determine the paths to folder and file.

  This function could be called on its own after you have verified "folder"
  and "file"

  It uses a system() call to rsync which always checks that the copy was
  successful.

  This function then checks the state of $obj->delete to determine if the
  processed file should be renamed "file.done" or should be removed using
  unlink(). Note delete(1) should be called before process_new_shows() if you
  wish to delete the processed file. By default the file is only renamed.

=head2 delete

  Arguments: None,0,1

  $obj->delete return the current true or false state (1 or 0)
  $obj->delete(0) set delete to false
  $obj->delete(1) set delete to true

  Input should be 0 or 1. 0 being do not delete. 1 being delete.

  Set if we should delete source file after successfully moving it to the tv
  store or if we should rename it to $file.done


  The default is false and the file is simply renamed.

  Return undef if the varible passed to the function is not valid. Do not change
  the current state of delete.

=head2 recursion

  Arguments None,0,1

  $obj->recursion returns the current true or false state (1 or 0)
  $obj->recursion(0) set recursion to false
  $obj->recursion(1) set recursion to true

  This controls the behaviour of process_new_shows();

=head2 season_folder

  Arguments: None,0,1

  $obj->season_folder return the current true or false state (1 or 0)
  $obj->season_folder(0) or season_folder(1) sets and returns the new value.
  $obj->season_folder() returns undef if the input is invalid and the internal
  state is unchanged.

  if(!defined $obj->season_folder("x")) {
    print "You passed and invalid value\n";
  }

  The default is true.

=head2 were_there_errors

  Arguments: None

  $obj->were_there_errors;


  This should be called at the end of the program to report if any file names
  could not be handled correctly resulting in files not being processed. These
  missed files can then be manually moved or their show name can be added to
  the exceptionList variable. Remember to match the NAME preceeding SXX and to
  give the corrected name

  EG S.W.A.T.2017.SXX should get an entry such as:
  exceptionList = "S.W.A.T.2017:S.W.A.T 2017";

=head2 create_season_folder

  Arguments: String, Number

  The first argument is the current folder that the file should be moved to
  The second argument is the season number.

  $obj->create_season_folder("/absolute/path/to/show/folder/",$seasonNumber)

  This creates a folder within "/absolute/path/to/show/folder/" by calling
  make_path() returns the newly created path
  "absolute/path/to/show/folder/SeasonX/" or
  "/absolute/path/to/show/folder/Specials/"

  note: "/absolute/path/to/show/folder/" is not verified to be valid and is
  assumed to have been checked before being passed

  Based on SXX
  S01 creates Season1
  S00 creates Specials

=head2 verbose

  Arguments: None,0,1

  $obj->verbose();
  $obj->verbose(0);
  $obj->verbose(1);

  Return undef if passed an invalid imput and write to STDERR. Current value
  of verbose is not changed. Return 0 if verbose mode is off. Return 1 if
  verbose mode is on.

  This state is checked by create_season_folder(), move_show()
  This allows to system to give some user feedback on what is being done if you
  want to watch the module working.

=head1 Examples

=head2 Do not create season folders

  #!/bin/perl

  use strict;
  use warnings;

  use File::TVShow::Organize;

  my $obj = File::TVShow::Organize->new();

  $obj->new_show_folder("/tmp/");
  $obj->show_folder("/absolute/path/to/TV Shows");

  if((!defined $obj->new_show_folder()) || (!defined $obj->show_folder())) {
    print "Verify your paths. Something in wrong\n";
    exit;
  }

  # Create a hash for matching file name to Folders
  $obj->create_show_hash();

  # Don't create sub Season folders under the root show name folder.
  # Instead just dump them all into the root folder
  $obj->season_folder(0);

  # Batch process a folder containing TVShow files
  $obj->process_new_shows();

  # Report any file names which could not be handled automatically.
  $obj->were_there_errors();

=head2 Process two different source folders.

  #!/bin/perl

  use strict;
  use warnings;

  use File::TVShow::Organize;
  my $obj = File::TVShow::Organize->new();

  $obj->new_show_folder("/tmp/");
  $obj->show_folder("/absolute/path/to/TV Shows");

  if((!defined $obj->new_show_folder()) || (!defined $obj->show_folder())) {
    print "Verify your paths. Something in wrong\n";
    exit;
  }

  # Create a hash for matching file name to Folders
  $obj->create_show_hash();

  # Batch process first folder containing TVShow files
  $obj->new_show_folder("/tmp/");
  $obj->process_new_shows();

  # Batch process second folder containing TVShow files.
  $obj->new_show_folder("/tmp2/");
  $obj->process_new_shows();

  # Report any file names which could not be handled automatically.
  $obj->were_there_errors();

=head1 INCOMPATIBILITIES

This has not been tested on a windows system and I expect it will not actually
work.

I have not tested anycases where file names might be
"showname.(US).(2003).S0XE0X.avi" as I have no such cases myself.

=head1 SEE ALSO

=over

=item   L<File::Path>

=item   L<File::Copy>

=item   L<Video::Filename>

=back

=head1 AUTHOR

Adam Spann, E<lt>adam_spann@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Adam Spann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
=cut
