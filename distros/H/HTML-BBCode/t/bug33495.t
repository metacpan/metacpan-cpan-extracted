#########################

use Test::More tests => 3;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

my $text = "[url=ftp://somehost.com/some/path/and/file]Some file[/url]";
is($bbc->parse($text), '<a href="ftp://somehost.com/some/path/and/file">Some file</a>');
