#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Digest::PasswordComposer') || print "This is bad\n";
}

diag("Testing Digest::PasswordComposer $Digest::PasswordComposer::VERSION, Perl $], $^X");

