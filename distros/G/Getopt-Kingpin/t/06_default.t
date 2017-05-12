use strict;
use Test::More 0.98;
use Test::Exception;
use Getopt::Kingpin;


subtest 'default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default("default name")->string();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'default (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->flag('name', 'set name')->default(["default name", "default name 2"])->string_list();
    my $xxxx = $kingpin->flag('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};

subtest 'default arg' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default("default name")->string();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string();

    $kingpin->parse;

    is $name, 'default name';
    is $xxxx, '';
};

subtest 'default arg (list)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new;
    my $name = $kingpin->arg('name', 'set name')->default(["default name", "default name 2"])->string_list();
    my $xxxx = $kingpin->arg('xxxx', 'set xxxx')->string_list();

    $kingpin->parse;

    is_deeply $name->value, ['default name', 'default name 2'];
    is_deeply $xxxx->value, [];
};


done_testing;

