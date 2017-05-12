#!/usr/bin/env perl
# Mike Covington
# created: 2014-03-10
#
# Description:
#
use strict;
use warnings;
use Config;
use Test::More tests => 8;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Cwd;
use Capture::Tiny 'capture';
use locale;
use POSIX qw(locale_h);

# TODO: Account for systems with REPRO_DIR environmental variable set
# TODO: Need to update tests to account for new features
# TODO: Add tests for 'perlr'

BEGIN {
    require_ok('Log::Reproducible')
        or BAIL_OUT "Can't load Log::Reproducible";
}
my $cwd = getcwd;

# From: http://search.cpan.org/~stevan/perl/pod/perlvar.pod#$^X
my $secure_perl_path = $Config{perlpath};
if ( $^O ne 'VMS' ) {
    $secure_perl_path .= $Config{_exe}
        unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

# Avoid failing time tests due to non-English locales
setlocale(LC_ALL, "C");

my ( $got, $stderr, $exit );
my $expected = <<EOF;
a: 1
b: 'two words'
c: string
extra: some other stuff
EOF
my $script      = "test-reproducible.pl";
my $archive_dir = "$Bin/repro-archive";
my $cmd         = "$secure_perl_path $Bin/$script --reprodir $archive_dir";

( $got, $stderr, $exit ) = capture {
    system("$cmd -a 1 -b 'two words' -c string some other stuff");
};
die $stderr if $exit != 0;
is_deeply( $got, $expected, 'Run and archive Perl script' );

my $archive = get_recent_archive($archive_dir);
( $got, $stderr, $exit ) = capture {
    system("$cmd --reproduce $archive_dir/$archive;");
};
die $stderr if $exit != 0;
is_deeply( $got, $expected, 'Run an archived Perl script' );

subtest 'Time tests' => sub {
    plan tests => 4;

    my $now = Log::Reproducible::_now();

    like(
        $$now{'timestamp'},
        qr/2\d{3}[01][0-9][0-3][0-9]\.[0-2][0-9][0-6][0-9][0-6][0-9]/,
        "Test timestamp"
    );
    like(
        $$now{'when'},
        qr/at [0-2][0-9]:[0-6][0-9]:[0-6][0-9] on \w{3} \w{3} [0-3][0-9], 2\d{3}/,
        "Test 'at time on date'"
    );
    like( $$now{'seconds'}, qr/\d{10}/, "Test seconds" );

    my $start_seconds  = 1000000;
    my $finish_seconds = 3356330;
    my $elapsed
        = Log::Reproducible::_elapsed( $start_seconds, $finish_seconds );
    is( $elapsed, '654:32:10', 'Test elapsed time' );
};

subtest '_set_dir tests' => sub {
    plan tests => 4;

    my $original_REPRO_DIR = $ENV{REPRO_DIR};
    undef $ENV{REPRO_DIR};

    my $test_params = {};
    $test_params = {
        name     => "default _set_dir()",
        dir      => undef,
        args     => undef,
        expected => "$cwd/repro-archive",
    };
    test_set_dir($test_params);

    my $custom_dir = "custom-dir";
    $test_params = {
        name     => "_set_dir('$custom_dir')",
        dir      => $custom_dir,
        args     => undef,
        expected => $custom_dir,
    };
    test_set_dir($test_params);

    my $cli_dir = "cli-dir";
    $test_params = {
        name     => "_set_dir() using '--reprodir $cli_dir' on CLI",
        dir      => undef,
        args     => [ '--reprodir', $cli_dir ],
        expected => $cli_dir,
    };
    test_set_dir($test_params);

    my $env_dir = "env-dir";
    $ENV{REPRO_DIR} = $env_dir;
    $test_params = {
        name =>
            "_set_dir() using REPRO_DIR environmental variable ('$env_dir')",
        dir      => undef,
        args     => undef,
        expected => $env_dir,
    };
    test_set_dir($test_params);
    $ENV{REPRO_DIR} = $original_REPRO_DIR;
};

subtest '_get_repro_arg tests' => sub {
    plan tests => 3;

    my $argv_current = [
        '--repronote', 'test note',
        '--reprodir',  '/path/to/archive',
        '-a',          '1',
        '-b',          'a test',
        'some',        'arguments'
    ];

    my $arg;
    $arg = Log::Reproducible::_get_repro_arg( "repronote", $argv_current );
    is( $arg, 'test note', "Get note from CLI ('--repronote')" );
    $arg = Log::Reproducible::_get_repro_arg( "reprodir", $argv_current );
    is( $arg, '/path/to/archive', "Get directory from CLI ('--reprodir')" );
    is_deeply(
        $argv_current,
        [ '-a', '1', '-b', 'a test', 'some', 'arguments' ],
        "Leftover options/arguments"
    );
};

subtest '_parse_command tests' => sub {
    plan tests => 4;

    my $current      = {};
    my $argv_current = [
        '--repronote', 'test note', '-a',   '1',
        '-b',          'a test',    'some', 'arguments'
    ];
    my $full_prog_name = "/path/to/script.pl";
    my ( $prog, $prog_dir )
        = Log::Reproducible::_parse_command( $current, $full_prog_name,
        'repronote', $argv_current );

    is( $prog,             "script.pl", "Script name" );
    is( $prog_dir,         "/path/to/", "Script directory" );
    is( $$current{'NOTE'}, "test note", "Repro note" );
    is( $$current{'COMMAND'}, "$prog -a 1 -b 'a test' some arguments",
        "Full command" );
};

subtest '_divider_message tests' => sub {
    plan tests => 5;

    my $message;
    $message = Log::Reproducible::_divider_message("X" x 18);
    is($message, join (" ", "#" x 30, "X" x 18, "#" x 30) . "\n", 'Even length message');

    $message = Log::Reproducible::_divider_message("X" x 19);
    is($message, join (" ", "#" x 30, "X" x 19, "#" x 29) . "\n", 'Odd length message');

    $message = Log::Reproducible::_divider_message();
    is($message, "#" x 80 . "\n", 'Divider line only, no message');

    $message = Log::Reproducible::_divider_message("X" x 77);
    is($message, "# " . "X" x 77 . " #\n", 'Message almost as long as width (77)');

    $message = Log::Reproducible::_divider_message("X" x 100);
    is($message, "# " . "X" x 100 . " #\n", 'Message longer than width (80)');
};

exit;

sub get_recent_archive {
    my $archive_dir = shift;
    opendir (my $dh, $archive_dir) or die "Cannot opendir $archive_dir: $!";
    my @archives = grep { /^rlog-$script/ && -f "$archive_dir/$_" } readdir($dh);
    closedir $dh;
    my @sorted_archives = sort @archives;
    return pop @sorted_archives;
}

sub test_set_dir {
    my $test_params = shift;
    Log::Reproducible::_set_dir( \$$test_params{'dir'}, 'reprodir',
        $$test_params{'args'} );
    is( $$test_params{'dir'}, $$test_params{'expected'},
        $$test_params{'name'} );
}
