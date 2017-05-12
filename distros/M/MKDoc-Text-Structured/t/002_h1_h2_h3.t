use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
==========
Headline 1
==========

Headline 2
==========

Headline 3
----------
EOF

my $res = MKDoc::Text::Structured::process ($text);

like ($res, qr#<h1>Headline 1</h1>#);
like ($res, qr#<h2>Headline 2</h2>#);
like ($res, qr#<h3>Headline 3</h3>#);

1;

__END__
