#!perl -T

use Test::More tests => 1;

BEGIN
{
    use_ok('File::ConfigDir') || BAIL_OUT "Couldn't load File::ConfigDir";
}

diag("Testing File::ConfigDir $File::ConfigDir::VERSION, Perl $], $^X");
