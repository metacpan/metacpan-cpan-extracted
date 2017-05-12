use strict;
use Test::More 0.98;
use Test::Exception;
use Getopt::Kingpin;


subtest 'type error' => sub {
    local @ARGV;
    push @ARGV, qw(--verbose);

    my $kingpin = Getopt::Kingpin->new();
    my $verbose = $kingpin->flag('verbose', 'Verbose mode.')->short('v')->bool();
    $verbose->type("__type_error__");
    throws_ok {
        $kingpin->parse;
    } qr/type error '__type_error__'/;
};

subtest 'type error 2' => sub {
    local @ARGV;

    my $kingpin = Getopt::Kingpin->new();
    throws_ok {
        $kingpin->flag('verbose', 'Verbose mode.')->short('v')->type_error();
    } qr/type error 'TypeError'/;
};

done_testing;

