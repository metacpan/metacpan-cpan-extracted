#!/bin/perl

  use strict;
  use warnings;

  use File::TVShow::Organize;

  my $obj = File::TVShow::Organize->new({
            Exceptions => 'S.W.A.T.2017:S.W.A.T 2017'
            });

  $obj->new_show_folder("/tmp/");
  $obj->show_folder("/absolute/path/to/TV Shows");

  if((!defined $obj->new_show_folder()) || (!defined $obj->show_folder())) {
    print "Verify your paths. Something is wrong\n";
    exit;
  }

  # Create a hash for matching file name to Folders
  $obj->create_show_hash();

  # Delete files after processing. The default is to rename the files by appending ".done"
  $obj->delete(1);

  # Do not create sub folders under the the show's parent folder. All files should be dumped
  # into the parent folder. The default is to create season folders.
  $obj->season_folder(0);

  # Batch process a folder containing TV Show files
  $obj->process_new_shows();

  # Report any file names which could not be handled automatically.
  $obj->were_there_errors();

  #end of program
