use strict;
use Test::More 0.98;
use Getopt::Kingpin;


subtest 'double dash' => sub {
    local @ARGV;
    push @ARGV, qw(--name kingpin -- path);

    my $kingpin = Getopt::Kingpin->new();
    my $name = $kingpin->flag("name", "")->string();
    my $path = $kingpin->arg("path", "")->file();

    $kingpin->parse;

    my $x = $name->value;

    is $name, "kingpin";
    is $path, "path";
};

subtest 'double dash 2' => sub {
    local @ARGV;
    push @ARGV, qw(--name kingpin -- --path);

    my $kingpin = Getopt::Kingpin->new();
    my $name = $kingpin->flag("name", "")->string();
    my $path = $kingpin->arg("path", "")->file();

    $kingpin->parse;

    my $x = $name->value;

    is $name, "kingpin";
    is $path, "--path";
};

subtest 'double dash 3' => sub {
    local @ARGV;
    push @ARGV, qw(-n kingpin -- -v);

    my $kingpin = Getopt::Kingpin->new();
    my $name    = $kingpin->flag("name", "")->short("n")->string();
    my $verbose = $kingpin->flag("verbose", "")->short("v")->bool();
    my $path    = $kingpin->arg("path", "")->file();

    $kingpin->parse;

    my $x = $name->value;

    is $name, "kingpin";
    is $verbose, 0;
    is $path, "-v";
};

done_testing;

