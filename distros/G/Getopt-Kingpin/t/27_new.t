use strict;
use warnings;
use utf8;
use Test::More;
use Getopt::Kingpin;

subtest 'run' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new({
            name => 'run.pl',
        });

    is $kingpin->name, 'run.pl';
    is $kingpin->description, '';
};

subtest 'run' => sub {
    local @ARGV;
    push @ARGV, qw();

    my $kingpin = Getopt::Kingpin->new(
            name => 'run.pl',
            description => 'run.pl description',
        );

    is $kingpin->name, 'run.pl';
    is $kingpin->description, 'run.pl description';
};

done_testing;

