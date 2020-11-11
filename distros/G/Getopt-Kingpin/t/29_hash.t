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

subtest 'repeatable flag (is_hash)' => sub {
    local @ARGV;
    push @ARGV, qw(--xxx a=a --xxx b= --xxx c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->string_hash();

    my $cmd = $kingpin->parse;

    is_deeply $args->value, { a=>'a', b=>'', c=>undef };
};

subtest 'repeatable flag 2 (is_hash)' => sub {
    local @ARGV;
    push @ARGV, qw(--xxx a=a --xxx b=b --xxx c=c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->file_hash();

    my $cmd = $kingpin->parse;

    is ref $args->value->{'a'}, "Path::Tiny";
    is ref $args->value->{'b'}, "Path::Tiny";
    is ref $args->value->{'c'}, "Path::Tiny";
    is $args->value->{'a'}, 'a';
    is $args->value->{'b'}, 'b';
    is $args->value->{'c'}, 'c';
};

subtest 'repeatable flag 3 (is_hash)' => sub {
    local @ARGV;
    push @ARGV, qw(--xxx a=21 --xxx b=22 --xxx c=XYZ);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $args = $kingpin->flag("xxx", "xxx yyy")->int_hash();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    is ref($args->value), 'HASH';
    is $args->value->{'a'}, 21;
    is $args->value->{'b'}, 22;
    is $args->value->{'c'}, undef;

    like $stderr, qr/int parse error/;
    is $exit, 1;
};

subtest 'repeatable arg (is_hash)' => sub {
    local @ARGV;
    push @ARGV, qw(a=a b= c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->arg("xxx", "xxx yyy")->string_hash();

    my $cmd = $kingpin->parse;

    is_deeply $args->value, { a=>'a', b=>'', c=>undef };
};

subtest 'repeatable arg 2 (is_hash)' => sub {
    local @ARGV;
    push @ARGV, qw(a=a b=b c=c);

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->arg("xxx", "xxx yyy")->file_hash();

    my $cmd = $kingpin->parse;

    is ref $args->value->{'a'}, "Path::Tiny";
    is ref $args->value->{'b'}, "Path::Tiny";
    is ref $args->value->{'c'}, "Path::Tiny";
    is $args->value->{'a'}, 'a';
    is $args->value->{'b'}, 'b';
    is $args->value->{'c'}, 'c';
};

subtest 'repeatable flag (is_hash) with default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->default({a=>'a',b=>'',c=>undef})->string_hash();

    my $cmd = $kingpin->parse;

    is_deeply $args->value, { a=>'a', b=>'', c=>undef };
};

subtest 'repeatable flag (is_hash) with no default and no flag on command line' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new();
    my $args = $kingpin->flag("xxx", "xxx yyy")->string_hash();

    my $cmd = $kingpin->parse;

    is_deeply $args->value, {};
};

subtest 'repeatable flag (is_hash) with bad default' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $args = $kingpin->flag("xxx", "xxx yyy")->default({'a'=>'xyz'})->int_hash();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/;
    is $exit, 1;
};

done_testing;

