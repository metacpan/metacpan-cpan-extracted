#!perl

use Test::More 0.88;

BEGIN {
    use_ok( 'Getopt::Modular', '-namespace', 'GM');
}

GM->acceptParam(
                'foo|f' => {
                    spec => '!',
                    help => qq[helpful foo that has a really nice, long annoying run-on boring description],
                    default => 5,
                },
                'zoo|Z' => {
                    spec => '=s',
                    help => qq[zoo],
                    valid_values => [ qw/abbc bccd cdde/ ],
                },
                'zed' => {
                    spec => '=s',
                    help => 'zed',
                    valid_values => sub { qw/ one two three / },
                },
                'bar|b' => {
                    spec => '!',
                    help => qq[helpful bar that has a really nice, long annoying run-on boring description],
                    default => 1,
                    help_bool => [ qw/ yuck yum / ],
                },
               );

my $help = GM->getHelp(
                       {
                           valid_values => sub { join '', "XYZ ", @_ },
                           current_value => sub { join '', "ABC ", grep defined, @_ },
                       }
                      );
like($help, qr/XYZ abbcbccdcdde/);
like($help, qr/ABC yum/);
like($help, qr/XYZ onetwothree/);

done_testing();
