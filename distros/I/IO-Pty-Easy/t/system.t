#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Pty::Easy;

my $pty = IO::Pty::Easy->new;
$pty->spawn("$^X -ple ''");
my $output;
eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 5;
    $output = `$^X -e 'print "foo"'`;
    alarm 0;
};
isnt($@, "alarm\n", "system() didn't time out");
is($output, "foo", "system() got the right value");
$pty->kill;
undef $output;
eval {
    local $SIG{ALRM} = sub { die "alarm2\n" };
    alarm 5;
    $output = `$^X -e 'print "bar"'`;
    alarm 0;
};
isnt($@, "alarm2\n", "system() didn't time out (after kill)");
is($output, "bar", "system() got the right value (after kill)");
$pty->close;

done_testing;
