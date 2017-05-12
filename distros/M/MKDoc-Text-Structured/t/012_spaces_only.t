use warnings;
use strict;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use MKDoc::Text::Structured;

my $text = <<EOF;
1. Some Text

   Some more text

2. Some Text
EOF

my $res = MKDoc::Text::Structured::process ($text);

# use Data::Dumper; print Dumper $res;

=cut

<ol><li><p>Some Text</p></li></ol>
<pre>
  Some more text</pre>
<ol><li><p>Some Text</p></li></ol>

=cut

like ($res, qr#<ol><li><p>Some Text</p>#);
like ($res, qr#<p>Some more text</p></li>#);
like ($res, qr#<li><p>Some Text</p></li></ol>#);

1;

__END__
