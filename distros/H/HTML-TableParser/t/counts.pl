our ( $start, $end, $hdr, $nrow, $ncols );

sub start
{
  $hdr = 0;
  $nrow = 0;
  $ncols = 0;
  $end = 0;
  $start++;
};

sub   end{ $end++ };

sub hdr
{
  my( $tbl_id, $line_no, $col_names, $udata ) = @_;

  $hdr++;
  $ncols = @$col_names;
};

sub row
{
  my( $tbl_id, $line_no, $data ) = @_;

  $nrow++;
};


sub run
{
  my ( %req ) = @_;

  #------------------------------------------------------

  {
    my $p = HTML::TableParser->new( [ \%req ] ) or die;
    $p->parse_file( 'data/ned.html' ) || die;

    ok(   1 == $start &&
          1 == $end &&
          1 == $hdr &&
          15 == $ncols &&
          116 == $nrow,
          "ned check" );
  }

  #------------------------------------------------------

  $start = 0;
  {
    my $p = HTML::TableParser->new( [ \%req ] ) or die;
    $p->parse_file( 'data/screwy.html' ) || die;

    ok( 1 == $start &&
        1 == $end &&
        1 == $hdr &&
        8 == $ncols &&
        2 == $nrow,
        "screwy check" );
  }

  #------------------------------------------------------

  $start = 0;
  {
    my $p = HTML::TableParser->new( [ \%req ] ) or die;
    $p->parse_file( 'data/table.html' ) || die;

    ok( 1 == $start &&
        1 == $end &&
        1 == $hdr &&
        16 == $ncols &&
        8 == $nrow,
        "table check" );
  }
  #------------------------------------------------------

  $req{id} = 1;
  $start = 0;
  {
    my $p = HTML::TableParser->new( [ \%req ] );
    $p->parse_file( 'data/table2.html' ) || die;

    ok(   1 == $start &&
          1 == $end &&
          1 == $hdr &&
          16 == $ncols &&
          9 == $nrow,
          "table2 check1" );
  }
  #------------------------------------------------------

  $req{id} = 1.1;
  $start = 0;
  {
    my $p = HTML::TableParser->new( [ \%req ] ) or die;
    $p->parse_file( 'data/table2.html' ) || die;

    ok(   1 == $start &&
          1 == $end &&
          1 == $hdr &&
          16 == $ncols &&
          8 == $nrow,
          "table2 check2" );

  }

}
1;
