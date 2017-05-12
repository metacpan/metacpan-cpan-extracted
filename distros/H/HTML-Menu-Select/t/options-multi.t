use Test::More tests => 25;

BEGIN { use_ok('HTML::Menu::Select', 'options') };

{ # 2 OPTIONS
  my $html = options(
    values => [1, 2],
  );
  
  my $regex1 = '<option value="1">1</option>';
  my $regex2 = '<option value="2">2</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 1st SELECTED
  my $html = options(
    values  => [3, 4],
    default => 3,
  );
  
  my $regex1 = '<option selected="selected" value="3">3</option>';
  my $regex2 = '<option value="4">4</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 2nd SELECTED
  my $html = options(
    values  => [5, 6],
    default => 6,
  );
  
  my $regex1 = '<option value="5">5</option>';
  my $regex2 = '<option selected="selected" value="6">6</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 2nd SELECTED - ALIAS
  my $html = options(
    values   => [5, 6],
    defaults => 6,
  );
  
  my $regex1 = '<option value="5">5</option>';
  my $regex2 = '<option selected="selected" value="6">6</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # BOTH SELECTED - ALIAS
  my $html = options(
    values  => [5, 6],
    default => [5, 6],
  );
  
  my $regex1 = '<option selected="selected" value="5">5</option>';
  my $regex2 = '<option selected="selected" value="6">6</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # BOTH SELECTED
  my $html = options(
    values   => [5, 6],
    defaults => [5, 6],
  );
  
  my $regex1 = '<option selected="selected" value="5">5</option>';
  my $regex2 = '<option selected="selected" value="6">6</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 1st LABEL
  my $html = options(
    values  => [7, 8],
    default => 7,
    labels  => {7 => 'seven'},
  );
  
  my $regex1 = '<option selected="selected" value="7">seven</option>';
  my $regex2 = '<option value="8">8</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 2nd LABEL
  my $html = options(
    values  => [7, 8],
    default => 7,
    labels  => {8 => 'eight'},
  );
  
  my $regex1 = '<option selected="selected" value="7">7</option>';
  my $regex2 = '<option value="8">eight</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # BOTH LABELS
  my $html = options(
    values  => [7, 8],
    default => 7,
    labels  => {7 => 'seven', 8 => 'eight'},
  );
  
  my $regex1 = '<option selected="selected" value="7">seven</option>';
  my $regex2 = '<option value="8">eight</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 1st ATTRIBUTE
  my $html = options(
    values     => [9, 10],
    default    => 9,
    labels     => {9 => 'nine', 10 => 'ten'},
    attributes => {9 => {onSelect => 'do(this);'}},
  );
  
  my $regex1 = '<option selected="selected" onSelect="do(this);" value="9">nine</option>';
  my $regex2 = '<option value="10">ten</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # 2nd ATTRIBUTE
  my $html = options(
    values     => [9, 10],
    default    => 9,
    labels     => {9 => 'nine', 10 => 'ten'},
    attributes => {10 => {onSelect => 'do(this);'}},
  );
  
  my $regex1 = '<option selected="selected" value="9">nine</option>';
  my $regex2 = '<option onSelect="do(this);" value="10">ten</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}

{ # ATTRIBUTES
  my $html = options(
    values     => [9, 10],
    default    => 9,
    labels     => {9 => 'nine', 10 => 'ten'},
    attributes => {9 => {onSelect => 'do(this);'}, 10 => {onSelect => 'and(that);'}},
  );
  
  my $regex1 = '<option selected="selected" onSelect="do(this);" value="9">nine</option>';
  my $regex2 = '<option onSelect="and(that);" value="10">ten</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}
