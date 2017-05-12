#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {

	use Facebook::Signed;

	my $fb_cookie = Facebook::Signed->new(
		cookie_param => 'access_token=148266808552034|2._RM0U0UYxeFVfVOJRioaxQ__.3600.1287687600-100001153174797|s4kBFzVXiOYs2kp6PptgrbtOxIU&base_domain=raudssus.de&expires=1287687600&secret=TEvqx4MBFvlQD8NrRkgOtw__&session_key=2._RM0U0UYxeFVfVOJRioaxQ__.3600.1287687600-100001153174797&sig=ab1009a312eb07d7812d47a9a3e3b31c&uid=100001153174797',
		secret => '7adde7e516bf42ec914b08c8d075c13d',
	);
	
	isa_ok($fb_cookie, 'Facebook::Signed');

	is($fb_cookie->uid, '100001153174797', 'Facebook::Signed gave proper uid for cookie');
	is($fb_cookie->session_key, '2._RM0U0UYxeFVfVOJRioaxQ__.3600.1287687600-100001153174797', 'Facebook::Signed gave proper session_key for cookie');
	is($fb_cookie->access_token, '148266808552034|2._RM0U0UYxeFVfVOJRioaxQ__.3600.1287687600-100001153174797|s4kBFzVXiOYs2kp6PptgrbtOxIU', 'Facebook::Signed gave proper access_token for cookie');

	my $fb_canvas = Facebook::Signed->new(
		canvas_param => 'yS85w5rVKvjZv-RT-iyhc73SHipFGrTGEvwpdblMEOs.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImV4cGlyZXMiOjEyOTczODYwMDAsImlzc3VlZF9hdCI6MTI5NzM3OTM3MCwib2F1dGhfdG9rZW4iOiIxNTA5NDUxNTQ5NjI2ODd8Mi4ycVhnOXl4VUpySG9Xd2dmTmJmeDVnX18uMzYwMC4xMjk3Mzg2MDAwLTY1MDI4NzY3MHx5TWhnenNKVjVUeW5scU5EYjZCREhTZVlEeVUiLCJ1c2VyIjp7ImNvdW50cnkiOiJ1cyIsImxvY2FsZSI6ImVuX1VTIiwiYWdlIjp7Im1pbiI6MjF9fSwidXNlcl9pZCI6IjEwMDAwMTE1MzE3NDc5NyJ9',
		secret => '7adde7e516bf42ec914b08c8d075c13d',
	);
	is($fb_canvas->uid, '100001153174797', 'Facebook::Signed gave proper uid for canvas');
	is($fb_canvas->get('oauth_token'), '150945154962687|2.2qXg9yxUJrHoWwgfNbfx5g__.3600.1297386000-650287670|yMhgzsJV5TynlqNDb6BDHSeYDyU', 'Facebook::Signed gave proper oauth_token for canvas');

	my $fb = Facebook::Signed->new(
		secret => '7adde7e516bf42ec914b08c8d075c13d',
	);
	isa_ok($fb, 'Facebook::Signed');
}

done_testing;
