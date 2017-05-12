use HTML::HTML5::Builder;
use Test::More;

plan skip_all => 'Tests need DateTime'
	unless eval 'use DateTime; 1;';
plan tests => 3;

my $b  = HTML::HTML5::Builder->new;
my $dt = DateTime->now(time_zone=>'floating');

is(
	$b->time($dt)->toString,
	qq{<time xmlns="http://www.w3.org/1999/xhtml" datetime="$dt">$dt</time>},
	'time() with single DateTime argument'
	);

is(
	$b->time($dt, 'now')->toString,
	qq{<time xmlns="http://www.w3.org/1999/xhtml" datetime="$dt">now</time>},
	'time() with DateTime argument and label'
	);

is(
	$b->time($dt, $b->span('now'))->toString,
	qq{<time xmlns="http://www.w3.org/1999/xhtml" datetime="$dt"><span>now</span></time>},
	'time() with DateTime argument and nested HTML'
	);