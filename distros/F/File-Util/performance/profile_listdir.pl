#!/usr/bin/perl

# perl -d:NYTProf performance/profile_listdir.pl

use strict;
use warnings;

use lib './lib';
use lib '../lib';

use File::Util;

my $f   = File::Util->new();
my $dir = shift @ARGV || '.';

for ( 0 .. 99 )
{
   $f->list_dir( $dir => { recurse => 1, files_only => 1, files_match => qr/\.pod$/ } );
}

__END__

