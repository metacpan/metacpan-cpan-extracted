use strict; use warnings;
package Devel::PerlLog;
our $VERSION = '0.04';

use Fcntl qw(:flock SEEK_END);
use Time::HiRes;

my $log_path;
my $log_handle;
my %data;
my @plugins;
my %group = (
    all => [qw(argv cwd pid)],
);

sub write_log {
    my ($text) = @_;
    if ($log_path ne 'STDOUT') {
        flock $log_handle, LOCK_EX
            or die "Cannot lock '$log_path':\n$!\n";
        seek $log_handle, 0, SEEK_END
            or die "Cannot seek '$log_path':\n$!\n";
    }
    print $log_handle $text;
    if ($log_path ne 'STDOUT') {
        flock $log_handle, LOCK_UN
            or die "Cannot unlock '$log_path':\n$!\n";
    }
}

sub import {
    my ($class, @args) = @_;
    for my $arg (@args) {
        if ($arg =~ m![\\\/\.]!) {
            die "Devel::PerlLog log path already set to '$log_path'"
                if $log_path;
            $log_path = $arg;
            open $log_handle, '>>', $log_path
                or die "Can't open '$log_path' for append:\n$!";
        }
        elsif ($arg =~ m!^(all)$!) {
            die "No support for Devel::PerlLog '$arg'"
                unless $group{$arg};
            $class->add(@{$group{$arg}});
        }
        else {
            $class->add($arg);
        }
    }
    $log_handle ||= \*STDOUT;
    $log_path ||= 'STDOUT';
    for my $plugin (@plugins) {
        my $method = "do_$plugin";
        die "No support for Devel::PerlLog '$plugin'"
            unless $class->can($method);
        $class->$method;
    }
    my $time = localtime;
    write_log "# $time ($$) Perl BEGIN:\n";
}

END {
    require YAML::XS;
    $YAML::XS::Head = 0;
    my $time = localtime;
    write_log "# $time ($$) Perl END:\n";
    my @keys = keys %data;
    return unless @keys;
    my $dump = YAML::XS::Dump(\%data);
    $dump =~ s/\A---\s*//;
    write_log $dump;
}

sub add {
    my ($class, @names) = @_;
    for my $name (@names) {
        @plugins = grep { $_ ne $name } @plugins;
        push @plugins, $name;
    }
}

#------------------------------------------------------------------------------

sub do_argv {
    $data{argv} = join ', ', @ARGV;
}

sub do_cwd {
    require Cwd;
    $data{cwd} = Cwd::cwd();
}

sub do_pid {
    $data{pid} = $$;
}

1;
