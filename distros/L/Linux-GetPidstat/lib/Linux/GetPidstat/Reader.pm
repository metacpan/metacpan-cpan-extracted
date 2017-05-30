package Linux::GetPidstat::Reader;
use 5.008001;
use strict;
use warnings;

use Carp;
use Capture::Tiny qw/capture/;
use Path::Tiny qw/path/;

sub new {
    my ( $class, %opt ) = @_;
    bless \%opt, $class;
}

sub get_program_pid_mapping {
    my $self = shift;

    my $pid_dir = path($self->{pid_dir});

    my @program_pid_mapping;
    for my $pid_file ($pid_dir->children) {
        chomp(my $pid = $pid_file->slurp);
        unless (_is_valid_pid($pid)) {
            next;
        }

        my @pids;
        push @pids, $pid;

        if ($self->{include_child}) {
            my $child_pids = $self->search_child_pids($pid);
            push @pids, @$child_pids;
        }

        push @program_pid_mapping, {
            program_name => $pid_file->basename,
            pids         => \@pids,
        };
    }

    return \@program_pid_mapping;
}

sub search_child_pids {
    my ($self, $pid) = @_;
    my $command = _command_search_child_pids($pid);
    my ($stdout, $stderr, $exit) = capture { system $command };

    if (length $stderr or $exit != 0) {
        chomp ($stderr);
        carp "Failed a command: $command, stdout=$stdout, stderr=$stderr, exit=$exit";
    }
    unless (length $stdout) {
        return [];
    }

    my @child_pids;

    my @lines = split '\n', $stdout;
    for (@lines) {
        while (/[^}]\((\d+)\)/g) {
            my $child_pid = $1;
            next if $child_pid == $pid;

            # TODO: Remove the limit.
            ## FIXME: Replace calling pidstat with reading /proc manually
            my $max = $self->{max_child_limit};
            if ($max && $max <= scalar @child_pids) {
                carp "Stop searching child pids. max_child_limit is too little. pid=$pid";
                last;
            }
            push @child_pids, $child_pid;
        }
    }
    return \@child_pids;
}

# for mock in tests
sub _command_search_child_pids {
    my $pid = shift;
    return "pstree -pn $pid";
}

sub _is_valid_pid {
    my $pid = shift;
    unless ($pid =~ /^[0-9]+$/) {
        carp "invalid pid: $pid";
        return 0;
    }
    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Linux::GetPidstat::Reader - Read each pid info from a pid dir path

=head1 SYNOPSIS

    use Linux::GetPidstat::Reader;

    my $instance = Linux::GetPidstat::Reader->new(
        pid_dir       => './pid',
        include_child => 1,
    );
    my $pids = $instance->get_program_pid_mapping;

=cut
