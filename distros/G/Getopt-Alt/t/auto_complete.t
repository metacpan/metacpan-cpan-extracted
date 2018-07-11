#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
#use Test::Warnings;
use Getopt::Alt;
use Capture::Tiny qw/capture/;

my $last_exit;
$Getopt::Alt::EXIT = 0;

sub_command();
arguments();
general();

done_testing();

sub sub_command {
    diag 'sub_command';
    my $opt = eval {
        Getopt::Alt->new(
            {
                sub_command => {
                    cmd => [
                        {},
                        [ 'processed|p=s', ],
                    ],
                    '2nd' => [
                        {},
                        [ 'thing|t', ],
                    ],
                },
                default => {
                    other => 'global default',
                },
            },
            [
                'out|o=s',
                'other|t=s',
            ]
        )
    };
    my $err = $@;
    ok !$err, 'No errors' or diag explain $err;
    local @ARGV = qw/cm/;
    my ($stdout, $stderr) = capture { $opt->complete([]) };
    is $stdout, 'cmd', 'Suggests the correct command';

    @ARGV = qw//;
    ($stdout, $stderr) = capture { $opt->complete([]) };
    is $stdout, '2nd cmd', 'Suggests the correct command';
}

sub arguments {
    diag 'arguments';
    my $opt = eval {
        Getopt::Alt->new(
            {
                default => {
                    other => 'global default',
                },
            },
            [
                'out|o=s',
                'other|t=s',
            ]
        )
    };
    local @ARGV = qw/-/;
    my ($stdout, $stderr) = capture { $opt->complete([]) };
    is $stdout, '--help --man --other --out --version -o -t', 'Suggests the correct arguments';

    @ARGV = qw/--/;
    ($stdout, $stderr) = capture { $opt->complete([]) };
    is $stdout, '--help --man --other --out --version', 'Suggests the correct arguments';
}

sub general {
    diag 'general';
    my $opt = eval {
        Getopt::Alt->new(
            {
                default => {
                    other => 'global default',
                },
            },
            [
                'out|o=s',
                'other|t=s',
            ]
        )
    };
    my ($stdout, $stderr) = capture { get_options([]) };
}
