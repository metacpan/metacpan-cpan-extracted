#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use File::Temp;
use Cwd;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

my $cwd = Cwd::getcwd();

my $dir = File::Temp::tempdir( CLEANUP => 1 );
chdir $dir or die "chdir($dir): $!";

{
    open my $jfh, '>', "module.js";
    print {$jfh} "export let foo = 'BAR';";
}

my $got;

$js->set_globals(
    __ret => sub { $got = shift },
)->eval(<<END);
import("./module.js").then(exp => __ret(exp.foo));
END

is($got, undef, 'pre-await(): no returned value');

$js->await();

is($got, 'BAR', 'await() waited until the jobs are done');

chdir $cwd or warn "chdir($cwd): $!";

done_testing;
