use strict;
use warnings;
use v5.10;
use File::Hotfolder;

# watch a given directory and delete all new or modified files
watch( $ARGV[0] // '.', delete  => 1, print => DELETE_FILE )->loop;
