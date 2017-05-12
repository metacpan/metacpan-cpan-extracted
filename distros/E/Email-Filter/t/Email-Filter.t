use Test::More 'no_plan';
use strict;
$^W = 1;
use File::Temp qw(tmpnam);
use_ok("Email::Filter");

open IN, "t/josey-nofold" or die $!;
my $mail;
{local $/; $mail = <IN>; }

my $x = Email::Filter->new(data => $mail);
isa_ok($x, "Email::Filter");
is($x->{noexit}, 0, "exit flag set correctly");

$x->exit(0);
is($x->{noexit}, 1, "exit flag set correctly");

my $where = tmpnam();
ok(!-f $where, "Just testing... (Going to $where)");
$x->accept($where);
ok(-f $where, "Delivered OK");
unlink $where;

my $y = $x->pipe("$^X", "-pe1"); # A sort of portable /bin/cat
is($y, $mail, "pipe works");

my $z = $x->pipe("$^X -pe1");
is $z, undef, 'pipe failed for broken input';
