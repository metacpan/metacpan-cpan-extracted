#!perl -T

use Test::More tests => 1;

BEGIN
{
    use_ok('File::Find::Rule::Age') || BAIL_OUT "Couldn't load File::Find::Rule::Age!";
}

diag("Testing File::Find::Rule::Age $File::Find::Rule::Age::VERSION, Perl $], $^X");
