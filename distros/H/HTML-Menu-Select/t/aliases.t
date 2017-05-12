use Test::More tests => 19;

BEGIN { use_ok('HTML::Menu::Select', 'options') };


{ # value (single)
  my $html = options(
    value  => 'a',
  );
  
  my $regex1 = '<option value="a">a</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
}

{ # value (multiple)
  my $html = options(
    value  => [1, 2],
  );
  
  my $regex1 = '<option value="1">1</option>';
  my $regex2 = '<option value="2">2</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}


{ # values (single)
  my $html = options(
    values  => 'b',
  );
  
  my $regex1 = '<option value="b">b</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
}


{ # values (multiple)
  my $html = options(
    values  => [3, 4],
  );
  
  my $regex1 = '<option value="3">3</option>';
  my $regex2 = '<option value="4">4</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
}


{ # default (single)
  my $html = options(
    values  => [6, 7, 8],
    default => 7,
  );
  
  my $regex1 = '<option value="6">6</option>';
  my $regex2 = '<option selected="selected" value="7">7</option>';
  my $regex3 = '<option value="8">8</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
  ok( $html =~ /\Q$regex3\E/ );
}


{ # default (multiple)
  my $html = options(
    values  => ['c', 'd', 'e'],
    default => ['d', 'e'],
  );
  
  my $regex1 = '<option value="c">c</option>';
  my $regex2 = '<option selected="selected" value="d">d</option>';
  my $regex3 = '<option selected="selected" value="e">e</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
  ok( $html =~ /\Q$regex3\E/ );
}


{ # defaults (single)
  my $html = options(
    values   => [9, 10, 11],
    defaults => 10,
  );
  
  my $regex1 = '<option value="9">9</option>';
  my $regex2 = '<option selected="selected" value="10">10</option>';
  my $regex3 = '<option value="11">11</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
  ok( $html =~ /\Q$regex3\E/ );
}


{ # defaults (multiple)
  my $html = options(
    values   => ['f', 'g', 'h'],
    defaults => ['f', 'g'],
  );
  
  my $regex1 = '<option selected="selected" value="f">f</option>';
  my $regex2 = '<option selected="selected" value="g">g</option>';
  my $regex3 = '<option value="h">h</option>';
  
  ok( $html =~ /\Q$regex1\E/ );
  ok( $html =~ /\Q$regex2\E/ );
  ok( $html =~ /\Q$regex3\E/ );
}

