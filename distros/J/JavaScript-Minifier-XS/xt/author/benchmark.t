use strict;
use warnings;
use Test::More;
use File::Basename qw(basename);
use File::Slurp qw(write_file);
use File::Which qw(which);
use Benchmark qw(countit);
use JavaScript::Minifier;
use JavaScript::Minifier::XS;
use Number::Format qw(format_bytes);

###############################################################################
# Only run Benchmark if asked for.
unless ($ENV{BENCHMARK}) {
    plan skip_all => 'Skipping Benchmark; use BENCHMARK=1 to run';
}

###############################################################################
# Find "curl"
my $curl = which('curl');
unless ($curl) {
    plan skip_all => 'curl required for comparison';
}

###############################################################################
# What JS files do we want to try compressing?
my @libs = (
    'http://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.js',
    'http://code.jquery.com/jquery-3.5.1.js',
    'http://cdnjs.cloudflare.com/ajax/libs/react/17.0.1/cjs/react.development.js',
);

###############################################################################
# time test the PurePerl version against the XS version.
my $time = 1;
foreach my $uri (@libs) {
    subtest $uri => sub {
        my $content = qx{$curl --silent $uri};
        ok defined $content, 'fetched JS';
        BAIL_OUT("No JS fetched!") unless (length($content));

        # Run the benchmarks
        do_compress('JavaScript::Minifier', $content, sub {
            my $js    = shift;
            my $small = JavaScript::Minifier::minify(input => $js);
            return $small;
        } );

        do_compress('JavaScript::Minifier::XS', $content, sub {
            my $js    = shift;
            my $small = JavaScript::Minifier::XS::minify($js);
            return $small;
        } );
    };
}

###############################################################################
done_testing();


sub do_compress {
    my $name = shift;
    my $js   = shift;
    my $cb   = shift;

    # Compress the JS
    my $small;
    my $count = countit($time, sub { $small = $cb->($js) } );

    # Stuff the compressed JS out to file for examination
    my $fname = lc($name);
    $fname =~ s{\W+}{-}g;
    write_file("$fname.out", $small);

    # Calculate length, speed, and percent savings
    my $before   = length($js);
    my $after    = length($small);
    my $rate     = sprintf('%ld', ($count->iters / $time) * $before);
    my $savings  = sprintf('%0.2f%%', (($before - $after) / $before) * 100);

    my $results  = sprintf("%30s before[%7d] after[%7d] savings[%6s] rate[%8s/sec]",
      $name, $before, $after, $savings, format_bytes($rate, unit => 'K', precision => 0),
    );
    pass $results;
}
