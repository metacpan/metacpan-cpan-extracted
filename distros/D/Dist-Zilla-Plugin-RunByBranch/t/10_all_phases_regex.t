use strict;
use warnings;
use Test::More tests => 8;
use Test::Git;

use lib 't/lib';

use Path::Class;
use Dist::Zilla::Tester;

has_git();

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/all_phases_regex' },
    );
    my $dir = $tzil->tempdir;

    test_repository(
        temp => [ DIR => $dir ],
        init => [qw| ../ |],
    )->run(qw/ checkout -b develop /);

    $tzil->release;
    my @txt = split /\n/, $tzil->slurp_file(file(qw(source script phases.txt)));

    my %f = (
        a => 'TestDzilPhasesBranches-1.01.tar.gz',
        n => 'TestDzilPhasesBranches',
        d => $dir->subdir('build'),
        v => '1.01',
        x => Dist::Zilla::Plugin::Run::Role::Runner->current_perl_path,
    );

    # test constant conversions as well as positional %s for backward compatibility
    my @exp = split /\n/, <<OUTPUT;
before_build $f{v} $f{n} $f{v} ... $f{x}
after_build $f{n} $f{v} $f{d} $f{d} $f{v} $f{v} .. $f{x}
before_release $f{n} -d $f{d} $f{a} -v $f{v} .$f{a}. $f{x}
release $f{a} $f{n} $f{v} $f{d}/a $f{d}/b $f{a} $f{x}
after_release $f{d} $f{v} $f{a} $f{v} $f{n} $f{a} $f{x}
OUTPUT

    # provide better test titles
    my @phases = map { /^(\w+) / && $1 } @exp;

    foreach my $i ( 0 .. $#exp ) {
      is($txt[$i], $exp[$i], "expected output from $phases[$i] phase");
    }
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/all_phases_regex' },
    );
    my $dir = $tzil->tempdir;

    test_repository(
        temp => [ DIR => $dir ],
        init => [qw| ../ |],
    )->run(qw| checkout -b testing/1.4 |);

    $tzil->release;
    my @txt = split /\n/, $tzil->slurp_file(file(qw(source script phases.txt)));

    my %f = (
        a => 'TestDzilPhasesBranches-1.01.tar.gz',
        n => 'TestDzilPhasesBranches',
        d => $dir->subdir('build'),
        v => '1.01',
        x => Dist::Zilla::Plugin::Run::Role::Runner->current_perl_path,
    );

    # test constant conversions as well as positional %s for backward compatibility
    my @exp = split /\n/, <<OUTPUT;
before_build $f{v} $f{n} $f{v} ... $f{x}
after_build $f{n} $f{v} $f{d} $f{d} $f{v} $f{v} .. $f{x}
OUTPUT

    # provide better test titles
    my @phases = map { /^(\w+) / && $1 } @exp;

    foreach my $i ( 0 .. $#exp ) {
      is($txt[$i], $exp[$i], "expected output from $phases[$i] phase");
    }
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/all_phases_regex' },
    );
    my $dir = $tzil->tempdir;

    test_repository(
        temp => [ DIR => $dir ],
        init => [qw| ../ |],
    )->run(qw/ checkout -b master /);

    $tzil->release;

    my $file = file(qw(source script phases.txt));
    ok( ( ! -e $file ), 'no commands matched regex, no commands ran' );
}
