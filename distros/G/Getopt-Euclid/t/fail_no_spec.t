use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

BEGIN {
    $INFILE  = $0;
    $OUTFILE = 'nexistpas';
    $LEN     = 42;
    $H       = 2;
    $W       = -10;
    $TIMEOUT = 7;

    @ARGV = (
        '-v',
        "-out=", $OUTFILE,
        "size", "${H}x${W}",
        "-i", $INFILE,
        "-lgth", $LEN,
        "--timeout", $TIMEOUT,
    );
}

if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Unknown argument/   => 'Failed as expected'; 
}
