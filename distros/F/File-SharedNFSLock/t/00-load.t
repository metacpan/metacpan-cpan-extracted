#! perl

use strict;
use warnings;
use Test::More;

BEGIN {
   use_ok('File::SharedNFSLock')
};

diag( "Testing File::SharedNFSLock $File::SharedNFSLock::VERSION, Perl $], $^X" );

done_testing();
