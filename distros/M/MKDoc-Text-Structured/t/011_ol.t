use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
1. An item
2. Another item

3. Headlines work too
   ==================

   * An un-ordered list
   * Can be nested
   * It should all work nicely.
EOF

my $res = MKDoc::Text::Structured::process ($text);
like ($res, qr#<ol><li><p>An item</p></li>#);
like ($res, qr#<li><p>Another item</p></li>#);
like ($res, qr#<li><h2>Headlines work too</h2>#);
like ($res, qr#<ul><li><p>An un-ordered list</p></li>#);
like ($res, qr#<li><p>Can be nested</p></li>#);
like ($res, qr#<li><p>It should all work nicely.</p></li></ul></li></ol>#);

1;

__END__
