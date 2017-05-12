use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
* Hello, _I will not
* be bold_
* but
* _I will be_

This is a paragraph. _Nothing in this paragraph
is going to be bold.

Nor in this one_.
EOF

my $res = MKDoc::Text::Structured::process ($text);

like ($res, qr#<ul><li><p>Hello, _I will not</p></li>#);
like ($res, qr#<li><p>be bold_</p></li>#);
like ($res, qr#<li><p>but</p></li>#);
like ($res, qr#<li><p><em>I will be</em></p></li></ul>#);
like ($res, qr#<p>This is a paragraph. _Nothing in this paragraph#);
like ($res, qr#is going to be bold.</p>#);
like ($res, qr#<p>Nor in this one_.</p>#);


1;

__END__
