#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Getopt::Long::Subcommand;

subtest "basics" => sub {
    local @ARGV;
    my @output;

    my @spec = (
        summary => 'Program summary',
        options => {
            'help|h|?' => {
                summary => 'Display help',
                handler => sub { push @output, 'General help message' },
            },
            'version|v' => {
                summary => 'Display version',
                handler => sub { push @output, 'Version 1.0' },
            },
        },
        subcommands => {
            sc1 => {
                summary => 'Subcommand1 summary',
                options => {
                    'opt1=s' => {
                        handler => sub { push @output, "set sc1.opt1=$_[1]" },
                    },
                    'opt2=s' => {
                        handler => sub { push @output, "set sc1.opt2=$_[1]" },
                    },
                },
            },
            sc2 => {
                summary => 'Subcommand2 summary',
                options => {
                    'help|h|?' => {
                        summary => 'Display subcommand2 help',
                        handler => sub { push @output, 'Sc2 help message' },
                    },
                    'opt1=i' => {
                        handler => sub { push @output, "set sc2.opt1=$_[1]" },
                    },
                },
                subcommands => {
                    sc21 => {
                        subcommands => {
                            sc211 => {
                                subcommands => {
                                    sc2111 => {},
                                },
                            },
                        },
                    },
                },
            },
            # to test cmdspec key 'configure'
            sc3 => {
                summary => 'Subcommand3 summary',
                configure => ['ignore_case'],
                options => {
                    'Opt1|A=s' => {
                        handler => sub { push @output, "set sc3.Opt1=$_[1]" },
                    },
                    'Opt2|B=s' => {
                        handler => sub { push @output, "set sc3.Opt2=$_[1]" },
                    },
                },
            },
        },
    );

    subtest "unknown options" => sub {
        subtest "unknown option -> not success" => sub {
            @ARGV = (qw/--foo/);
            my $res = GetOptions(@spec);
            is_deeply($res, {success => 0, subcommand => []});
        };

        subtest "unknown subcommand -> not success" => sub {
            @ARGV = (qw/sc99/);
            my $res = GetOptions(@spec);
            is_deeply($res, {success => 0, subcommand => []});
        };
    };

    subtest "general options" => sub {
        subtest "--help" => sub {
            @output = ();
            @ARGV = (qw/--help/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['General help message']);
            is_deeply($res, {success => 1, subcommand => []});
        };
        subtest "sc1 --help" => sub {
            @output = ();
            @ARGV = (qw/sc1 --help/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['General help message']);
            is_deeply($res, {success => 1, subcommand => ['sc1']});
        };
        subtest "--help sc1" => sub {
            @output = ();
            @ARGV = (qw/--help sc1/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['General help message']);
            is_deeply($res, {success => 1, subcommand => ['sc1']});
        };
        subtest "--help sc2" => sub {
            @output = ();
            @ARGV = (qw/--help sc2/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['General help message']);
            is_deeply($res, {success => 1, subcommand => ['sc2']});
        };
        subtest "sc2 --help" => sub {
            @output = ();
            @ARGV = (qw/--help sc2/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['General help message']);
            is_deeply($res, {success => 1, subcommand => ['sc2']});
        };
    };

    subtest "subcommand options" => sub {
        subtest "subcommand option must be with subcommand name" => sub {
            @ARGV = (qw/--opt1 foo/);
            my $res = GetOptions(@spec);
            is_deeply($res, {success => 0, subcommand => []});
        };
        subtest "--opt1 sc1 sc2" => sub {
            @output = ();
            @ARGV = (qw/--opt1 sc1 sc2/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, []);
            is_deeply($res, {success => 0, subcommand => []});
        };
        subtest "sc1 --opt1 sc2" => sub {
            @output = ();
            @ARGV = (qw/sc1 --opt1 sc2/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['set sc1.opt1=sc2']);
            is_deeply($res, {success => 1, subcommand => ['sc1']});
        };
    };

    subtest "nested subcommand" => sub {
        subtest "sc2 sc21" => sub {
            @ARGV = (qw/sc2 sc21/);
            my $res = GetOptions(@spec);
            is_deeply($res, {success => 1, subcommand => ['sc2', 'sc21']});
        };
        subtest "unknown sub-subcommand" => sub {
            @ARGV = (qw/sc2 foo/);
            my $res = GetOptions(@spec);
            is_deeply($res, {success => 0, subcommand => ['sc2']});
        };

        subtest "sc2 sc21 sc211" => sub {
            @ARGV = (qw/sc2 sc21 sc211/);
            my $res = GetOptions(@spec);
            is_deeply(
                $res, {success => 1, subcommand => ['sc2', 'sc21', 'sc211']});
        };
        subtest "unknown sub-sub-subcommand" => sub {
            @ARGV = (qw/sc2 sc21 foo/);
            my $res = GetOptions(@spec);
            is_deeply($res, {success => 0, subcommand => ['sc2', 'sc21']});
        };
        subtest "sc2 sc21 sc211 sc2111" => sub {
            @ARGV = (qw/sc2 sc21 sc211 sc2111/);
            my $res = GetOptions(@spec);
            is_deeply(
                $res, {success => 1,
                       subcommand => [qw/sc2 sc21 sc211 sc2111/]});
        };
        subtest "unknown sub-sub-sub-subcommand" => sub {
            @ARGV = (qw/sc2 sc21 sc211 foo/);
            my $res = GetOptions(@spec);
            is_deeply(
                $res, {success => 0, subcommand => ['sc2', 'sc21', 'sc211']});
        };
    };

    subtest "cmdspec 'configure'" => sub {
        subtest "sc3 --opt1 X" => sub {
            @output = ();
            @ARGV = (qw/sc3 --opt1 X/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, ['set sc3.Opt1=X']);
            is_deeply($res, {success => 1, subcommand => ['sc3']});
        };
        subtest "sc1 --Opt1 X" => sub {
            @output = ();
            @ARGV = (qw/sc1 --Opt1 X/);
            my $res = GetOptions(@spec);
            is_deeply(\@output, []);
            is_deeply($res, {success => 0, subcommand => ['sc1']});
        };
    };
};

DONE_TESTING:
done_testing;
