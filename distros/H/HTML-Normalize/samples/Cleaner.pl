use strict;
use warnings;

use HTML::Normalize;

my $html = <<'HTML';
<FONT color="#0000ff" face="Verdana" size="1">
<p>paragraph</p>
</font>
<P align="center"><a href="#"><br/>
<font color="#0000ff" face="Verdana" size="1">&euro; 750aa</font>
<B><i>foo</b></i>
<font face="Verdana" size="1"><b><i></i></b></font>
<br /></a>
</p>
HTML

my $cleaner = HTML::Normalize->new (
    -default     => 'font face =~ /Verdana/i ',
    -default     => 'font size = 1',
    -default     => 'p style=\'margin-bottom: 0cm;\'',
    -selfrender  => 1,
);

print $cleaner->cleanup (-html => $html);

