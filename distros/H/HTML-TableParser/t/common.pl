sub read_table_data
{
  my ( $html, $data_t ) = @_;

  ( my $hdrfile = $html ) =~ s/.html/.hdr/;

  open FILE, $hdrfile or die( "unable to open $hdrfile\n" );
  @columns = <FILE>;
  chomp(@columns);

  my %data;
  foreach my $type ( @$data_t )
  {
    ( my $datafile = $html ) =~ s/.html/.$type.data/;

    open FILE, $datafile
      or die( "couldn't open datafile $datafile{$type}\n");
    local $/ = $; ;
    $data{$type} = [<FILE>];
    chomp(@{$data{$type}});
  }

  \@columns, \%data;
}

1;
