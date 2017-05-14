#!/usr/bin/perl

# This test is used to ensure that the new_commmand method does not
# accept any arguments. Some users have attempted to use new_command
# as some sort of constructor, or special version of new()... This
# should make that very clear.

use strict;
use FindBin qw($Bin);
use File::Which;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $req = Grid::Request::Test->get_test_request();
$req->command(which("echo"));

undef $@;
eval {
    $req->new_command("garbage");
};

ok($@, "Calling new_command with a scalar argument yielded an exception");

undef $@;
eval {
    my @args = (1, 2, 3);
    $req->new_command(@args);
};
ok($@, "Calling new_command with a list of arguments yielded an exception");
