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
                ['GatherDir'],             #
                ['ExecDir'],               #
                ['MetaConfig'],            #
                ['Test::MixedScripts'],    #
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
my $file      = $build_dir->child(qw(xt author mixed-unicode-scripts.t));
ok( -e $file, $file . ' created' );
my $content = $file->slurp_utf8;

my @files = ( path(qw(lib Foo.pm)), path(qw(lib Bar.pod)), path(qw(bin myscript)), path(qw(t foo.t)), );
like( $content, qr/'\Q$_\E'/m, "test checks $_" ) foreach @files;

note $content;

is(
    $tzil->distmeta,
    hash {
        field prereqs => {
            develop => {
                requires => {
                    'Test2::Tools::Basic' => '1.302200',
                    'Test::MixedScripts' => 'v0.3.0',
                },
            },
        };
        field x_Dist_Zilla => hash {
            field plugins => bag {
                item {
                    class  => 'Dist::Zilla::Plugin::Test::MixedScripts',
                    config => {
                        'Dist::Zilla::Plugin::Test::MixedScripts' => {
                            filename => 'xt/author/mixed-unicode-scripts.t',
                            finder   => [ ':ExecFiles', ':InstallModules', ':TestFiles' ],
                            scripts  => [ ],
                        },
                    },
                    name    => 'Test::MixedScripts',
                    version => Dist::Zilla::Plugin::Test::MixedScripts->VERSION,
                };
                etc;
            };
            etc;
        };
        etc;
    },
    'prereqs are properly injected for the develop phase',
) or diag 'got distmeta: ', Dumper( $tzil->distmeta );

my $files_tested;
subtest 'run the generated test' => sub {
    my $wd = pushd $build_dir;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@)                      if $@;
    my $ctx = context();
    $files_tested = $ctx->hub->count;
    $ctx->release;
};
is( $files_tested, 4, 'correct number of files were tested' );
diag 'got log messages: ', Dumper( $tzil->log_messages )
  if not Test::Builder->new->is_passing;
had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
