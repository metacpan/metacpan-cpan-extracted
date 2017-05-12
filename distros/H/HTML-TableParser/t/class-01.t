use Test::More tests => 4;

BEGIN { use_ok( 'HTML::TableParser' ); }

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

}

{
  package Foo;
  sub new
  {
    my $this = shift;
    my $class = ref($this) || $this;

    my $self = {};
    bless $self, $class;
  }

  sub start { shift; &::start } 
  sub end   { shift; &::end } 
  sub hdr   { shift; &::hdr } 
  sub row   { shift; &::row }
}

{
  my $p = HTML::TableParser->new( [ { id => 'DEFAULT',
				    class => 'Foo' } ]
				) or die;
  $p->parse_file( 'data/ned.html' ) || die;
  
  ok( 1 == $end, "class method check" );
}

{
  my $p = HTML::TableParser->new( [{ id => 'DEFAULT',
				    class => 'Foo',
				    end => undef
				  }]
				) or die;
  $p->parse_file( 'data/ned.html' ) || die;
  
  ok( 0 == $end, "class method undef check" );
}

{
  my $foo = Foo->new();
  my $p = HTML::TableParser->new( [{ id => 'DEFAULT',
				    obj => $foo,
				    end => undef
				  }]
				) or die;
  $p->parse_file( 'data/ned.html' ) || die;
  
  ok( 0 == $end, "object method undef check" );
}
