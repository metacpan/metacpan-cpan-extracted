use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;

subtest 'repeatable flag error' => sub {
    local @ARGV;
    push @ARGV, qw(--xxx a --xxx b --xxx c);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $args = $kingpin->flag("xxx", "xxx yyy")->string();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: flag 'xxx' cannot be repeated, try --help/;
    is $exit, 1;
};

subtest 'repeatable flag (is_cumulative)' => sub {
    local @ARGV;
    push @ARGV, qw(--xxx a --xxx b --xxx c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->string_list();
    #$args->is_cumulative(1);

    my $cmd = $kingpin->parse;

    is_deeply $args->value, ['a', 'b', 'c'];
};

subtest 'repeatable flag (is_cumulative no-flags)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->string_list();
    #$args->is_cumulative(1);

    my $cmd = $kingpin->parse;

    is_deeply $args->value, [];
};


subtest 'repeatable flag 2 (is_cumulative)' => sub {
    local @ARGV;
    push @ARGV, qw(--xxx a --xxx b --xxx c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->file_list();
    #$args->is_cumulative(1);

    my $cmd = $kingpin->parse;

    is ref $args->value->[0], "Path::Tiny";
    is ref $args->value->[1], "Path::Tiny";
    is ref $args->value->[2], "Path::Tiny";
    is $args->value->[0], 'a';
    is $args->value->[1], 'b';
    is $args->value->[2], 'c';
};

subtest 'repeatable arg error' => sub {
    local @ARGV;
    push @ARGV, qw(a b c);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $args = $kingpin->arg("xxx", "xxx yyy")->string();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: unexpected b, try --help/;
    is $exit, 1;
};

subtest 'repeatable arg (is_cumulative)' => sub {
    local @ARGV;
    push @ARGV, qw(a b c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->arg("xxx", "xxx yyy")->string_list();

    my $cmd = $kingpin->parse;

    is_deeply $args->value, ['a', 'b', 'c'];
};

subtest 'repeatable arg (is_cumulative no-args)' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->arg("xxx", "xxx yyy")->string_list();

    my $cmd = $kingpin->parse;

    is_deeply $args->value, [];
};

subtest 'repeatable arg 2 (is_cumulative)' => sub {
    local @ARGV;
    push @ARGV, qw(a b c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->arg("xxx", "xxx yyy")->file_list();

    my $cmd = $kingpin->parse;

    is ref $args->value->[0], "Path::Tiny";
    is ref $args->value->[1], "Path::Tiny";
    is ref $args->value->[2], "Path::Tiny";
    is $args->value->[0], 'a';
    is $args->value->[1], 'b';
    is $args->value->[2], 'c';
};

subtest 'not repeatable and repeatable arg' => sub {
    local @ARGV;
    push @ARGV, qw(a b c);

    my $kingpin = Getopt::Kingpin->new();
    my $args1 = $kingpin->arg("xxx", "xxx yyy")->file();
    my $args2 = $kingpin->arg("yyy", "xxx yyy")->file_list();

    my $cmd = $kingpin->parse;

    is ref $args1->value, "Path::Tiny";
    is ref $args2->value->[0], "Path::Tiny";
    is ref $args2->value->[1], "Path::Tiny";
    is $args1->value, 'a';
    is $args2->value->[0], 'b';
    is $args2->value->[1], 'c';
};

subtest 'not repeatable and repeatable arg (required)' => sub {
    local @ARGV;
    push @ARGV, qw(a b c);

    my $kingpin = Getopt::Kingpin->new();
    my $args1 = $kingpin->arg("xxx", "xxx yyy")->required->file();
    my $args2 = $kingpin->arg("yyy", "xxx yyy")->file_list();

    my $cmd = $kingpin->parse;

    is ref $args1->value, "Path::Tiny";
    is ref $args2->value->[0], "Path::Tiny";
    is ref $args2->value->[1], "Path::Tiny";
    is $args1->value, 'a';
    is $args2->value->[0], 'b';
    is $args2->value->[1], 'c';
};

subtest 'not repeatable and repeatable arg 2 (required)' => sub {
    local @ARGV;
    push @ARGV, qw(a b c);

    my $kingpin = Getopt::Kingpin->new();
    my $args1 = $kingpin->arg("xxx", "xxx yyy")->required->file();
    my $args2 = $kingpin->arg("yyy", "xxx yyy")->required->file_list();

    my $cmd = $kingpin->parse;

    is ref $args1->value, "Path::Tiny";
    is ref $args2->value->[0], "Path::Tiny";
    is ref $args2->value->[1], "Path::Tiny";
    is $args1->value, 'a';
    is $args2->value->[0], 'b';
    is $args2->value->[1], 'c';
};

done_testing;

