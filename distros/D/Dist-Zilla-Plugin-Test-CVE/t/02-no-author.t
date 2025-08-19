use v5.20;
use warnings;

use Test2::V0;
use Test::Warnings 0.009 qw( :no_end_test had_no_warnings );
use Test::DZil;

use Data::Dumper 2.154 qw( Dumper );
use Path::Tiny;
use File::pushd qw( pushd );

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                ['GatherDir'],                       #
                ['ExecDir'],                         #
                ['MetaConfig'],                      #
                [ 'Test::CVE', { author => 0 } ],    #
            ),
            path(qw(source lib Foo.pm)) => <<'MODULE',
package Foo;
use strict;
use warnings;
1;
MODULE
            path(qw(source lib Bar.pod)) => <<'POD',

POD
            path(qw(source bin myscript)) => <<'SCRIPT',
use strict;
use warnings;
print "hello there!\n";
SCRIPT
            path(qw(source t foo.t)) => <<'TEST',
use strict;
use warnings;
use Test::More tests => 1;
pass('hi!');
TEST
        },
    },
);
$tzil->chrome->logger->set_debug(1);
$tzil->build;
my $build_dir = path( $tzil->tempdir )->child('build');
my $file      = $build_dir->child(qw(xt author cve.t));
ok( -e $file, $file . ' created' );
my $content = $file->slurp_utf8;

unlike $content, qr/Test2::Require::AuthorTesting/, "not using Test2::Require::AuthorTesting";

note $content;

is(
    $tzil->distmeta,
    hash {
        field prereqs => {
            develop => {
                requires => {
                    'Test2::V0' => 0,
                    'Test::CVE' => '0.10',
                },
            },
        };
        field x_Dist_Zilla => hash {
            field plugins => bag {
                item {
                    class  => 'Dist::Zilla::Plugin::Test::CVE',
                    config => {
                        'Dist::Zilla::Plugin::Test::CVE' => {
                            filename   => 'xt/author/cve.t',
                            _test_args => {
                                author => 0,
                                core   => 1,
                                deps   => 1,
                                perl   => 0,
                            },
                        },
                    },
                    name    => 'Test::CVE',
                    version => Dist::Zilla::Plugin::Test::CVE->VERSION,
                };
                etc;
            };
            etc;
        };
        etc;
    },
    'prereqs are properly injected for the develop phase',
) or diag 'got distmeta: ', Dumper( $tzil->distmeta );

my $tests;
subtest 'run the generated test' => sub {
    local $ENV{AUTHOR_TESTING} = 1;
    my $wd = pushd $build_dir;

    my $script = << "SCRIPT";
    package _Local::main;
    do '$file';
SCRIPT

    eval $script;

    note 'ran tests successfully' if not $@;
    fail($@)                      if $@;
    my $ctx = context();
    $tests = $ctx->hub->count;
    $ctx->release;
};
is( $tests, 1, 'expected result' );
diag 'got log messages: ', Dumper( $tzil->log_messages )
  if not Test::Builder->new->is_passing;
had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
