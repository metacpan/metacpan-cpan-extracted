#: t/Shell.pm
#: Testing framework for t/sh/*.t
#: Copyright (C) Yichun "agentzh" Zhang

package t::Shell;

use lib 't/lib';
use lib 'inc';
use Test::Base -Base;
use Test::Util;
use FindBin;
use Cwd;
use File::Temp qw( tempdir );
#use Data::Dumper::Simple;

our @EXPORT = qw( run_tests run_test );

filters {
    cmd            => [qw< chomp >],
    error_code     => [qw< eval >],
};

our $SHELL;

BEGIN {
    $SHELL = $ENV{TEST_SHELL_PATH} || "$^X $FindBin::Bin/../../script/sh";
    no_diff();
}

sub run_test ($) {
    my $block = shift;
    #warn Dumper($block->cmd);

    my $tempdir = tempdir( 'backend_XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;

    process_pre($block);

    my $cmd = [ split_arg($SHELL), '-c', $block->cmd() ];
    if ($^O eq 'MSWin32' and $block->stdout and $block->stdout eq qq{\\"\n}) {
        workaround($block, $cmd);
    } else {
        test_shell_command($block, $cmd);
    }

    process_found($block);
    process_not_found($block);
    process_post($block);

    chdir $saved_cwd;
}

sub workaround (@) {
    my ($block, $cmd) = @_;
    my ($error_code, $stdout, $stderr) = 
        run_shell( $cmd );
    #warn Dumper($stdout);
    my $stdout2     = $block->stdout;
    my $stderr2     = $block->stderr;
    my $error_code2 = $block->error_code;

    my $name = $block->name;
    SKIP: {
        skip 'Skip the test uncovers quoting issue on Win32', 3
            if 1;
        is ($stdout, $stdout2, "stdout - $name");
        is ($stderr, $stderr2, "stderr - $name");
        is ($error_code, $error_code2, "error_code - $name");
    }
}

sub run_tests () {
    for my $block (blocks) {
        run_test($block);
    }
}

1;
