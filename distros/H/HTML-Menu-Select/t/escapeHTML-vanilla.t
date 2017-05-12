use strict;
use Test::More tests => 2;


BEGIN { use_ok('HTML::Menu::Select', 'menu') };


for (qw/ CGI CGI::Simple::Util HTML::Entities Apache::Util /) {
  my $mod;
  ($mod = $_) =~ s|::|/|g;
  
  die "$_ is already loaded - why?"
    if exists $::INC{"$mod.pm"};
}

my $html = menu(
  name  => ' < ',
  value => [' > '],
);

my $regex1 = '<select name=" &lt; ">';
my $regex2 = '<option value=" &gt; "> &gt; </option>';
my $regex3 = '</select>';

ok( $html =~ /\Q$regex1\E\s*\Q$regex2\E\s*\Q$regex3\E/s );

