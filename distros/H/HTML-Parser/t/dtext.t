use strict;
use warnings;
use utf8;

use HTML::Parser ();
use Test::More tests => 2;

my $dtext = "";
my $text  = "";

sub append {
    $dtext .= shift;
    $text  .= shift;
}

my $p = HTML::Parser->new(
    text_h    => [\&append, "dtext, text"],
    default_h => [\&append, "text,  text" ],
);

my $doc = <<'EOT';
<title>&aring</title>
<a href="foo&aring">&aring&aring;&#65&#65;&lt&#65&gt;&#x41&#X41;</a>
<?&aring>
foo&nbsp;bar
foo&nbspbar
&xyzzy
&xyzzy;
<!-- &#0; -->
&#1;
&#255;
&#xFF
&#xFFG
<!-- &#256; -->
&#40000000000000000000000000000;
&#x400000000000000000000000000000000;
&
&#
&#x
<xmp>&aring</xmp>
<script>&aring</script>
<ScRIPT>&aring</scRIPT>
<skript>&aring</script>
EOT

$p->parse($doc)->eof;

is($text, $doc);
is($dtext, <<"EOT");
<title>å</title>
<a href="foo&aring">ååAA<A>AA</a>
<?&aring>
foo\240bar
foo\240bar
&xyzzy
&xyzzy;
<!-- &#0; -->
\1
\377
\377
\377G
<!-- &#256; -->
&#40000000000000000000000000000;
&#x400000000000000000000000000000000;
&
&#
&#x
<xmp>&aring</xmp>
<script>&aring</script>
<ScRIPT>&aring</scRIPT>
<skript>å</script>
EOT
