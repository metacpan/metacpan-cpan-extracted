BEGIN {
    $INFILE  = 'test.generic';

    @ARGV = (
        '-input_files', $INFILE,
    );

    chmod 0644, $0;
}

use Getopt::Euclid qw( :minimal_keys );
use Test::More 'no_plan';

sub got_arg {
    my ($key, $val) = @_;
    is $ARGV{$key}, $val, "Got expected value for $key";
}

is keys %ARGV, 8 => 'Right number of args returned';

is ref $ARGV{'input_files'}, 'ARRAY'  => 'Array reference returned for input_files';
is $ARGV{'input_files'}->[0], $INFILE => 'Got expected value for input_files';

is ref $ARGV{'if'}, 'ARRAY'  => 'Array reference returned for input_files';
is $ARGV{'if'}->[0], $INFILE => 'Got expected value for input_files';

got_arg 'dist_type'     => 'euclidean';
got_arg 'dt'            => 'euclidean';

got_arg 'weight_assign' => 'ancestor';
got_arg 'wa'            => 'ancestor';

got_arg 'output_prefix' => 'bc_distance';
got_arg 'op'            => 'bc_distance';

__END__

=head1 OPTIONAL ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

=item -wa <weight_assign> | -weight_assign <weight_assign>

=for Euclid:
   weight_assign.default: 'ancestor'

=item -op <output_prefix> | -output_prefix <output_prefix>

=for Euclid:
   output_prefix.type: string
   output_prefix.default: 'bc_distance'

=item -dt <dist_type> | -dist_type <dist_type>

=for Euclid:
   dist_type.default: 'euclidean'

=back

