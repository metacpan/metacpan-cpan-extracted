use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;
use File::pushd 'pushd';

{
    package My::MakeMaker;
    use Moose;
    extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

    around _build_MakeFile_PL_template => sub {
        my $orig = shift; my $self = shift;
        return $self->$orig(@_) . "\n# in Makefile_PL_template\n"
    };
    around _build_WriteMakefile_args => sub {
        my $orig = shift; my $self = shift;
        return +{ %{ $self->$orig(@_) }, '_IGNORE' => 'in WriteMakefile_args' }
    };
    around _build_WriteMakefile_dump => sub {
        my $orig = shift; my $self = shift;
        return $self->$orig(@_) . "\n# in WriteMakefile_dump\n"
    };
    around _build_test_files => sub {
        my $orig = shift; my $self = shift;
        return [ @{ $self->$orig(@_) }, 'xt/*.t' ]
    };
    around _build_exe_files => sub {
        my $orig = shift; my $self = shift;
        return [ @{ $self->$orig(@_) }, 'bin/hello-world' ]
    };
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                '=My::MakeMaker',
                # note no [ExecDir] plugin - so original _build_exe_files
                # returns nothing
            ),
            path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
            path(qw(source t basic.t)) => 'warn "here is a test";',
            path(qw(source bin hello-world)) => "#!/usr/bin/perl\nprint \"hello!\\n\"",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

# this isn't that great of a test... would be nice to do more sophisticated
# testing of the content generated.

# qr/...$/m does not work before perl 5.010
my $empty = "$]" < '5.010' ? qr/.{0}/ : '';

my $content = $tzil->slurp_file('build/Makefile.PL');
like(
    $content,
    qr/^# in Makefile_PL_template$empty$/ms,
    '_build_MakeFile_PL_template hook called',
);
like(
    $content,
    qr/^\s+"_IGNORE"\s+=>\s+"in WriteMakefile_args",/m,
    '_build_WriteMakefile_args hook called',
);
like(
    $content,
    qr/^# in WriteMakefile_dump$empty$/ms,
    '_build_WriteMakefile_dump hook called',
);
like(
    $content,
    qr{^\s+"TESTS"\s+=>\s+\Q"t/*.t xt/*.t"\E}m,
    '_build_test_files hook called',
);
like(
    $content,
    qr{^\s+"EXE_FILES"\s+=>\s+\[\n^\s+"bin/hello-world"\n^\s+\],}m,
    '_build_exe_files hook called',
);

subtest 'run the generated Makefile.PL' => sub
{
    my $wd = pushd path($tzil->tempdir)->child('build');
    is(
        exception { $tzil->plugin_named('=My::MakeMaker')->build },
        undef,
        'Makefile.PL can be run successfully',
    );
};

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
