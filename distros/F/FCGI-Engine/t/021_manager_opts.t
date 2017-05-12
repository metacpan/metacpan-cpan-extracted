#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Cwd;
use File::Spec::Functions;

use Test::More;
use Test::Exception;
use Test::Moose;

BEGIN {
    my $got_YAML = 1;
    eval "use YAML::XS;";
    $got_YAML = 0 if $@;
    plan skip_all => "Some kind of YAML parser is required for this test" unless $got_YAML;    
    plan tests => 15;
    use_ok('FCGI::Engine::Manager');
}

my $CWD                = Cwd::cwd;
$ENV{MX_DAEMON_STDOUT} = catfile($CWD, 'Out.txt');
$ENV{MX_DAEMON_STDERR} = catfile($CWD, 'Err.txt');

my $m = FCGI::Engine::Manager->new(
    conf => catfile($FindBin::Bin, 'confs', 'test_conf.yml')
);
isa_ok($m, 'FCGI::Engine::Manager');
does_ok($m, 'MooseX::Getopt');

lives_ok {
    $m->start('foo.server');
} '... started foo server okay';

is( $m->status, "foo.server is running\nbar.server is not running\n", '... got the right status' );

lives_ok {
    $m->start('bar.server');
} '... started bar server okay';

is( $m->status, "foo.server is running\nbar.server is running\n", '... got the right status' );

#diag join "\n" => map { chomp; s/\s+$//; $_ } grep { /fcgi|overseer|minion/ } `ps auxwww`;

lives_ok {
    $m->stop();
} '... stopped all okay';

is( $m->status, "foo.server is not running\nbar.server is not running\n", '... got the right status' );

## now reverse that ...

lives_ok {
    $m->start();
} '... started all okay';

is( $m->status, "foo.server is running\nbar.server is running\n", '... got the right status' );

lives_ok {
    $m->stop('foo.server');
} '... stopped foo server okay';

is( $m->status, "foo.server is not running\nbar.server is running\n", '... got the right status' );

lives_ok {
    $m->stop('bar.server');
} '... stopped bar server okay';

is( $m->status, "foo.server is not running\nbar.server is not running\n", '... got the right status' );

#diag join "\n" => map { chomp; s/\s+$//; $_ } grep { /fcgi|overseer|minion/ } `ps auxwww`;

unlink $ENV{MX_DAEMON_STDOUT};
unlink $ENV{MX_DAEMON_STDERR};
