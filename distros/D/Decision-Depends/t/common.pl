sub touch
{
  my $time = time();

  my @times;
  foreach ( @_ )
  {
    unless ( -f $_ )
    {
      open( FILE, ">$_" ) or die( "unable to create $_\n");
      close(FILE);
    }
    utime( $time, $time, $_ );
    push @times, $time;
    $time++;
  }
  @times;
}


1;
