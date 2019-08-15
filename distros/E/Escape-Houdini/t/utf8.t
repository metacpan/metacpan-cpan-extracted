use strict;
use warnings;
use utf8;

use Test::More tests => 9;
use Escape::Houdini qw/ :all /;
use Encode;

{
	my $src = '<div class="❤">foo</div>';
	my $was_flag = Encode::is_utf8( $src );

	my $dst = escape_html $src; 
	my $is_flag = Encode::is_utf8( $dst );

	ok $was_flag == $is_flag, "Utf8 flag is preserved after html escaping";
}

{
	my $src = '&lt;div class=&quot;❤&quot;&gt;foo&lt;&#47;div&gt;';
	my $was_flag = Encode::is_utf8( $src );

	my $dst = unescape_html $src; 
	my $is_flag = Encode::is_utf8( $dst );

	ok $was_flag == $is_flag, "Utf8 flag is preserved after html unescaping";
}

{
	my $src = "http://☃.net";
	my $was_flag = Encode::is_utf8( $src );

	for my $sub (qw( escape_url escape_uri escape_href )) {
		no strict 'refs';
		my $dst = "$sub"->($src);
		my $is_flag = Encode::is_utf8( $dst );
		ok $was_flag == $is_flag, "Utf8 flag is preserved after $sub";
	}
}

{
	my $src = 'http%3A%2F%2F☃.net';
	my $was_flag = Encode::is_utf8( $src );

	for my $sub (qw( unescape_url unescape_uri )) {
		no strict 'refs';
		my $dst = "$sub"->($src);
		my $is_flag = Encode::is_utf8( $dst );
		ok $was_flag == $is_flag, "Utf8 flag is preserved after $sub";
	}
}

{
	my $src = "foo['❤']\nbar";
	my $was_flag = Encode::is_utf8( $src );

	for my $sub (qw( escape_js )) {
		no strict 'refs';
		my $dst = "$sub"->($src);
		my $is_flag = Encode::is_utf8( $dst );
		ok $was_flag == $is_flag, "Utf8 flag is preserved after $sub";
	}
}

{
	my $src = q|foo['❤']\nbar|;
	my $was_flag = Encode::is_utf8( $src );

	for my $sub (qw( unescape_js )) {
		no strict 'refs';
		my $dst = "$sub"->($src);
		my $is_flag = Encode::is_utf8( $dst );
		ok $was_flag == $is_flag, "Utf8 flag is preserved after $sub";
	}
}
