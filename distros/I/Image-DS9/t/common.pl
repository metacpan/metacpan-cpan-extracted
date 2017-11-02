#! perl

use Test::Deep;
use Test::More;

use lib 't/lib';
use TestServer;

our $verbose = 0;

sub start_up  {

    my $ds9 = t::TestServer->new( $verbose );

    $ds9->raise();
    return $ds9;
}

sub clear
{
  my $ds9 = shift;

  $ds9->frame( delete => 'all' );
  $ds9->frame( 'new' );
}


sub load_events
{
  my $ds9 = shift;

  $ds9->file( 'data/snooker.fits.gz', { extname => 'raytrace',
                                        bin => [ 'rt_x', 'rt_y' ] } );
  $ds9->bin( factor => 0.025 );
  $ds9->zoom( 0 );
}

sub test_stuff
{
  my ( $ds9, @stuff ) = @_;


  while ( my ( $cmd, $subcmds ) = splice( @stuff, 0, 2 ) )
  {
    last if $cmd eq 'stop';

    while ( my ( $subcmd, $args ) = splice( @$subcmds, 0, 2 ) )
    {
      my @subcmd = ( 'ARRAY' eq ref $subcmd ? @$subcmd : $subcmd );
      $subcmd = join( ' ', @subcmd);

      $args = [ $args ] unless 'ARRAY' eq ref $args;

      my $ret;
      eval {
        $ds9->$cmd(@subcmd, @$args);
        $ret = $ds9->$cmd(@subcmd);
      };

      diag($@, explain($ds9->res) ) && fail( "$cmd $subcmd" ) if $@;

      if ( ! ref($ret) && 1 == @$args )
      {
        is( $ret, $args->[0], join( " ", $cmd, $subcmd,  @$args ) );
      }
      elsif ( @$ret == @$args )
      {
        cmp_deeply( $ret, $args,  "$cmd $subcmd" );
      }
      else
      {
        fail( "$cmd $subcmd" );
      }
    }
  }

}


1;
