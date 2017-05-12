use Test::More tests => 8;

BEGIN { use_ok('HTML::Menu::Select', 'menu') };

{ # BASIC
  my $html = menu(
    values => [1],
  );
  
  my $regex1 = '<select name="">';
  my $regex2 = '<option value="1">1</option>';
  my $regex3 = '</select>';
  
  ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E\s*\Q$regex3\E/s );
}

{ # NAME
  my $html = menu(
    name   => 'myMenu',
    values => [1],
  );
  
  my $regex1 = '<select name="myMenu">';
  my $regex2 = '<option value="1">1</option>';
  my $regex3 = '</select>';
  
  ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E\s*\Q$regex3\E/s );
}

{ # UNKNOWN KEY
  my $html = menu(
    name     => 'myMenu',
    values   => [1],
    onSelect => 'do(this);',
  );
  
  my $regex1 = '<select name="myMenu" onSelect="do(this);">';
  my $regex2 = '<option value="1">1</option>';
  my $regex3 = '</select>';
  
  ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E\s*\Q$regex3\E/s );
}

{ # UNKNOWN KEYS
  my $html = menu(
    name     => 'myMenu',
    id       => 'myMenu',
    values   => [1],
    onSelect => 'do(this);',
  );
  
  ok( $html =~ /<select name="myMenu"/ );
  ok( $html =~ /id="myMenu"/ );
  ok( $html =~ /onSelect="do\(this\);"/ );
  
  my $regex1 = '<option value="1">1</option>';
  my $regex2 = '</select>';
  
  ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E/s );
}
