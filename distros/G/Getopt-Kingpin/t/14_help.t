use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;
use File::Basename;


subtest 'help' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $name    = $kingpin->arg('name', 'Name of user.')->required()->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <name>

Flags:
      --help     Show context-sensitive help.
  -v, --verbose  Verbose mode.

Args:
  <name>  Name of user.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse
    };
    is $exit, 0;
    is $stdout, $expected;
};


subtest 'help short' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $name    = $kingpin->arg('name', 'Name of user.')->required()->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <name>

Flags:
  -h, --help     Show context-sensitive help.
  -v, --verbose  Verbose mode.

Args:
  <name>  Name of user.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'help max_length_of_flag' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $ip      = $kingpin->flag('ip', 'IP address.')->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  -h, --help     Show context-sensitive help.
  -v, --verbose  Verbose mode.
      --ip=IP    IP address.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'help max_length_of_flag 2' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $ip      = $kingpin->flag('ipaddress', 'IP address.')->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  -h, --help                 Show context-sensitive help.
  -v, --verbose              Verbose mode.
      --ipaddress=IPADDRESS  IP address.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'help max_length_of_arg' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $ip      = $kingpin->flag('ip', 'IP address.')->bool();
    my $name    = $kingpin->arg('name', 'Name of user.')->required()->string();
    my $name    = $kingpin->arg('age', 'Age of user.')->required()->int();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <name> <age>

Flags:
  -h, --help     Show context-sensitive help.
  -v, --verbose  Verbose mode.
      --ip       IP address.

Args:
  <name>  Name of user.
  <age>   Age of user.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'help max_length_of_arg 2' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $ip      = $kingpin->flag('ip', 'IP address.')->string();
    my $name    = $kingpin->arg('age', 'Age of user.')->required()->int();
    my $name    = $kingpin->arg('name', 'Name of user.')->required()->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <age> <name>

Flags:
  -h, --help     Show context-sensitive help.
  -v, --verbose  Verbose mode.
      --ip=IP    IP address.

Args:
  <age>   Age of user.
  <name>  Name of user.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'help required' => sub {
    local @ARGV;
    push @ARGV, qw(-h);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    $kingpin->flags->get("help")->short('h');
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    my $ip      = $kingpin->flag('ip', 'IP address.')->string();
    my $name    = $kingpin->arg('age', 'Age of user.')->required()->int();
    my $name    = $kingpin->arg('name', 'Name of user.')->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>] <age> <name>

Flags:
  -h, --help     Show context-sensitive help.
  -v, --verbose  Verbose mode.
      --ip=IP    IP address.

Args:
  <age>     Age of user.
  [<name>]  Name of user.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'app info' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new("app_name", "app_description");
    $kingpin->terminate(sub {return @_});

    my $expected = sprintf <<'...';
usage: app_name [<flags>]

app_description

Flags:
  --help  Show context-sensitive help.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $exit, 0;
    is $stdout, $expected;
};

subtest 'place holder' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    $kingpin->flag("name", "Set name.")->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help       Show context-sensitive help.
  --name=NAME  Set name.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'default' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->default("default name")->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help                 Show context-sensitive help.
  --name="default name"  Set name.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'default2' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->default("")->string();
    my $id1 = $kingpin->flag('id1', 'Set id1.')->default(1)->int();
    my $id2 = $kingpin->flag('id2', 'Set id2.')->default(0)->int();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help     Show context-sensitive help.
  --name=""  Set name.
  --id1="1"  Set id1.
  --id2="0"  Set id2.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'default3' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->default(sub{ "default name" })->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help       Show context-sensitive help.
  --name=NAME  Set name.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'default4' => sub {
    { package Local::Overloaded; use overload '&{}' => sub { $_[0][0] } };
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->default(bless [sub{ "default name" }], 'Local::Overloaded')->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help       Show context-sensitive help.
  --name=NAME  Set name.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'default5' => sub {
    require Path::Tiny;
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('input', 'Set input.')->default(Path::Tiny::path('Build.PL'))->file();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help              Show context-sensitive help.
  --input="Build.PL"  Set input.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'place holder' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->placeholder("place_holder_name")->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help                    Show context-sensitive help.
  --name=place_holder_name  Set name.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'place holder' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->placeholder("place_holder_name")->string();
    my $id1 = $kingpin->flag('id1', 'Set id1.')->placeholder("1")->int();
    my $id2 = $kingpin->flag('id2', 'Set id2.')->placeholder("0")->int();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help                    Show context-sensitive help.
  --name=place_holder_name  Set name.
  --id1=1                   Set id1.
  --id2=0                   Set id2.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'place holder with default' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('name', 'Set name.')->placeholder("place_holder_name")->default("default name")->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help                    Show context-sensitive help.
  --name=place_holder_name  Set name.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

subtest 'flag with hidden flag' => sub {
    local @ARGV;
    push @ARGV, qw(--help);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});

    my $name = $kingpin->flag('name', 'Set name.')->hidden->string();

    my $expected = sprintf <<'...', basename($0);
usage: %s [<flags>]

Flags:
  --help  Show context-sensitive help.

...

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };
    is $stdout, $expected;
};

done_testing;

