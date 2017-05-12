use strict;
use Test::More tests => 2;


BEGIN { use_ok('HTML::Menu::Select', 'menu') };

SKIP: {
  eval "require CGI::Simple";
  
  if ($@) {
    skip "CGI::Simple not available", 1;
  }
  
  die "CGI::Simple does not appear to be loaded"
    unless exists $::INC{'CGI/Simple.pm'};
  
  
  my $html = menu(
    name  => ' < ',
    value => [' > '],
  );
  
  my $regex1 = '<select name=" &lt; ">';
  my $regex2 = '<option value=" &gt; "> &gt; </option>';
  my $regex3 = '</select>';
  
  ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E\s*\Q$regex3\E/s );
}
