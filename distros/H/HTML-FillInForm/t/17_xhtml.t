# -*- Mode: Perl; -*-

use strict;

$^W = 1;

print "1..1\n";

use HTML::FillInForm;
use CGI;

my $html = <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
<html>
<body>
    <input type="radio" name="status" value=0 />Canceled<br>
    <input type="radio" name="status" value=1 />Confirmed<br>
    <input type="radio" name="status" value=2 />Wait List<br>

    <input type="radio" name="status" value=3 />No Show<br>
    <input type="radio" name="status" value=4 />Moved to Another Class<br>
    <input type="radio" name="status" value=5 />Late Cancel<br>
</body>
</html>
EOF

my $q = CGI->new;
$q->param('status', 1 );

my $fif = HTML::FillInForm->new;

my $output = $fif->fill(
    scalarref => \$html,
    fobject => $q
);

my $matches;
while ($output =~ m!( />)!g) {
  $matches++;
}

if ($matches == 6) {
  print "ok 1\n";
} else {
  print "not ok 1\n";
}

print $output;
