use Test2::V0 -no_srand => 1;
use File::Listing::Ftpcopy qw( parse_dir );

my $value;
parse_dir( [ 'bogus' ], undef, undef, sub { $value = shift } );

is $value, 'bogus', 'value = bogus';

done_testing;
