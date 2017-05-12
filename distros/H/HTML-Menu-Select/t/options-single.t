use Test::More tests => 5;

BEGIN { use_ok('HTML::Menu::Select', 'options') };

{ # BASIC
  my $html = options(
    values => [1],
  );
  
  my $regex = '<option value="1">1</option>';
  
  ok( $html =~ /\Q$regex\E/ );
}

{ # SELECTED
  my $html = options(
    values  => [2],
    default => 2,
  );
  
  my $regex = '<option selected="selected" value="2">2</option>';
  
  ok( $html =~ /\Q$regex\E/ );
}

{ # LABEL
  my $html = options(
    values  => [3],
    default => 3,
    labels  => {3 => 'three'},
  );
  
  my $regex = '<option selected="selected" value="3">three</option>';
  
  ok( $html =~ /\Q$regex\E/ );
}

{ # ATTRIBUTE
  my $html = options(
    values     => [4],
    default    => 4,
    labels     => {4 => 'four'},
    attributes => {4 => {onSelect => 'do(this);'}},
  );
  
  my $regex = '<option selected="selected" onSelect="do(this);" value="4">four</option>';
  
  ok( $html =~ /\Q$regex\E/ );
}
