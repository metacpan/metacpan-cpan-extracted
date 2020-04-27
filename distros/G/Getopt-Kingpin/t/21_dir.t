use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'existing_dir' => sub {
    local @ARGV;
    push @ARGV, qw(lib);

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->arg("path", "")->existing_dir();

    $kingpin->parse;

    my $x = $path->value;

    is $path, "lib";
    is ref $path, "Getopt::Kingpin::Arg";

    is $x, "lib";
    is ref $x, "Path::Tiny";

    is $x->is_dir, 1;
};

subtest 'existing_dir is file' => sub {
    local @ARGV;
    push @ARGV, qw(Build.PL);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $path = $kingpin->arg("path", "")->existing_dir();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: 'Build.PL' is a file, try --help/;
    is $exit, 1;
};

subtest 'existing_dir error' => sub {
    local @ARGV;
    push @ARGV, qw(NOT_FOUND_DIR);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $path = $kingpin->arg("path", "")->existing_dir();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: path 'NOT_FOUND_DIR' does not exist, try --help/;
    is $exit, 1;
};

subtest 'existing_dir with default' => sub {
    local @ARGV;

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->arg("path", "")->default("lib")->existing_dir();

    $kingpin->parse;

    is $path, "lib";
    is ref $path->value, "Path::Tiny";
    is $path->value->is_dir, 1;
};

subtest 'existing_dir with envar' => sub {
    local @ARGV;
    $ENV{KINGPIN_TEST_PATH} = "lib";

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->arg("path", "")->override_default_from_envar("KINGPIN_TEST_PATH")->existing_dir();

    $kingpin->parse;

    is $path, "lib";
    is ref $path->value, "Path::Tiny";
    is $path->value->is_dir, 1;
};

done_testing;

