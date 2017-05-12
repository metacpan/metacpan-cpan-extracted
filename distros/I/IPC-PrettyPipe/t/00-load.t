#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('IPC::PrettyPipe');
}

diag( "Testing IPC::PrettyPipe $IPC::PrettyPipe::VERSION, Perl $], $^X" );
