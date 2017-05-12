#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes;
use Benchmark::Forking qw( :all );

use lib './lib';
use lib '../lib';

use File::Util;
use File::Find::Rule;

my $f = File::Util->new();

# some dir with several subdirs (and .pod files preferably)
my $dir = shift @ARGV || '.';

print "\nNON-RECURSIVE\n";
cmpthese
   10_000,
   {
      'File::Util'       => sub { $f->list_dir( $dir => { files_only => 1 } ) },
      'File::Find::Rule' => sub { File::Find::Rule->maxdepth(1)->file->in( $dir ) },
   };

print "\nNON-RECURSIVE WITH REGEXES\n";
cmpthese
   10_000,
   {
      'File::Util'       => sub { $f->list_dir( $dir => { files_only => 1, files_match => qr/\.pod$/ } ) },
      'File::Find::Rule' => sub { File::Find::Rule->maxdepth(1)->file->name( qr/\.pod$/ )->in( $dir ) },
   };

print "\nRECURSIVE\n";
cmpthese
   400,
   {
      'File::Util'       => sub { $f->list_dir( $dir => { recurse => 1, files_only => 1 } ) },
      'File::Find::Rule' => sub { File::Find::Rule->file->in( $dir ) },
   };

print "\nRECURSIVE WITH REGEXES\n";
cmpthese
   400,
   {
      'File::Util'       => sub { $f->list_dir( $dir => { recurse => 1, files_only => 1, files_match => qr/\.pod$/ } ) },
      'File::Find::Rule' => sub { File::Find::Rule->file->name( qr/\.pod$/ )->in( $dir ) },
   };

__END__

----------------------------------------------------------------------
Mon Feb 25 12:30:03 CST 2013
----------------------------------------------------------------------
TEST - 1045 files, 32 directories varying from one to 4 levels deep
----------------------------------------------------------------------

NON-RECURSIVE
                    Rate File::Find::Rule       File::Util
File::Find::Rule  2128/s               --             -80%
File::Util       10753/s             405%               --

NON-RECURSIVE WITH REGEXES
                   Rate File::Find::Rule       File::Util
File::Find::Rule 2375/s               --             -70%
File::Util       7937/s             234%               --

RECURSIVE
                   Rate File::Find::Rule       File::Util
File::Find::Rule 72.2/s               --             -55%
File::Util        160/s             122%               --

RECURSIVE WITH REGEXES
                   Rate File::Find::Rule       File::Util
File::Find::Rule 87.9/s               --             -42%
File::Util        153/s              74%               --


