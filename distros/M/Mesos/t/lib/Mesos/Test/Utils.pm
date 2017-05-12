package Mesos::Test::Utils;
use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Mesos::Types qw(ExecutorInfo FrameworkInfo);
use Time::HiRes qw(alarm);
use Try::Tiny;
use parent 'Exporter';
our @EXPORT = qw(
    root
    test_executor
    test_framework
    test_master
    timeout
);

our $_ROOT;
sub root {
    $_ROOT //= do {
        my $current_dir = abs_path(dirname __FILE__);
        (my $root = $current_dir) =~ s#/t/.*?$##;
        $root;
    };
}

sub test_executor {
    my ($command) = @_;
    $command //= "/bin/echo perl test executor";
    return ExecutorInfo->new({
        executor_id => {value => 'default'},
        command     => {value => $command},
    });
}

sub test_framework {
    my ($name) = @_;
    $name //= 'Test Framework (Perl)';
    FrameworkInfo->new({
        user => $ENV{USER},
        name => $name,
    });
}

sub test_master {
    $ENV{MESOS_TEST_MASTER} // 'localhost:5050';
}

sub timeout (&;$) {
    my ($code, $time) = @_;
    my $timeout = "TIMEOUT\n";

    my $timedout;
    try {
        local $SIG{ALRM} = sub { die $timeout };
        alarm($time // 1);
        $code->();
        alarm(0);
    } catch {
        die $_ unless /^$timeout/;
        $timedout++;
    };
    alarm(0);

    return !!$timedout;
}

1;
