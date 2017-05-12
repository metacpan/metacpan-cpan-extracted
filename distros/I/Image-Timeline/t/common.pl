
sub has_gif {
  return GD::Image->can('gif') && GD::Image->new(1,1)->gif;
}

sub new_with_data {
  my $datafile = shift;
  my $t = new Image::Timeline(width => 600);
  
  local *DATA;
  open DATA, $datafile or die "$datafile: $!";
  while (<DATA>) {
    my @data = /(.*) \((\d+)-(\d+)\)/ or next;
    $t->add(@data);
  }
  close DATA;
  return $t;
}

sub write_and_compare {
  my ($t, $name, $truthname, $suffix) = @_;
  
  my $outfile = "$name.$suffix";
  my $method = "write_$suffix";
  $t->$method($outfile);
  return (-e $outfile, &files_identical($outfile, "$truthname.$suffix"));
}

sub files_identical {
  my ($one, $two) = @_;
  local $/;
  my $data_one = do {local *F; open F, $one or die "$one: $!"; <F>};
  my $data_two = do {local *F; open F, $two or die "$two: $!"; <F>};
  return $data_one eq $data_two;
}

1;
