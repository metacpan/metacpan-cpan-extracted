use strict;
use Test::More tests => 2;


BEGIN { use_ok('HTML::Menu::Select', 'menu') };

SKIP: {
  eval "require CGI";
  
  if ($@) {
    skip "CGI not available", 1;
  }
  
  die "CGI does not appear to be loaded"
    unless exists $::INC{'CGI.pm'};
  
  
  my $html = menu(
    name  => 'and&this',
    value => ['"'],
  );
  
  my $regex1 = '<select name="and&amp;this">';
  my $regex2 = '<option value="&quot;">&quot;</option>';
  my $regex3 = '</select>';
  
  ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E\s*\Q$regex3\E/s );
}
