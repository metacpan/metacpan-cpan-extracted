use strict;
use warnings FATAL => 'all';

use Test::More tests => 37;
use DateTime;
use DateTime::Duration;
use HTML::Tested::Test::Request;
use Data::Dumper;
use Carp;

BEGIN { use_ok('HTML::Tested', 'HTV');
	use_ok('HTML::Tested::Value');
	use_ok('HTML::Tested::Test::Value');
	use_ok('HTML::Tested::Value::DropDown');
	use_ok('HTML::Tested::Test::DateTime');
	use_ok('HTML::Tested::Value::Marked');
	use_ok('HTML::Tested::Test');
}

$SIG{__DIE__} = sub { confess(@_); };
HTML::Tested::Seal->instance('boo boo boo');

package T;
use base 'HTML::Tested';

__PACKAGE__->ht_add_widget(::HTV, d => is_datetime => '%b %d, %Y');

package main;

my $dt = DateTime->new(year => 1964, month => 10, day => 16);
my $obj = T->new({ d => $dt });
my $stash = {};
$obj->ht_render($stash);
is_deeply($stash, { d => 'Oct 16, 1964' });

$obj->d(undef);
$obj->ht_render($stash);
is_deeply($stash, { d => '' });

$obj = T->ht_load_from_params(d => 'Oct 27, 1976');
$obj->ht_render($stash);
is_deeply($stash, { d => 'Oct 27, 1976' }) or exit 1;

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, e => is_datetime => {
		pattern => '%x', locale => 'ru_RU' });

package main;

$obj = T2->ht_load_from_params(e => '27.10.1976');
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { e => '27.10.1976' });

T2->ht_add_widget(::HTV, id => is_sealed => 1);
$obj->id(555555);

my $qs = $obj->ht_make_query_string("hello", "id", "e");
like($qs, qr/^hello\?id/);
unlike($qs, qr/555555/);
like($qs, qr/&e=27\.10\.1976/);

is($obj->ht_make_query_string("hello"), 'hello');

my $qs2 = $obj->ht_make_query_string("hello?a=b", "id", "e");
like($qs2, qr/a=b&id/);
unlike($qs2, qr/\?.*\?/);

my $r = HTML::Tested::Test::Request->new;
$r->parse_url($qs);
isnt($r->param('id'), undef);

$obj = T2->ht_load_from_params(map { $_, $r->param($_) } $r->param);
is($obj->id, 555555);
is($obj->e->year, '1976');

is($r->dir_config("Moo"), undef);
$r->dir_config("Moo", "boo");
is($r->dir_config("Moo"), "boo");
$r->dir_config("Moo", undef);
is($r->dir_config("Moo"), undef);

T2->ht_add_widget(::HTV, 'd');
T2->ht_set_widget_option(id => skip_undef => 1);
T2->ht_find_widget('d')->setup_datetime_option('%x');
is(T2->ht_find_widget('d')->options->{is_datetime}->pattern, '%x');

$obj = T2->new({ d => $dt });
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { d => 'Oct 16, 1964', e => '' });

my $opts = {};
T2->ht_find_widget('d')->setup_datetime_option('%c', $opts);
is(T2->ht_find_widget('d')->options->{is_datetime}->pattern, '%x');
is($opts->{is_datetime}->pattern, '%c');

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV . "::DropDown", dd => 0 => { is_sealed => 1 }
		, 1 => { is_datetime => '%x' });

package main;

my $dt1 = DateTime->new(year => 1980, month => 2, day => 14);
my $dt2 = DateTime->new(year => 1985, month => 7, day => 18);
$obj = T3->new({ dd => [ [ 1, $dt1 ] , [ 2, $dt2, 1 ] ] });

$stash = {};
$obj->ht_render($stash);
like($stash->{dd}, qr/Feb 14/);
unlike($stash->{dd}, qr/"2"/);
is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash,
		{ HT_SEALED_dd => [ [ 1, $dt1 ], [ 2, $dt2, 1 ] ] }) ], [])
	or diag(Dumper($stash));

$dt = HTML::Tested::Test::DateTime->now(10);
my $now = DateTime->now(time_zone => POSIX::strftime('%z', localtime));

package T4;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, d => 'is_datetime' => '%c');

package main;
$obj = T4->new({ d => $now });
$stash = {};
$obj->ht_render($stash);

# check range comparison
is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash
		, { d => $now }) ], []);

my $dur = DateTime::Duration->new(seconds => 5);
$obj->d($obj->d + $dur);
$obj->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash, { d => $dt }) ], []) or die;

package T5;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV . "::Marked", d => 'is_datetime' => '%c');

package main;
$obj = T5->new({ d => ($now + $dur) });
$stash = {};
$obj->ht_render($stash);

is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash
		, { d => HTML::Tested::Test::DateTime->now(10) }) ], []);

my @res = HTML::Tested::Test->check_stash(ref($obj), $stash
		, { d => HTML::Tested::Test::DateTime->now(3) });
is(@res, 1);

my $str = "<html>$stash->{d}</html>";
is_deeply([ HTML::Tested::Test->check_text(ref($obj), $str
		, { d => HTML::Tested::Test::DateTime->now(10) }) ], []);
my (undef, undef, $h) = localtime(time);
like(HTML::Tested::Test::DateTime->now->strftime('%H'), qr/$h/);


$dt = HTML::Tested::Test::DateTime->now(3);
sleep 1;
$now = DateTime->now(time_zone => POSIX::strftime('%z', localtime));
$obj = T5->new({ d => $now });
$stash = {};
$obj->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash, { d => $dt }) ], []);

