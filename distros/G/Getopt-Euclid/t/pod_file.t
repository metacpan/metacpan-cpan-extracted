BEGIN {
    $INFILE  = $0;
    $OUTFILE = $0;
    $LEN     = 42;
    $H       = 2;
    $W       = -10;
    $TIMEOUT = 7;

    @ARGV = (
        '-i', $INFILE,
        "-out=$OUTFILE",
        '-lgth', $LEN,
        'size', "${H}x${W}",
        '-v',
        '--timeout', $TIMEOUT,
        '--with', 's p a c e s',
        7,
    );

    chmod 0644, $0;
}

sub lucky {
    my ($num) = @_;
    return $num == 7;
}

# Read POD from .pod file

use Getopt::Euclid;

use Test::More 'no_plan';

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

is keys %ARGV, 18 => 'Right number of args returned';

got_arg -i       => $INFILE;
got_arg -infile  => $INFILE;

got_arg -l       => $LEN;
got_arg -len     => $LEN;
got_arg -length  => $LEN;
got_arg -lgth    => $LEN;

got_arg -girth   => 42;

got_arg -o       => $OUTFILE;
got_arg -ofile   => $OUTFILE;
got_arg -out     => $OUTFILE;
got_arg -outfile => $OUTFILE;

got_arg -v       => 1,
got_arg -verbose => 1,

is ref $ARGV{'--timeout'}, 'HASH'     => 'Hash reference returned for timeout';
is $ARGV{'--timeout'}{min}, $TIMEOUT  => 'Got expected value for timeout <min>';
is $ARGV{'--timeout'}{max}, -1        => 'Got default value for timeout <max>';

is ref $ARGV{size}, 'HASH'      => 'Hash reference returned for size';
is $ARGV{size}{h}, $H           => 'Got expected value for size <h>';
is $ARGV{size}{w}, $W           => 'Got expected value for size <w>';

is $ARGV{'--with'}, 's p a c e s'      => 'Handled spaces correctly';
is $ARGV{-w},       's p a c e s'      => 'Handled alternation correctly';

is $ARGV{'<step>'}, 7      => 'Handled step size correctly';
