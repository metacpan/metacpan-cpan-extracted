use strict;
use warnings;
use Encode;

my $charset = shift or die "Usage: $0 utf-8";

my $message = $charset =~ /utf-?8/i ? "ゆーてぃーえふ" : encode('cp932', decode('utf-8', "えすじす"));

print <<"...";
<?xml version="1.0" encoding="$charset"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="ja" xml:lang="ja" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=$charset" />
    <title>i-mode pictogram test</title>
</head>
<body>
<p>target charset: $charset($message)</p>
<h1>docomo</h1>
<ol>
    <li>uni hex cref: &#xE63E;</li>
    <li>uni dec cref: &#58942;</li>
    <li>utf8 binary: @{[ encode 'utf-8', "\x{E63E}" ]}</li>
    <li>sjis hex cref: &#xF89F;</li>
    <li>sjis dec cref: &#x63647;</li>
    <li>sjis binary: \xF8\x9F</li>
</ol>

<p>target charset: $charset($message)</p>
<h1>airh</h1>
<ol>
    <li>uni hex cref: &#xE093;</li>
    <li>uni dec cref: &#57491;</li>
    <li>utf8 binary: @{[ encode 'utf-8', "\x{E093}" ]}</li>
    <li>sjis hex cref: &#xF0D4;</li>
    <li>sjis dec cref: &#@{[ 0xF0D4 ]};</li>
    <li>sjis binary: \xF0\xD4</li>
</ol>

</body>
</html>
...

