use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

lives_ok { use File::Find::Declare } 'File::Find::Declare loaded ok';
lives_ok { require File::Find::Declare } 'File::Find::Declare required ok';
