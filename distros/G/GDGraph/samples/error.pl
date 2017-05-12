use strict;
use GD::Graph::Data;

my $data = GD::Graph::Data->new()    
      or die GD::Graph::Data->error;
  $data->read(file => '/foo/bar.data') 
        or die $data->error;

