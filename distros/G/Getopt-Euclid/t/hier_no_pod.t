BEGIN {
    $INFILE  = $0;
    $OUTFILE = $0;

    @ARGV = (
        '-i', $INFILE,
        "-out=$OUTFILE",
    );

    chmod 0644, $0;
}

use t::lib::HierDemo;
use Test::More 'no_plan';

is keys %ARGV, 6 => 'Right number of args returned';

# Manual should contain POD from .pl and .pm files
my $man = <<EOS;
\=head1 REQUIRED ARGUMENTS

\=over

\=item -i[nfile]  [=]<file>

Specify input file

\=item -o[ut][file]= <file>

Specify output file

\=back



EOS

my $man_test = Getopt::Euclid->man();
is $man_test, $man, 'Man page is as expected';

