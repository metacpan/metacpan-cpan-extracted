#!/bin/perl

# This is used during development to confirm code works in my local environment.
# before I do a make install for the module.
#use lib "/Users/aspann/dev/BAS-TVShow-Organize/lib/";

# Note I do not personally do any case testing as I have been using this code
# for some time and am very familiar with its operation.

use strict;
use warnings;

use File::TVShow::Organize;

my $obj = File::TVShow::Organize->new({
            Exceptions => 'S.W.A.T.2017:S.W.A.T 2017'
            });

$obj->new_show_folder("/Volumes/Drobo/completed");
$obj->show_folder("/Volumes/Drobo/TV Shows");

$obj->create_show_hash();

$obj->process_new_shows();

# if you wish to use the plex command here you will need to check what number
# matches your TV Library to trigger a reload of the correct items.
# See https://support.plex.tv/articles/201242707-plex-media-scanner-via-command-line/ for details.
my $plexCommand = "/Applications/Plex\\ Media\\ Server.app/Contents\\/MacOS\\/Plex\\ Media\\ Scanner -s -c 1 > /dev/null 2>&1";

system($plexCommand);

exit 0;
