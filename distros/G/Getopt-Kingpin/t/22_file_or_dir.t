use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'existing_file_or_dir file' => sub {
    local @ARGV;
    push @ARGV, qw(Build.PL);

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->arg("path", "")->existing_file_or_dir();

    $kingpin->parse;

    my $x = $path->value;

    is $path, "Build.PL";
    is ref $path, "Getopt::Kingpin::Arg";

    is $x, "Build.PL";
    is ref $x, "Path::Tiny";
    ok $x->is_file;
};

subtest 'existing_file_or_dir dir' => sub {
    local @ARGV;
    push @ARGV, qw(lib);

    my $kingpin = Getopt::Kingpin->new();
    my $path = $kingpin->arg("path", "")->existing_file_or_dir();

    $kingpin->parse;

    my $x = $path->value;

    is $path, "lib";
    is ref $path, "Getopt::Kingpin::Arg";

    is $x, "lib";
    is ref $x, "Path::Tiny";
    ok $x->is_dir;
};

subtest 'existing_file_or_dir not found' => sub {
    local @ARGV;
    push @ARGV, qw(NOT_FOUND);

    my $kingpin = Getopt::Kingpin->new();
    $kingpin->terminate(sub {return @_});
    my $path = $kingpin->arg("path", "")->existing_file_or_dir();

    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/error: path 'NOT_FOUND' does not exist, try --help/;
    is $exit, 1;
};

done_testing;

