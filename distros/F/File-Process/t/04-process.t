use strict;
use warnings;

use lib qw(.);

use Data::Dumper;
use Test::More tests => 11;
use List::Util qw(all none);

use_ok('File::Process');

File::Process->import('process_csv');

my $fh        = *DATA;
my $start_pos = tell $fh;

our $NUM_COLS;

########################################################################
subtest 'is_array' => sub {
########################################################################

  File::Process::Utils->import('is_array');

  my $t = [];

  ok( is_array($t), '[] is an array' );

  ok( !is_array(q{}), 'empty string is not an array' );

  ok( !is_array(undef), 'undef is not an array' );

  ok( !is_array(), 'no argument is not an array' );

  ok( !is_array( {} ), 'hash is not an array' );

  my $foo = [ 0 .. 9 ];

  my (@foo) = is_array($foo);

  is( @foo, scalar @{$foo}, 'wantarray: returned a list' );

  (@foo) = is_array();

  ok( !@foo, 'wantarray: empty list' );

  (@foo) = is_array( [] );

  ok( !@foo, 'wantarray: empty list' );
};

########################################################################
subtest 'is_hash' => sub {
########################################################################

  File::Process::Utils->import('is_hash');

  my $t = {};

  ok( is_hash($t), '{}] is an array' );

  ok( !is_hash(q{}), 'empty string is not an hash' );

  ok( !is_hash(undef), 'undef is not an hash' );

  ok( !is_hash(), 'no argument is not an hash' );

  ok( !is_hash( [] ), 'array is not an hash' );

  my $foo = { foo => 1, bar => 2 };

  my (%foo) = is_hash($foo);

  is( keys %foo, scalar keys %{$foo}, 'wantarray: returned a list' );

  (%foo) = is_hash();

  ok( !keys %foo, 'wantarray: empty list' );

  (%foo) = is_hash( [] );

  ok( !keys %foo, 'wantarray: empty list' );
};

########################################################################
subtest 'header' => sub {
########################################################################
  my $columns = <$fh>;
  chomp $columns;

  seek $fh, $start_pos, 0;

  my ($obj) = process_csv(
    $fh,
    has_headers => 1,
    keep_open   => 1,
    csv_options => { sep_char => "\t" }
  );

  isa_ok( $obj, 'ARRAY', 'returns an array' )
    or do {
    diag($obj);
    BAIL_OUT('did not return an ARRAY');
    };

  isa_ok( $obj->[0], 'HASH', 'returns an array of hashes' );

  my %columns = map { $_ => undef } split /\t/xsm, $columns;

  $NUM_COLS = keys %columns;

  is( keys %{ $obj->[0] }, $NUM_COLS, "$NUM_COLS keys" )
    or diag( Dumper( [ $obj->[0] ] ) );

  is( scalar( grep { exists $columns{$_} } keys %{ $obj->[0] } ),
    $NUM_COLS, 'all columns found' );
};

########################################################################
subtest 'has_header => 0, column_names => undef' => sub {
########################################################################

  seek $fh, $start_pos, 0;

  <$fh>; # clear header

  my ($obj) = process_csv(
    $fh,
    keep_open   => 1,
    csv_options => { sep_char => "\t" }
  );

  isa_ok( $obj->[0], 'ARRAY', 'default array' );
};

########################################################################
subtest 'provided column names' => sub {
########################################################################

  seek $fh, $start_pos, 0;

  my $header = <$fh>;
  chomp $header;

  my @column_names = split /\t/xsm, $header;

  my ($obj) = process_csv(
    $fh,
    column_names => \@column_names,
    keep_open    => 1,
    csv_options  => { sep_char => "\t" }
  );

  isa_ok( $obj->[0], 'HASH', $obj->[0] )
    or diag( Dumper( [ 'column_names:', \@column_names, 'obj:', $obj ] ) );

  is( keys %{ $obj->[0] }, $NUM_COLS, "$NUM_COLS keys" )
    or diag( Dumper( [ 'column_names:', \@column_names, 'obj:', $obj ] ) );

};

########################################################################
subtest 'empty column names' => sub {
########################################################################

  seek $fh, $start_pos, 0;

  my $header = <$fh>;
  chomp $header;

  my ($obj) = process_csv(
    $fh,
    column_names => [],
    keep_open    => 1,
    csv_options  => { sep_char => "\t" }
  );

  is( @{$obj}, 9, 'all rows read' );

  isa_ok( $obj->[0], 'HASH', $obj->[0] )
    or diag( Dumper( [ 'obj:', $obj ] ) );

  is( keys %{ $obj->[0] }, $NUM_COLS, "$NUM_COLS keys" )
    or diag( Dumper( [ 'NUM_COLS:', $NUM_COLS, 'obj:', $obj ] ) );

  SKIP: {
    if ( $NUM_COLS != keys %{ $obj->[0] } ) {
      skip 'not enough keys', 1;
    }

    ok(
      ( all {/^col\d+/xsm} keys %{ $obj->[0] } ),
      'keys all have names like col\d+'
    ) or diag( Dumper( [ 'obj:', $obj ] ) );
  }
};

########################################################################
subtest 'array of hooks' => sub {
########################################################################
  seek $fh, $start_pos, 0;

  my $header = <$fh>;

  my @hooks;

  $hooks[0] = $hooks[1] = sub { return uc shift };

  my ($obj) = process_csv(
    $fh,
    keep_open   => 1,
    csv_options => { sep_char => "\t" },
    hooks       => \@hooks,
  );

  isa_ok( $obj, 'ARRAY' );

  ok( ( all {/^[[:upper:] ]+$/xsm} map { $_->[0] } @{$obj} ),
    'col 0 all caps' )
    or do {
    diag( Dumper( [ map { $_->[0] } @{$obj} ] ) );
    BAIL_OUT('hook failure');
    };

  ok( ( all {/^[[:upper:] ]+$/xsm} map { $_->[1] } @{$obj} ),
    'col 1 all caps' )
    or do {
    diag( Dumper( [ map { $_->[1] } @{$obj} ] ) );
    BAIL_OUT('hook failure');
    };

};

########################################################################
subtest 'hash of hooks' => sub {
########################################################################
  seek $fh, $start_pos, 0;

  my $header = <$fh>;

  my %hooks;

  $hooks{col0} = $hooks{col1} = sub { return uc shift };

  my ($obj) = process_csv(
    $fh,
    column_names => [],
    keep_open    => 1,
    csv_options  => { sep_char => "\t" },
    hooks        => \%hooks,
  );

  isa_ok( $obj, 'ARRAY' );

  ok( ( all {/^[[:upper:] ]+$/xsm} map { $_->{col0} } @{$obj} ),
    'col 0 all caps' )
    or do {
    diag( Dumper( [ map { $_->{col0} } @{$obj} ] ) );
    BAIL_OUT('hook failure');
    };

  ok( ( all {/^[[:upper:] ]+$/xsm} map { $_->{col1} } @{$obj} ),
    'col 1 all caps' )
    or do {
    diag( Dumper( [ map { $_->{col1} } @{$obj} ] ) );
    BAIL_OUT('hook failure');
    };

};

########################################################################
subtest 'process hook' => sub {
########################################################################
  seek $fh, $start_pos, 0;

  my $header = <$fh>;

  my ($obj) = process_csv(
    $fh,
    column_names => [],
    keep_open    => 1,
    csv_options  => { sep_char => "\t" },
    process      => sub {
      my ( $fh, $lines, $args, $row ) = @_;
      for ( 0, 1 ) {
        $row->{"col$_"} = uc $row->{"col$_"};
      }
      return $row;
    }
  );

  isa_ok( $obj, 'ARRAY' )
    or diag( Dumper( [$obj] ) );

  ok( ( all {/^[[:upper:] ]+$/xsm} map { $_->{col0} } @{$obj} ),
    'col 0 all caps' )
    or do {
    diag( Dumper( [ map { $_->{col0} } @{$obj} ] ) );
    BAIL_OUT('hook failure');
    };

  ok( ( all {/^[[:upper:] ]+$/xsm} map { $_->{col1} } @{$obj} ),
    'col 1 all caps' )
    or do {
    diag( Dumper( [ map { $_->{col1} } @{$obj} ] ) );
    BAIL_OUT('hook failure');
    };

};

########################################################################
subtest 'skip_list' => sub {
########################################################################
  seek $fh, $start_pos, 0;

  my $header = <$fh>;

  my ($obj) = process_csv(
    $fh,
    column_names => [],
    keep_open    => 1,
    skip_list    => { col2     => 1 },
    csv_options  => { sep_char => "\t" },
  );

  isa_ok( $obj, 'ARRAY' )
    or diag( Dumper( [$obj] ) );

  ok( ( none { exists $_->{col2} } @{$obj} ), 'col2 dropped' )
    or diag( Dumper($obj) );

  seek $fh, $start_pos, 0;

  <$fh>;

  my %options = (
    keep_open   => 1,
    skip_list   => [2],
    csv_options => { sep_char => "\t" },
  );

  ($obj) = process_csv( $fh, %options );

  isa_ok( $obj->[0], 'ARRAY' )
    or diag( Dumper( [ 'obj', $obj ] ) );

  is( @{ $obj->[0] }, 3, '1 dropped column' );

};

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
