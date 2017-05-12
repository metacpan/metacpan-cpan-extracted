#!perl
use strict;
use Test::More (tests => 4);
BEGIN
{
    use_ok("File::MMagic::XS");
}

my $fm = File::MMagic::XS->new;

ok ! $fm->error;
ok !$fm->fsmagic("t/non-existent");

my $error = $fm->error;
ok $error, qr/No such file/;

