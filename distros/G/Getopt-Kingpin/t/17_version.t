use strict;
use Test::More 0.98;
use Capture::Tiny ':all';
use Getopt::Kingpin;
use File::Basename;


subtest 'version' => sub {
    local @ARGV;
    push @ARGV, qw(--version);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->version("v1.2.3");

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    is $stderr, "v1.2.3\n";
    is $exit, 0;
};

subtest 'version help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->version("v1.2.3");

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    is $stdout, sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help     Show context-sensitive help.
  --version  Show application version.

...

    is $exit, 0;
};

done_testing;

