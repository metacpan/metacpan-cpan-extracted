#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok ('MRS::Client');
}

diag ("Testing MRS::Client $MRS::Client::VERSION, Perl $^V, $^X");
