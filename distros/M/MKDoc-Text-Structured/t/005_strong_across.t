use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
* Hello, *I will not
* be bold*
* but
* *I will be*

This is a paragraph. *Nothing in this paragraph
is going to be bold.

Nor in this one*.
EOF

my $res = MKDoc::Text::Structured::process ($text);

like ($res, qr#<ul><li><p>Hello, \*I will not</p></li>#);
like ($res, qr#<li><p>be bold\*</p></li>#);
like ($res, qr#<li><p>but</p></li>#);
like ($res, qr#<li><p><strong>I will be</strong></p></li></ul>#);
like ($res, qr#<p>This is a paragraph. \*Nothing in this paragraph#);
like ($res, qr#is going to be bold.</p>#);
like ($res, qr#<p>Nor in this one\*.</p>#);


1;

__END__
