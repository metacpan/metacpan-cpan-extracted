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
    plan tests => 19;
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
    $m->start;
} '... started okay';

#diag join "\n" => map { chomp; s/\s+$//; $_ } grep { /fcgi|overseer|minion/ } `ps auxwww`;

is( $m->status, "foo.server is running\nbar.server is running\n", '... got the right status' );

lives_ok {
    $m->stop;
} '... stopped okay';

is( $m->status, "foo.server is not running\nbar.server is not running\n", '... got the right status' );

# ... now try loading just a single server ... (make sure everything is cleaned up right)

lives_ok {
    $m->start('foo.server');
} '... started okay';

is( $m->status('foo.server'), "foo.server is running\n", '... got the right status' );
is( $m->status('bar.server'), "bar.server is not running\n", '... got the right status' );

#diag join "\n" => map { chomp; s/\s+$//; $_ } grep { /fcgi|overseer|minion/ } `ps auxwww`;

lives_ok {
    $m->stop('foo.server');
} '... stopped okay';

is( $m->status('foo.server'), "foo.server is not running\n", '... got the right status' );
is( $m->status('bar.server'), "bar.server is not running\n", '... got the right status' );

# ... now try starting, restarting and then stopping again ...

lives_ok {
    $m->start('foo.server');
} '... started okay';

is( $m->status('foo.server'), "foo.server is running\n", '... got the right status' );

lives_ok {
    $m->restart('foo.server');
} '... restarted okay';

is( $m->status('foo.server'), "foo.server is running\n", '... got the right status' );

lives_ok {
    $m->stop('foo.server');
} '... stopped okay';

is( $m->status('foo.server'), "foo.server is not running\n", '... got the right status' );


unlink $ENV{MX_DAEMON_STDOUT};
unlink $ENV{MX_DAEMON_STDERR};

