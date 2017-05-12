use strict;
use warnings;

use HTML::Trim;

use Test::More;
use Test::Base -Base;
use Test::Base::Filter;
use Encode;

filters qw/norm chomp u8/;

plan tests => 1 * blocks;
run_is input => 'expected';

sub u8 {
	decode_utf8 $_;
}

sub htrim {
	my $str  = $_;
	my $args = filter_arguments || '';
	my ($max, $delim) = split /\s*,\s*/, $args;
	HTML::Trim::trim($str, $max || 5, $delim || "...");
}

sub hvtrim {
	my $str  = $_;
	my $args = filter_arguments || '';
	my ($max, $delim) = split /\s*,\s*/, $args;
	HTML::Trim::vtrim($str, $max || 10, $delim || "...");
}


__END__
===
--- input htrim
あああいいい
--- expected
あああい...

===
--- input htrim
aaaaaa
--- expected
aaaa...

===
--- input htrim
あああ<a href="hoge">いい</a>
--- expected
あああ<a href="hoge">いい</a>

===
--- input htrim
あああ<a href="hoge">いいい</a>
--- expected
あああ<a href="hoge">い</a>...

===
--- input htrim
あああ<img name="bar"/>foo
--- expected
あああ<img name="bar"/>f...

===
--- input htrim
あああ<img name="bar">foo
--- expected
あああ<img name="bar">f...

===
--- input htrim
<div>あああ<a href="hoge">いいい</a></div>
--- expected
<div>あああ<a href="hoge">い</a></div>...

===
--- input htrim
<div>あああ<a href="hoge">いいい
--- expected
<div>あああ<a href="hoge">い</a></div>...

===
--- input htrim
&lt;script>alert("あああ")&lt;/script>
--- expected
&lt;...

===
--- input hvtrim
<div>あああ<a href="hoge">いいい
--- expected
<div>あああ<a href="hoge">い</a></div>...

===
--- input hvtrim
<div>aaaaaa<a href="hoge">iiiiii
--- expected
<div>aaaaaa<a href="hoge">iii</a></div>...
===

--- input hvtrim
foo bar <a href="hoge">baz</a> fumino
--- expected
foo bar <a href="hoge">b</a>...

===
--- input hvtrim
&lt;script>alert("aaa")&lt;/script>
--- expected
&lt;scrip...
