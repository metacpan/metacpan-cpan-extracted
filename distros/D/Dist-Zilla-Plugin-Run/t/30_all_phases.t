use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;
use Path::Tiny;

use lib 't/lib';
use TestHelper;

# protect from external environment
local $ENV{TRIAL};
local $ENV{RELEASE_STATUS};

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],

                    # NOTE: We prepend "x:" to %x to work around Mac Perl's
                    # "versioner" voodoo which rewrites @ARGV elements of
                    # "/usr/bin/perl" to "/usr/bin/perl5.18" (rt-101483).

                    [ 'Run::BeforeBuild' => { run => [ '"%x" %o%pscript%prun.pl %o before_build %s %n %v .%d.%a. x:%x' ] } ],
                    [ 'Run::AfterBuild' => { run => [ '"%x" %o%pscript%prun.pl %o after_build %n %v %d %s %s %v .%a. x:%x' ] } ],
                    [ 'Run::BeforeArchive' => { run => [ '"%x" %o%pscript%prun.pl %o before_archive %n %v %d .%a. x:%x' ] } ],
                    [ 'Run::BeforeRelease' => { run => [ '"%x" %o%pscript%prun.pl %o before_release %n -d %d %s -v %v .%a. x:%x' ] } ],
                    [ 'Run::Release' => { run => [ '"%x" %o%pscript%prun.pl %o release %s %n %v %d/a %d/b %a x:%x' ] } ],
                    [ 'Run::AfterRelease' => { run => [ '"%x" %o%pscript%prun.pl %o after_release %d %v %s %s %n %a x:%x' ] } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source script run.pl)) => <<'SCRIPT',
use strict;
use warnings;

use Path::Tiny;

path(shift)->child('phases.txt')->append_raw(join(' ', @ARGV) . "\n");
SCRIPT
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    my $source_dir = path($tzil->tempdir)->child('source');
    my $build_dir = path($tzil->tempdir)->child('build');

    my %f = (
        a => 'DZT-Sample-0.001.tar.gz',
        n => 'DZT-Sample',
        o => $source_dir,
        d => $build_dir,
        v => '0.001',
        x => do { my $path = Dist::Zilla::Plugin::Run::Role::Runner->current_perl_path; $path =~ s{\\}{/}g; $path },
    );

    # test constant conversions as well as positional %s for backward compatibility
    my $expected = <<OUTPUT;
before_build $f{v} $f{n} $f{v} ... x:$f{x}
after_build $f{n} $f{v} $f{d} $f{d} $f{v} $f{v} .. x:$f{x}
before_archive $f{n} $f{v} $f{d} .. x:$f{x}
before_release $f{n} -d $f{d} $f{a} -v $f{v} .$f{a}. x:$f{x}
release $f{a} $f{n} $f{v} $f{d}/a $f{d}/b $f{a} x:$f{x}
after_release $f{d} $f{v} $f{a} $f{v} $f{n} $f{a} x:$f{x}
OUTPUT

    is_path(
        path($tzil->tempdir)->child(qw(source phases.txt))->slurp_raw,
        $expected,
        'got expected output for all five phases',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
