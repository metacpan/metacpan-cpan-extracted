BEGIN {
    $INFILE  = $0;
    $OUTFILE = $0;

    @ARGV = (
        '-i', $INFILE,
        "-out=$OUTFILE",
    );

    chmod 0644, $0;
}

use Getopt::Euclid ( );
use Test::More 'no_plan';


sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}


is scalar @ARGV, 3 => '@ARGV processing was defered';
is keys %ARGV, 0 => '%ARGV processing was defered';

my @pods = ( './t/lib/HierDemo2.pm' );
Getopt::Euclid->process_pods(\@pods);


is scalar @ARGV, 3 => '@ARGV processing was defered';
is keys %ARGV, 0 => '%ARGV processing was defered';


Getopt::Euclid->process_args(\@ARGV);


got_arg -i       => $INFILE;
got_arg -infile  => $INFILE;

got_arg -o       => $OUTFILE;
got_arg -ofile   => $OUTFILE;
got_arg -out     => $OUTFILE;
got_arg -outfile => $OUTFILE;
