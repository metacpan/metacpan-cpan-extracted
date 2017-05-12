use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
> > Hey, that's pretty cool!

> Well, sort-of

I think it's pretty cool...
EOF

my $res = MKDoc::Text::Structured::process ($text);
like ($res, qr#<blockquote><blockquote><p>Hey, that\'s pretty cool!</p></blockquote>#);
like ($res, qr#<p>Well, sort-of</p></blockquote>#);
like ($res, qr#<p>I think it\'s pretty cool&hellip;</p>#);

1;

__END__
