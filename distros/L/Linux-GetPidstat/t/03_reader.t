use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;
use Test::Mock::Guard;
use Capture::Tiny qw/capture/;

use Linux::GetPidstat::Reader;

my %opt = (
    pid_dir       => 't/assets/pid',
    include_child => '0',
);

is exception {
    my $instance = Linux::GetPidstat::Reader->new(%opt);
}, undef, "create ok";

my $guard = Test::Mock::Guard->new(
    'Linux::GetPidstat::Reader' => {
        _command_search_child_pids => sub {
            my ($pid) = shift;
            return "cat t/assets/source/pstree_$pid.txt";
        },
    },
);

subtest 'include_child 0' => sub {
    my $instance = Linux::GetPidstat::Reader->new(%opt);
    my $mapping  = $instance->get_program_pid_mapping;
    is scalar @$mapping, 2 or diag explain $mapping;

    my $got;
    for my $info (@$mapping) {
        my $program_name = $info->{program_name};
        my $pid          = $info->{pid};
        push @{$got->{$program_name}}, $pid;
    }
    is_deeply [sort { $a <=> $b } @{$got->{target_script}}] , [1] or diag explain $got;
    is_deeply [sort { $a <=> $b } @{$got->{target_script2}}], [2] or diag explain $got;
};

$opt{include_child} = 1;
subtest 'include_child 1' => sub {
    my $instance = Linux::GetPidstat::Reader->new(%opt);
    my $mapping  = $instance->get_program_pid_mapping;
    is scalar @$mapping, 7 or diag explain $mapping;

    my $got;
    for my $info (@$mapping) {
        my $program_name = $info->{program_name};
        my $pid          = $info->{pid};
        push @{$got->{$program_name}}, $pid;
    }

    is_deeply [sort { $a <=> $b } @{$got->{target_script}}] , [1] or diag explain $got;
    is_deeply [sort { $a <=> $b } @{$got->{target_script2}}],
        [2, 18352, 18353, 18360, 18366, 28264] or diag explain $got;
};

$opt{max_child_limit} = 3;
subtest 'limit a number of child' => sub {
    my $instance = Linux::GetPidstat::Reader->new(%opt);
    my ($stdout, $stderr, $mapping) = capture {
        $instance->get_program_pid_mapping;
    };
    is scalar @$mapping, 5 or diag explain $mapping;
    like $stderr, qr/Stop searching child pids. max_child_limit is too little. pid=2/
        or diag $stderr;

    my $got;
    for my $info (@$mapping) {
        my $program_name = $info->{program_name};
        my $pid          = $info->{pid};
        push @{$got->{$program_name}}, $pid;
    }

    is_deeply [sort { $a <=> $b } @{$got->{target_script}}] , [1] or diag explain $got;
    is_deeply [sort { $a <=> $b } @{$got->{target_script2}}],
        [2, 18352, 18353, 18360] or diag explain $got;
};

$opt{pid_dir} = 't/assets/invalid_pid';
subtest 'all pid are invalid' => sub {
    my $instance = Linux::GetPidstat::Reader->new(%opt);
    my ($stdout, $stderr, $mapping) = capture {
        $instance->get_program_pid_mapping;
    };
    is scalar @$mapping, 0 or diag explain $mapping;
    like $stderr, qr/invalid pid: dummy/ or diag $stderr;
    like $stderr, qr/invalid pid: one/ or diag $stderr;
};

$opt{pid_dir} = 't/assets/valid_invalid_pid';
subtest 'some pid are valid or invalid' => sub {
    my $instance = Linux::GetPidstat::Reader->new(%opt);
    my ($stdout, $stderr, $mapping) = capture {
        $instance->get_program_pid_mapping;
    };
    is scalar @$mapping, 1 or diag explain $mapping;
    like $stderr, qr/invalid pid: dummy/ or diag $stderr;
};

subtest 'a search child command is failed' => sub {
    my $guard_local = Test::Mock::Guard->new(
        'Linux::GetPidstat::Reader' => {
            _command_search_child_pids => sub {
                my ($pid) = shift;
                return "cat t/assets/not_found_source/pstree_$pid.txt";
            },
        },
    );

    my $instance = Linux::GetPidstat::Reader->new(%opt);
    my ($stdout, $stderr, $mapping) = capture {
        $instance->get_program_pid_mapping;
    };
    is scalar @$mapping, 1 or diag explain $mapping;
    like $stderr, qr{Failed a command: cat t/assets/not_found_source/pstree}
        or diag $stderr;
};

done_testing;
