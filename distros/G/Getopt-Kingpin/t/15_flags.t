use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;
use File::Basename;


subtest 'flag error' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new();
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    throws_ok {
        my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->bool();
    } qr/flag verbose is already exists/;

};

subtest 'flags ordered help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $verbose3 = $kingpin->flag('verbose3', 'Verbose mode.')->bool();
    my $verbose1 = $kingpin->flag('verbose1', 'Verbose mode.')->bool();
    my $verbose2 = $kingpin->flag('verbose2', 'Verbose mode.')->bool();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    is $stdout, sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help      Show context-sensitive help.
  --verbose3  Verbose mode.
  --verbose1  Verbose mode.
  --verbose2  Verbose mode.

...
};

subtest 'get max length' => sub {
    my $kingpin = Getopt::Kingpin->new();

    is $kingpin->flags->_help_length->[0], 0;
    is $kingpin->flags->_help_length->[1], length "--help";
    is $kingpin->flags->help, <<HELP;
Flags:
  --help  Show context-sensitive help.
HELP

    $kingpin->flag('a')->bool();
    is $kingpin->flags->_help_length->[0], 0;
    is $kingpin->flags->_help_length->[1], length "--help";
    is $kingpin->flags->help, <<HELP;
Flags:
  --help  Show context-sensitive help.
  --a
HELP

    $kingpin->flag('bbbbbb')->bool();
    is $kingpin->flags->_help_length->[0], 0;
    is $kingpin->flags->_help_length->[1], length "--bbbbbb";
    is $kingpin->flags->help, <<HELP;
Flags:
  --help    Show context-sensitive help.
  --a
  --bbbbbb
HELP

    $kingpin->flag('cc', 'description of cc')->bool();
    is $kingpin->flags->_help_length->[0], 0;
    is $kingpin->flags->_help_length->[1], length "--bbbbbb";
    is $kingpin->flags->help, <<HELP;
Flags:
  --help    Show context-sensitive help.
  --a
  --bbbbbb
  --cc      description of cc
HELP

    $kingpin->flag('ddd')->string();
    is $kingpin->flags->_help_length->[0], 0;
    is $kingpin->flags->_help_length->[1], length "--ddd=DDD";
    is $kingpin->flags->help, <<HELP;
Flags:
  --help     Show context-sensitive help.
  --a
  --bbbbbb
  --cc       description of cc
  --ddd=DDD
HELP

    $kingpin->flag('eee', 'description of eee')->short('e')->string();
    is $kingpin->flags->_help_length->[0], length "-e";
    is $kingpin->flags->_help_length->[1], length "--eee=EEE";
    is $kingpin->flags->help, <<HELP;
Flags:
      --help     Show context-sensitive help.
      --a
      --bbbbbb
      --cc       description of cc
      --ddd=DDD
  -e, --eee=EEE  description of eee
HELP
};

done_testing;

