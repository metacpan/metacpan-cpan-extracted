BEGIN {
    @ARGV = qw/ -a foo /
}

use Test::More 'no_plan';

if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 1 => 'Optional argument not read as required';
}
else {
    ok 0 => 'Optional argument read as required'; 
}

=head1 REQUIRED

=over

=item -a <a>

=back

=cut

=head1 OPTIONS

=over

=item -b <b>

=back

=cut