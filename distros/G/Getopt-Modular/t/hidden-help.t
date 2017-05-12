#!perl

use Test::More 0.88;

BEGIN {
    use_ok( 'Getopt::Modular', '-namespace', 'GM');
}

use Data::Dumper;

GM->acceptParam(
                'foo|f' => {
                    spec => '!',
                    help => qq[helpful foo that has a really nice, long annoying run-on boring description],
                    default => 5,
                },
                'zoo|Z' => {
                    spec => '=s',
                    help => qq[zoo],
                    hidden => 1,
                    valid_values => [ qw/abbc bccd cdde/ ],
                },
                'bar|b' => {
                    spec => '!',
                    help => qq[helpful bar that has a really nice, long annoying run-on boring description],
                    default => 1,
                    help_bool => [ qw/ yuck yum / ],
                },
               );

my @l = GM->getHelpRaw();
is(@l, 3, "All params returned");

SKIP: {
    eval { require Text::Table; 1 } or skip 'Optional module Text::Table missing', 3;

    my $help = GM->getHelp();
    unlike($help, qr/--zoo/, "--zoo is hidden");
}

done_testing();
