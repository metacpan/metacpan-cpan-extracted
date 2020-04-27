use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'default' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_NAME} = "name from env var";

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default("default name")->override_default_from_envar("KINGPIN_TEST_NAME")->string();

    $kingpin->parse;

    is $name, 'name from env var';

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default arg' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_NAME} = "name from env var";

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default("default name")->override_default_from_envar("KINGPIN_TEST_NAME")->string();

    $kingpin->parse;

    is $name, 'name from env var';

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default arg (no env var)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default("default name")->override_default_from_envar("KINGPIN_TEST_NAME")->string();

    $kingpin->parse;

    is $name, 'default name';
};

subtest 'default with error' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_ID} = "xxx";

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('id', 'set id')->default("default id")->override_default_from_envar("KINGPIN_TEST_ID")->int();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default with error (no env var)' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_ID} = "xxx";

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('id', 'set id')->default("default id")->int();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default with error (no env var, list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_ID} = "xxx";

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->flag('id', 'set id')->default(["default id"])->int_list();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default arg with error' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_ID} = "xxx";

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->arg('id', 'set id')->default("default id")->override_default_from_envar("KINGPIN_TEST_ID")->int();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default arg with error (no env var)' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_ID} = "xxx";

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->arg('id', 'set id')->default("default id")->int();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

    delete $ENV{KINGPIN_TEST_NAME};
};

subtest 'default arg with error (no env var)' => sub {
    local @ARGV;
    push @ARGV, qw();

    $ENV{KINGPIN_TEST_ID} = "xxx";

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $name = $kingpin->arg('id', 'set id')->default(["default id"])->int_list();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

    delete $ENV{KINGPIN_TEST_NAME};
};

done_testing;

