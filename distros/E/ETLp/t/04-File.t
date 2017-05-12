#!perl 
use FindBin qw($Bin);
use lib "$Bin/lib";
use ETLp::Test::File;

ETLp::Test::File->runtests;
