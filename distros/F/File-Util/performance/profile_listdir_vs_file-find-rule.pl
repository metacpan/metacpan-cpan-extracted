#!/usr/bin/perl

# perl -d:NYTProf misc/profile_listdir_vs_file-find-rule.pl

use strict;
use warnings;

use lib './lib';
use lib '../lib';

use File::Util;
use File::Find::Rule;

my $f = File::Util->new();

# some dir with several subdirs (and .pod files preferably)
my $dir = shift @ARGV || '.';

for ( 1 .. 100 ) {

   print "$_\n";

   $f->list_dir( $dir => { recurse => 1, files_only => 1, files_match => qr/\.pod/ } );

   File::Find::Rule->file->name( qr/\.pod$/ )->in( $dir );
}

exit;
