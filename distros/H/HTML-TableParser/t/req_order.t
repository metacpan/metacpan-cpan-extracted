use Test::More tests => 3;

BEGIN { use_ok( 'HTML::TableParser' ); }

require './t/common.pl';

my $header = [];
my @parse_data;

sub start
{
  @parse_data = ();
}

sub row
{
  my ( $tbl_id, $line_no, $data, $udata ) = @_;

  my $data_s = join("\t", @$data);

  push @parse_data, $data_s;
}

sub header
{
  my ( $tbl_id, $line_no, $col_names, $udata ) = @_;

  $header = $col_names;
}

@reqs = (
          {
	   colre => [ qr/NO MATCH POSSIBLE/ ],
	  },
          {
	   id => 'DEFAULT',
	   start => \&start,
	   hdr => \&header,
	   row => \&row 
	  },
	) ;


my $html = 'data/ned.html';
my @data_t = ( 'Default' );
my ($columns, $data, $datafile ) = read_table_data( $html, \@data_t );

my $p = HTML::TableParser->new( \@reqs );
$p->parse_file( 'data/ned.html' ) || die;

ok( eq_array( $header, $columns ), "$html header" );
ok( eq_array( $data->{Default}, \@parse_data ), "$html data" );




