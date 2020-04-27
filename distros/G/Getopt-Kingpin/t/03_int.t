use strict;
use Test::More 0.98;
use Test::Exception;
use Capture::Tiny ':all';
use Getopt::Kingpin;


subtest 'int normal with overload' => sub {
    local @ARGV;
    push @ARGV, qw(--x 0);

    my $kingpin = Getopt::Kingpin->new;
    my $x = $kingpin->flag('x', 'set x')->int();
    $kingpin->parse;

    is $x, 0;
    ok $x == 0;
};


subtest 'int error with overload' => sub {
    local @ARGV;
    push @ARGV, qw(--x ZERO);

    my $kingpin = Getopt::Kingpin->new;
    $kingpin->terminate(sub {return @_});
    my $x = $kingpin->flag('x', 'set x')->int();
    my ($stdout, $stderr, $ret, $exit) = capture {
        $kingpin->parse;
    };

    like $stderr, qr/int parse error/, 'int parse error';
    is $exit, 1;

};

done_testing;

