use strict;
use Test::More 0.98;
use Test::Exception;
use Test::Trap;
use Getopt::Kingpin;


subtest 'file' => sub {
    local @ARGV;
    push @ARGV, qw(kingpin Build.PL);

    my $kingpin = Getopt::Kingpin->new();
    my $name = $kingpin->arg("name", "")->string();
    my $path = $kingpin->arg("path", "")->file();

    $kingpin->parse;

    my $x = $name->value;

    is $name, "kingpin";
    is ref $name, "Getopt::Kingpin::Arg";

    is $x, "kingpin";
    is ref $x, "";

    my $y = $path->value;

    is $path, "Build.PL";
    is ref $path, "Getopt::Kingpin::Arg";

    is $y, "Build.PL";
    is ref $y, "Path::Tiny";
};

subtest 'existing_file' => sub {
    local @ARGV;
    push @ARGV, qw(kingpin Build.PL);

    my $kingpin = Getopt::Kingpin->new();
    my $name = $kingpin->arg("name", "")->string();
    my $path = $kingpin->arg("path", "")->existing_file();

    $kingpin->parse;

    my $x = $name->value;

    is $name, "kingpin";
    is ref $name, "Getopt::Kingpin::Arg";

    is $x, "kingpin";
    is ref $x, "";

    my $y = $path->value;

    is $path, "Build.PL";
    is ref $path, "Getopt::Kingpin::Arg";

    is $y, "Build.PL";
    is ref $y, "Path::Tiny";
};

subtest 'existing_file is dir' => sub {
    local @ARGV;
    push @ARGV, qw(lib);

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->arg("path", "")->existing_file();

    trap {
        $kingpin->parse;
    };

    like $trap->stderr, qr/error: 'lib' is a directory, try --help/;
    is $trap->exit, 1;
};

subtest 'existing_file error' => sub {
    local @ARGV;
    push @ARGV, qw(kingpin Build.PL NOT_FOUND_FILE);

    my $kingpin = Getopt::Kingpin->new();
    my $name = $kingpin->arg("name", "")->string();
    my $path = $kingpin->arg("path", "")->file();
    my $not_found = $kingpin->arg("not_found", "")->existing_file();

    trap {
        $kingpin->parse;
    };

    like $trap->stderr, qr/error: path 'NOT_FOUND_FILE' does not exist, try --help/;
    is $trap->exit, 1;
};

subtest 'file with default' => sub {
    local @ARGV;

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->flag("path", "")->default("Build.PL")->file();

    $kingpin->parse;

    is $path, "Build.PL";
    is ref $path->value, "Path::Tiny";
};

done_testing;

