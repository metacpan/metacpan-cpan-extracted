BEGIN {
    @ARGV = (
        '-a', 1, '-b 2',
    );
    # This is equivalent to running:
    #    quoted_args_2.t -a 1 '-b 2'
    # or:
    #    quoted_args_2.t -a 1 -b\ 2
}

use Getopt::Euclid;
use Test::More 'no_plan';

use Data::Dumper; print Dumper(\%ARGV);

is keys %ARGV, 1 => 'Right number of args returned';

is ref $ARGV{'-a'}, 'ARRAY'         => 'Array reference returned for -a';
is $ARGV{'-a'}[0],  1               => 'Got expected value for -a[0]';
is $ARGV{'-a'}[1],  '-b 2'          => 'Got expected value for -a[1]';

ok not( exists $ARGV{'-b'} )        => 'Nothing returned for -b';


=head1 REQUIRED ARGUMENTS

=over

=item -a <a>...

=back

=head1 OPTIONS

=over

=item -b <b>

=back

=cut
