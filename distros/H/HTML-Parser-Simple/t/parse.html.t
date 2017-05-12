use strict;
use warnings;

use File::Spec;

use HTML::Parser::Simple;

use Test::More tests => 1;

# -----------------------------------

my($p) = HTML::Parser::Simple -> new(input_file  => File::Spec -> catfile('data', 's.1.html') );

open(my $fh, '<', $p -> input_file) || BAILOUT("Can't read data/s.1.html");
my($html);
read($fh, $html, -s $fh);
close $fh;

my(@got)      = split(/\n/, $p -> parse($html) -> traverse($p -> root) -> result);
my($expected) = <<EOS;
<html>
<body>

<img src = "/My.Image.png" alt = "My pix">

<p>Start of table.</p>

<table WIDTH=660 align=center>
  <tbody>

  <tr>

     <td>
        <br>td11<br>
     </td>
     <td>
        <br>td12<br>
     </td>

  </tr>

  <tr>

     <td>
        <br>td21<br>
     </td>
     <td>
        <br>td22<br>
     </td>

  </tr>

</tbody>
</table>

<p>End of table.</p>

</body>
</html>
EOS

my(@expected) = split(/\n/, $expected);

is_deeply(\@got, \@expected, 'Got expected output of HTML::Parser::Simple.parse($html)');