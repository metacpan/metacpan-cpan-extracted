use strict;
use Test::More;
use File::Find;
use File::Spec;

# let's test all the log files in t/
my @files = ( "doesnotexist.log" );
find( sub { push @files, $File::Find::name if /\.log$/ }, 't' );

# the command-line parameters to test
my @args = qw( -h -k -km -kl -kt -ks );

my $tests = @files * @args * 3 - @args;
plan tests => $tests;

SKIP: {
    eval { require Test::Cmd; };
    skip "mailstat does not exist on $^O", $tests
      if $^O =~ /^(?:dos|os2|MSWin32)/;
    skip "Test::Cmd not installed", $tests if $@;

    my $mailstat;
    find( sub { $mailstat = $File::Find::name if $_ eq 'mailstat' && -x },
          split /:/, $ENV{PATH} );

    SKIP: {
        skip "mailstat not found", $tests unless $mailstat;

        # Test::Cmd need to be a singleton...
        my $test = Test::Cmd->new( workdir => '');

        # arguments for each script
        my @orig = ( prog => $mailstat );
        my @perl = ( prog => './scripts/mailstat.pl', interpreter => $^X );

        # compare output, errput and status code for all combinations
        for my $file ( @files ) {
            for my $args ( @args ) {
                $test->run( @orig, args => "$args $file" );
                my $orig_out = $test->stdout;
                my $orig_err = $test->stderr;
                my $orig_sts = $? >> 8;
                $test->run( @perl, args => "$args $file" );
                my $perl_out = $test->stdout;
                my $perl_err = $test->stderr;
                my $perl_sts = $? >> 8;

                is( $perl_out, $orig_out, "Same output for $args $file" );
                is( $perl_err, $orig_err, "Same errput for $args $file" )
                  if $file !~ /empty\.log/; # ignore errput for empty.log
                is( $perl_sts, $orig_sts, "Same status code for $args $file" );
            }
        }
    }
}

