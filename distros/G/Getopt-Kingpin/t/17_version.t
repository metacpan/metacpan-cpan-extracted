use strict;
use Test::More 0.98;
use Test::Trap;
use Getopt::Kingpin;
use File::Basename;


subtest 'version' => sub {
    local @ARGV;
    push @ARGV, qw(--version);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->version("v1.2.3");

    trap {
        $kingpin->parse;
    };

    is $trap->stderr, "v1.2.3\n";
    is $trap->exit, 0;
};

subtest 'version help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->version("v1.2.3");

    trap {
        $kingpin->parse;
    };

    is $trap->stdout, sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help     Show context-sensitive help.
  --version  Show application version.

...

    is $trap->exit, 0;
};

done_testing;

