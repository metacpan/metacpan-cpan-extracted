use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
Features
========

* MKDoc is multilingual
  ---------------------
 
  You can create multilingual web sites using as many languages as required since MKDoc 
  supports Unicode.

  Content of any language and character set can be stored, searched and displayed as easily as  
  English. MKDoc supports the full Unicode character set, including right-to-left languages and 
  Indic languages e.g. Arabic, Urdu. 

* MKDoc is complete
  -----------------

EOF

my $res = MKDoc::Text::Structured::process ($text);

like ($res, qr#<h2>Features</h2>#);
like ($res, qr#<ul><li><h3>MKDoc is multilingual</h3>#);
like ($res, qr#<p>You can create multilingual web sites using as many languages as required since MKDoc#);
like ($res, qr#supports Unicode.</p>#);
like ($res, qr#<p>Content of any language and character set can be stored, searched and displayed as easily as#);
like ($res, qr#English. MKDoc supports the full Unicode character set, including right-to-left languages and#);
like ($res, qr#Indic languages e.g. Arabic, Urdu.</p></li>#);
like ($res, qr#<li><h3>MKDoc is complete</h3></li></ul>#);


1;

__END__
