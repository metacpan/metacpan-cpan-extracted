use strict;
use warnings;
use v5.10;
use File::Hotfolder;

# watch a given directory and print all events
watch( 
    watch => ($ARGV[0] // '.'),
    print => HOTFOLDER_ALL,
)->loop;
