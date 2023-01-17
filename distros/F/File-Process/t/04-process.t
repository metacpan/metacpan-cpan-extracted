use strict;
use warnings;

use lib qw(.);

use Data::Dumper;
use Test::More tests => 4;

use_ok('File::Process::Utils');

File::Process::Utils->import('process_csv');

my $fh  = *DATA;
my $pos = tell $fh;

my $columns = <$fh>;
chomp $columns;

seek $fh, $pos, 0;

my $obj = process_csv(
  $fh,
  has_headers => 1,
  csv_options => { sep_char => "\t" }
);

isa_ok( $obj, 'ARRAY', 'returns an array' )
  or do {
  diag($obj);
  BAIL_OUT('did not return an ARRAY');
  };

isa_ok( $obj->[0], 'HASH', 'returns an array of hashes' );

my %columns = map { $_ => undef } split /\t/xsm, $columns;

my $num_cols = keys %columns;

is( scalar( grep { exists $columns{$_} } keys %{ $obj->[0] } ),
  $num_cols, 'all columns found' );

1;

__DATA__
State	Capital	Population of Capital (census)	Population of Capital (estimated)
Alabama	Montgomery	(2020) 200,603	(2018 est.) 198,218
Alaska	Juneau	(2010) 31,275	(2018 est.) 32,113
Arizona	Phoenix	(2020) 1,608,139	(2018 est.) 1,660,272
Arkansas	Little Rock	(2020) 202,591	(2018 est.) 197,881
California	Sacramento	(2020) 524,943	(2018 est.) 508,529
Colorado	Denver	(2020) 715,522	(2018 est.) 716,492
Connecticut	Hartford	(2020) 121,054	(2018 est.) 122,587
Delaware	Dover	(2010) 26,047	(2018 est.) 38,079
Florida	Tallahassee	(2020) 196,169	(2018 est.) 193,551
