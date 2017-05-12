use strict;
use Test::More 0.98;
use Test::Exception;
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

done_testing;

