use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
This is _strong text_

_I_ am _here_
EOF

my $res = MKDoc::Text::Structured::process ($text);
like ($res, qr#<p>This is <em>strong text</em></p>#);
like ($res, qr#<em>I</em>#);
like ($res, qr#<em>here</em>#);

1;

__END__
