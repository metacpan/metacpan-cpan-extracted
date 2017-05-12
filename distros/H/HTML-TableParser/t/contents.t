use strict;
use warnings;

use Test::More tests => 131;

use IO::File;
use File::Basename;

BEGIN { use_ok( 'HTML::TableParser' ); }

require './t/common.pl';

our $verbose = 0;
our $create = 1;

our $header;
our $columns;

our @parse_data;


my $fh;

sub start
{
  my ( $tbl_id, $line_no, $udata ) = @_;

  print STDERR "start: $tbl_id\n" if $verbose;

  die( "whoops! we're already in the middle of a table!\n" )
    if @parse_data;
  @parse_data = ();
}

sub start_create
{
  @parse_data = ();
  my ( $tbl_id, $line_no, $udata ) = @_;

  print STDERR "start_create: $tbl_id\n" if $verbose;


  $fh = IO::File->new( $udata->{data}, 'w' ) 
    or die( "unable to create $udata->{data}\n" );
}

sub end_create
{
  my ( $tbl_id, $line_no, $udata ) = @_;

  print STDERR "end_create: $tbl_id\n" if $verbose;

  $fh->close;
}

sub row
{
  my ( $tbl_id, $line_no, $data, $udata ) = @_;

  print STDERR "row: $tbl_id\n" if $verbose;

  my $data_s = join("\t", @$data);

  print $fh $data_s, $;
    if $create;

  push @parse_data, $data_s;
}

sub header
{
  my ( $tbl_id, $line_no, $col_names, $udata ) = @_;

  print STDERR "header: $tbl_id\n" if $verbose;

  $header = $col_names;

  if ( $create )
  {
    open FILE, ">$udata->{hdr}" or die;
    print FILE "$_\n" foreach @$col_names;
    close FILE;

    @$columns = @$col_names;
  }

}

our @data_t = qw( Default Chomp Trim Decode );

opendir( DDIR, 'data' ) or die( "error reading dir data\n" );
my @html = map { "data/$_" } grep { /.html$/ } readdir( DDIR );
closedir DDIR;

for my $html ( @html )
{
  ( my $hdrfile = $html ) =~ s/.html/.hdr/;


  my %req = ( hdr => \&header, row => \&row,
	      udata => { hdr => $hdrfile }
	      );

  my $data;
  unless( $create )
  {
    ($columns, $data ) = read_table_data( $html, \@data_t );

    $req{start} = \&start;
  }
  else
  {
    $req{start} = \&start_create;
    $req{end} = \&end_create;
  }

  foreach my $type ( @data_t )
  {
    my %attr = $type eq 'Default' ? () : ( $type => 1 );

    ( my $datafile = $html ) =~ s/.html/.$type.data/;
    $req{udata}{data} = $datafile;
    
    {
      local $req{id} = 1;
      my $p = HTML::TableParser->new( [ \%req ], \%attr );
      undef @parse_data;
      $header = undef;
      $p->parse_file( $html ) || die;
      ok( eq_array( $header, $columns ), "$html id" );
      $data->{$type} = [@parse_data] if $create;
      ok( eq_array( $data->{$type}, \@parse_data ), "$html($type) id data" );
    }

    {
      local $req{cols} = [ $columns->[0] ];
      my $p = HTML::TableParser->new( [ \%req ], \%attr );
      undef @parse_data;
      $header = undef;
      $p->parse_file( $html ) || die;
      ok( eq_array( $header, $columns ), "$html cols" );
      ok( eq_array( $data->{$type}, \@parse_data ), "$html($type) cols data" );
    }

    {
      my $re = $columns->[-1];
      substr($re, -1, 1, '');
      local $req{colre} = [ $re ];
      undef @parse_data;
      $header = undef;
      my $p = HTML::TableParser->new( [ \%req ], \%attr );
      $p->parse_file( $html ) || die;
      ok( eq_array( $header, $columns ), "$html colre" );
      ok( eq_array( $data->{$type}, \@parse_data ), "$html($type) colre data" );
    }

    {
      $header = undef;
      local $req{cols} = [ "this column doesn't exist" ];
      undef @parse_data;
      $header = undef;
      my $p = HTML::TableParser->new( [ \%req ], \%attr );
      $p->parse_file( $html ) || die;
      ok( !defined $header, "$html($type) cols: no match" );
    }
  }

}


# table2.html has an embedded table.  check that out now.
{
  my $html = 'data/table2.html';
  my $fakehtml = 'data/table2-1.html';
  my $hdrfile = 'data/table2-1.hdr';

  my %req = ( hdr => \&header, row => \&row,
	      udata => { hdr => $hdrfile }
	      );

  my $data;
  my $datafile;
  unless( $create )
  {
    ($columns, $data, $datafile ) = read_table_data( $fakehtml, \@data_t );

    $req{start} = \&start;
  }
  else
  {
    $req{start} = \&start_create;
    $req{end} = \&end_create;
  }

  foreach my $type ( @data_t )
  {
    my %attr = $type eq 'Default' ? () : ( $type => 1 );

    ( my $datafile = $fakehtml ) =~ s/.html/.$type.data/;

    $req{udata}{data} = $datafile;
    $header = undef;
    {
      local $req{id} = 1.1;
      my $p = HTML::TableParser->new( [ \%req ], \%attr );
      undef @parse_data;
      $p->parse_file( $html ) || die;
      ok( eq_array( $header, $columns ), "$fakehtml id" );
      $data->{$type} = [@parse_data] if $create;
      ok( eq_array( $data->{$type}, \@parse_data ), "$fakehtml($type) id data" );
    }
  }
}

# check id coderef mode. no need to do the create bit,
# as we're reusing stuff from just above here
{
  local $create = 0;

  my $html = 'data/table2.html';
  my $fakehtml = 'data/table2-1.html';
  my $hdrfile = 'data/table2-1.hdr';

  my %req = ( hdr => \&header, row => \&row, start => \&start,
	      id => sub { $_[0] eq '1.1' },
	      udata => { hdr => $hdrfile, 
			 data => 'data/table2-1.Default.data' }
	    );


  my ( $data, $datafile );
  ($columns, $data, $datafile ) = read_table_data( $fakehtml, [ 'Default' ] );

  $header = undef;

  my $p = HTML::TableParser->new( [ \%req ] );
  undef @parse_data;
  $p->parse_file( $html ) || die;
  ok( eq_array( $header, $columns ), "$fakehtml id = coderef" );

  ok( eq_array( $data->{Default}, \@parse_data ), 
      "$fakehtml(Default) id = coderef data" );

}

# check id exclude mode. no need to do the create bit,
# as we're reusing stuff from just above here
{
  local $create = 0;

  my $html = 'data/table2.html';
  my $fakehtml = 'data/table2-1.html';
  my $hdrfile = 'data/table2-1.hdr';

  my %req = ( hdr => \&header, row => \&row, start => \&start,
	      id => [ '-', sub { $_[0] eq '1' }, 'DEFAULT' ],
	      udata => { hdr => $hdrfile, 
			 data => 'data/table2-1.Default.data' }
	    );


  my ( $data, $datafile );
  ($columns, $data, $datafile ) = read_table_data( $fakehtml, [ 'Default' ] );

  $header = undef;

  my $p = HTML::TableParser->new( [ \%req ] );
  undef @parse_data;
  $p->parse_file( $html ) || die;
  ok( eq_array( $header, $columns ), "$fakehtml id exclude" );

  ok( eq_array( $data->{Default}, \@parse_data ), 
      "$fakehtml(Default) id exclude data" );

}


# check id skip mode.
# no need to do the create bit,
# as we're reusing stuff from just above here
{
  local $create = 0;

  my $html = 'data/table2.html';
  my $fakehtml = 'data/table2-1.html';
  my $hdrfile = 'data/table2-1.hdr';

  my @reqs = 
    ( 
      { id => [ '--', '1' ] },
      {
       hdr => \&header, row => \&row, start => \&start,
       id => 'DEFAULT',
       udata => { hdr => $hdrfile, 
		  data => 'data/table2-1.Default.data' }
      }
    );


  my ( $data, $datafile );
  ($columns, $data, $datafile ) = read_table_data( $fakehtml, [ 'Default' ] );

  $header = undef;

  my $p = HTML::TableParser->new( \@reqs );
  undef @parse_data;
  $p->parse_file( $html ) || die;
  ok( eq_array( $header, $columns ), "$fakehtml id skip" );

  ok( eq_array( $data->{Default}, \@parse_data ), 
      "$fakehtml(Default) id skip data" );

}


# check id re mode. no need to do the create bit,
# as we're reusing stuff from just above here
{
  local $create = 0;

  my $html = 'data/table2.html';
  my $fakehtml = 'data/table2-1.html';
  my $hdrfile = 'data/table2-1.hdr';

  my %req = ( hdr => \&header, row => \&row, start => \&start,
	      id => qr/\.1$/,
	      udata => { hdr => $hdrfile, 
			 data => 'data/table2-1.Default.data' }
	    );


  my ( $data, $datafile );
  ($columns, $data, $datafile ) = read_table_data( $fakehtml, [ 'Default' ] );

  $header = undef;
  my $p = HTML::TableParser->new( [ \%req ] );
  undef @parse_data;
  $p->parse_file( $html ) || die;
  ok( eq_array( $header, $columns ), "$fakehtml idre" );

  ok( eq_array( $data->{Default}, \@parse_data ), 
      "$fakehtml(Default) idre data" );
}


# check cols coderef mode. no need to do the create bit,
# as we're reusing stuff from just above here
{
  use Data::Dumper;
  local $create = 0;

  my $html     = 'data/screwy.html';
  my $datafile = 'data/screwy.Default.data';
  my $hdrfile  = 'data/screwy.hdr';

  my %req = ( hdr => \&header, row => \&row, start => \&start,
	      cols => sub { grep { /Widget A/ } @{$_[2]}  },
	      udata => { hdr => $hdrfile, 
			 data => $datafile }
	    );


  my $data;
  ($columns, $data, $datafile ) = read_table_data( $html, [ 'Default' ] );

  $header = undef;

  my $p = HTML::TableParser->new( [ \%req ] );
  undef @parse_data;
  $p->parse_file( $html ) || die;
  ok( eq_array( $header, $columns ), "$html cols = coderef" );

  ok( eq_array( $data->{Default}, \@parse_data ), 
      "$html(Default) cols = coderef data" );

}

