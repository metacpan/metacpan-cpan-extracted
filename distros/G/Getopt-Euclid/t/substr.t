BEGIN {
    @ARGV = (
        '-i', 'test',
        '-o', 'test2',
    );
}

use Getopt::Euclid;
use Test::More 'no_plan';

is $ARGV{'-i'}, 'test'   => 'Got expected value for -i';
is $ARGV{'-o'}, 'test2'  => 'Got expected value for -o';

__END__

=head1 NAME

substr.pl - short description

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=item -o <o>

=item -i <i>
