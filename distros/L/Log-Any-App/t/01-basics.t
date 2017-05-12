#!perl

# check defaults

# XXX use Test::Deep?

use lib './t'; require 'testlib.pl';
use strict;
use warnings;

use Log::Any::App -dir => 0, -file => 0, -screen => 0, -syslog => 0, -init => 0;
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Test::More;

test_init(
    name => 'default',
    num_dirs => 0, num_files => 1, num_screens => 1, num_syslogs => 0,
    level => 'warn',
    file_level => 'warn', screen_level => 'warn',
); #=7

{
    local $0 = "-e";
    test_init(
        name => '-e doesnt get file by default',
        num_dirs => 0, num_files => 0, num_screens => 1, num_syslogs => 0,
    ); #=4
}

my %vars;



# TESTING LEVEL

%vars = (
    loglevel  => ["fatal", "fatal"],
    log_level => ["error", "error"],
    LogLevel  => ["debug", "debug"],
    Log_Level => ["info", "info"],
    LOGLEVEL  => ["trace", "trace"],
    LOG_LEVEL => ["TRACE", "trace"],
    Verbose   => [1, "info"],
    QUIET     => [1, "error"],
    Debug     => [1, "debug"],
    TRACE     => [1, "trace"],
); #10
while (my ($k, $v) = each %vars) {
    no strict 'refs';
    test_init(
        pre   => sub { $k = "main::$k"; $$k = $v->[0]; },
        name  => "setting general level via variable: \$$k = $v->[0]",
        level => $v->[1],
    ); #1
} #=10x1

%vars = (
    screen_loglevel  => ["fatal", screen => "fatal"],
    file_log_level   => ["error", file   => "error"],
    Screen_LogLevel  => ["debug", screen => "debug"],
    File_Log_Level   => ["INFO",  file   => "info" ],
    SCREEN_LOGLEVEL  => ["trace", screen => "trace"],
    FILE_LOG_LEVEL   => ["trace", file   => "trace"],
    Screen_Verbose   => [1,       screen => "info" ],
    FILE_QUIET       => [1,       file   => "error"],
    Screen_Debug     => [1,       screen => "debug"],
    FILE_TRACE       => [1,       file   => "trace"],
); #10
while (my ($k, $v) = each %vars) {
    no strict 'refs';
    test_init(
        pre   => sub { $k = "main::$k"; $$k = $v->[0]; },
        name  => "setting output level via variable: \$$k = $v->[0]",
        level => "warn", "$v->[1]_level" => $v->[2],
    ); #2
} #=10x2

%vars = (
    LOG_LEVEL => ["trace", "trace"],
    VERBOSE   => [1,       "info" ],
); #2
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { $ENV{$k} = $v->[0] },
        name  => "setting general level env: $k = $v->[0]",
        level => $v->[1],
    ); #1
} #=2x1

%vars = (
    SCREEN_LOG_LEVEL => ["trace", screen => "trace"],
    FILE_DEBUG       => [1,       file   => "debug"],
); #2
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { $ENV{$k} = $v->[0] },
        name  => "setting output level env: $k = $v->[0]",
        level => "warn", "$v->[1]_level" => $v->[2],
    ); #2
} #=2x2

%vars = (
    '--loglevel'   => ["fatal", "fatal"],
    '--log-level'  => ["DEBUG", "debug"],
    '--log_level'  => ["info" , "info" ],
    '--quiet'      => [undef  , "error"],
); #4
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { push @ARGV, grep {defined} $k, $v->[0] },
        name  => "setting general level via cmdline opts: ".join(" ", @ARGV),
        level => $v->[1],
    ); #1
} #=4x1

%vars = (
    '--screen-loglevel'   => ["fatal", screen => "fatal"],
    '--file_log-level'    => ["debug", file   => "debug"],
    '--screen-log_level'  => ["INFO" , screen => "info" ],
    '--file_quiet'        => [undef  , file   => "error"],
); #4
while (my ($k, $v) = each %vars) {
    test_init(
        pre   => sub { push @ARGV, grep {defined} $k, $v->[0] },
        name  => "setting output level via cmdline opts: ".join(" ", @ARGV),
        level => "warn", "$v->[1]_level" => $v->[2],
    ); #2
} #=4x2

my @lfftests = (
    {ext => "DEBUG", level => "debug"},
    {ext => "FILE_VERBOSE", level => "warn", file_level => "info"},
    {ext => "log_level", content => "error", level => "error"},
    {ext => "SCREEN_log_level", content => "trace", level => "warn",
     screen_level => "trace"},
);
my $tempdir = tempdir(CLEANUP => 1);
chdir $tempdir or die "Can't chdir to $tempdir: $!";
for my $test (@lfftests) {
    my $flag_file = "$tempdir/prog.$test->{ext}";
    write_text($flag_file, defined($test->{content}) ? $test->{content} : "");
    my %args = (
        name  => "setting output level via level flag file: $flag_file",
        init_args => [-name => 'prog', -level_flag_paths => [$tempdir]],
    );
    $args{level} = $test->{level} if $test->{level};
    $args{$_} = $test->{$_} for grep {/_level$/} keys %$test;
    test_init(%args);
    unlink $flag_file or die "Can't unlink flag file $flag_file: $!";
}
#chdir "/" if Test::More->builder->is_passing;

# TESTING FILE

%vars = (
    1 => [-file => "/foo/bar"],
    2 => [-file => {path=>"/foo/bar"}],
);
while (my ($k, $v) = each %vars) {
    test_init(
        init_args => $v,
        name => "file path without ending slash assumed as path ($k)",
        file_params => {path => "/foo/bar"},
    ); #1
} #=2x1

%vars = (
    1 => [-file => "/foo/bar/", -name => 'app'],
    2 => [-file => {path=>"/foo/bar/"}, -name => 'app'],
);
while (my ($k, $v) = each %vars) {
    test_init(
        init_args => $v,
        name => "file path with ending slash assumed as directory ($k)",
        file_params => {path => "/foo/bar/app.log"},
    ); #1
} #=2x1

# D3

# TESTING SCREEN
{
    local $INC{"Net/Daemon.pm"} = 1;
    test_init(
        name => "screen default: off if daemon",
        num_screens => 0,
    );
}

# TESTING SYSLOG

{
    local $INC{"Net/Daemon.pm"} = 1;
    test_init(
        name => "syslog default: on if daemon (\$INC{'Net/Daemon.pm'})",
        num_syslogs => 1,
    );
}
{
    local $::IS_DAEMON = 1;
    test_init(
        name => "syslog default: on if declaring as daemon (\$main::IS_DAEMON)",
        num_syslogs => 1,
    );
}
test_init(
    name => "syslog default: on if declaring as daemon (-daemon)",
    init_args => [-daemon => 1],
    num_syslogs => 1,
);
{
    local $INC{"Net/Daemon.pm"} = 1;
    test_init(
        name => "syslog default: off if declaring as not daemon",
        init_args => [-daemon => 0],
        num_syslogs => 0,
    );
}

# XXX priority/overrides (setting via env vs cmdline vs vars vs init args)
# XXX invalid level dies
# XXX syslog & dir: setting level
# XXX file: default path
# XXX dir: default path
# XXX screen: default color
# XXX and many more :)

# XXX setting general level via app::options
# XXX setting output level via app::options

# XXX test LOG_SHOW_CATEGORY
# XXX test LOG_CATEGORY_ALIAS & LOG_CATEGORY_LEVEL & ${OUT}_LOG_CATEGORY_LEVEL
# XXX test LOG_SHOW_LOCATION

# XXX test LOG_ENV

done_testing();
