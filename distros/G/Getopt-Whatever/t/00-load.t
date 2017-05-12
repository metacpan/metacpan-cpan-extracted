#!perl

use Test::More tests => 1;

BEGIN {
    use_ok('Getopt::Whatever');
}

diag("Testing Getopt::Whatever $Getopt::Whatever::VERSION, Perl $], $^X");
