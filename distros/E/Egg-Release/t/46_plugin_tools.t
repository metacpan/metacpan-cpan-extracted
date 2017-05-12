use Test::More tests=> 77;
use lib qw( ./lib ../lib );
use Egg::Helper;

$ENV{EGG_RC_NAME}= 'egg_releaserc';

ok my $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ Tools /] } ), q{ load plugin. };

my $curdir= $e->helper_current_dir;

can_ok $e, 'encode_entities';
  can_ok $e, 'encode_entities_numeric';
  can_ok $e, 'escape_html';
  can_ok $e, 'eHTML';
  is $e->escape_html('<test>'), '&lt;test&gt;',
     q{$e->escape_html('<test>'), '&lt;test&gt;'};

can_ok $e, 'decode_entities';
  can_ok $e, 'unescape_html';
  can_ok $e, 'ueHTML';
  is $e->unescape_html('&lt;test&gt;'), '<test>',
     q{$e->unescape_html('&lt;test&gt;'), '<test>'};

can_ok $e, 'uri_escape';
  can_ok $e, 'escape_uri';
  can_ok $e, 'eURI';
  is $e->escape_uri(':test:'), '%3Atest%3A',
     q{$e->escape_uri(':test:'), '%3Atest%3A'};

can_ok $e, 'uri_unescape';
  can_ok $e, 'unescape_uri';
  can_ok $e, 'ueURI';
  is $e->unescape_uri('%3Atest%3A'), ':test:',
     q{$e->unescape_uri('%3Atest%3A'), ':test:'};

can_ok $e, 'md5_hex';
  ok my $hex= $e->md5_hex('abc123'), q{my $hex= $e->md5_hex('abc123')};
  like $hex, qr{^[0-9a-f]{32}$}, q{$hex, qr{^[0-9a-f]{32}$}};
  is $hex, $e->md5_hex('abc123'), q{$hex, $e->md5_hex('abc123')};

can_ok $e, 'sha1_hex';
  ok $hex= $e->sha1_hex('abc123'), q{my $hex= $e->sha1_hex('abc123')};
  like $hex, qr{^[0-9a-f]{40}$}, q{$hex, qr{^[0-9a-f]{40}$}};
  is $hex, $e->sha1_hex('abc123'), q{$hex, $e->sha1_hex('abc123')};

can_ok $e, 'comma';
  ok my $num= $e->comma(1234567), q{my $num= $e->comma(1234567)};
  like $num, qr{^1\,234\,567$}, q{$num, qr{^1\,234\,567$}};
  ok $num= $e->comma(-1234567.123), q{$num= $e->comma(-1234567.123)};
  like $num, qr{^\-1\,234\,567\.123$}, q{$num, qr{^\-1\,234\,567\.123$}};
  ok $num= $e->comma(+1234567.123), q{$num= $e->comma(+1234567.123)};
  like $num, qr{^1\,234\,567\.123$}, q{$num, qr{^1\,234\,567\.123$}};
  ok $num= $e->comma('+1234567.123'), q{$num= $e->comma('+1234567.123')};
  like $num, qr{^\+1\,234\,567\.123$}, q{$num, qr{^\+1\,234\,567\.123$}};
  is $e->comma('ABC1234567'), 0, q{$e->comma('ABC1234567'), 0};

can_ok $e, 'shuffle_array';
  my @test= ('a'..'z');
  my $code= sub {
  	my($a1, $a2)= @_;
  	for (0..$#test) { $a1->[$_] eq $a2->[$_] || return 1 }
  	return 0;
    };
  ok my $array= $e->shuffle_array(@test), q{my $array= $e->shuffle_array(@test)};
  isa_ok $array, 'ARRAY';
  ok $code->(\@test, $array), q{$code->(\@test, $array)};

can_ok $e, 'filefind';
  my @files= $e->helper_yaml_load(join '', <DATA>);
  $e->helper_create_files([@files[0..2]]);
  ok my $f= $e->filefind(qr{\.txt$}, "$curdir/etc"), q{my $f= $e->filefind( ... };
  is scalar(@$f), 3, q{scalar(@$f), 3};
  $e->helper_create_files(\@files);
  ok $f= $e->filefind(qr{\.txt$}, "$curdir/etc"), q{$f= $e->filefind( ... };
  is scalar(@$f), 6, q{scalar(@$f), 6};

can_ok $e, 'referer_check';
  $ENV{REQUEST_METHOD}= 'GET';
  ok $e->referer_check, q{$e->referer_check};
  ok ! $e->referer_check(1), q{! $e->referer_check(1)};
  $ENV{REQUEST_METHOD}= 'POST';
  ok $e->referer_check(1), q{$e->referer_check(1)};
  $ENV{HTTP_REFERER}= 'http://a.com/page.html';
  ok ! $e->referer_check(1), q{! $e->referer_check(1)};
  $e->global->{referer_check_regexp}= "";
  $e->req->{host_name}= 'a.com';
  ok $e->referer_check(1), q{$e->referer_check(1)};

can_ok $e, 'gettimeofday';
  ok my @num= $e->gettimeofday, q{my @num= $e->gettimeofday};
  like $num[0], qr{^\d+$}, q{$num[0], qr{^\d+$}};
  ok $num[0] >= 10, q{$num[0] >= 10};
  like $num[1], qr{^\d+$}, q{$num[1], qr{^\d+$}};
  ok $num[1] >=  5, q{$num[1] >=  5};

can_ok $e, 'mkpath';
  ok $e->mkpath("$curdir/egg_test/test"), q{$e->mkpath("$curdir/egg_test/test")};
  ok -e "$curdir/egg_test", q{-e "$curdir/egg_test"};
  ok -e "$curdir/egg_test/test", q{-e "$curdir/egg_test/test"};

can_ok $e, 'rmtree';
  ok $e->rmtree("$curdir/egg_test"), q{$e->rmtree("$curdir/egg_test")};
  ok ! -e "$curdir/egg_test/test", q{! -e "$curdir/egg_test/test"};
  ok ! -e "$curdir/egg_test", q{! -e "$curdir/egg_test"};

eval{ require Jcode };
if ($@) {
	pass q{can_ok jfold};
	pass q{ok my $str= $e->jfold};
	pass q{is scalar( ...};
	pass q{is $str->[0]};
	pass q{is $str->[1]};
} else {
	can_ok $e, 'jfold';
	ok my $str= $e->jfold('123456',3), q{my $str= $e->jfold('123456',3)};
	is scalar(@$str), 2, q{scalar(@$str), 2};
	is $str->[0], '123', q{$str->[0], '123'};
	is $str->[1], '456', q{$str->[1], '456'};
}

can_ok $e, 'timelocal';
  $num= time;
  my @T= localtime($num);
  ok $str= $e->timelocal(reverse(@T[0..5])), q{$str= $e->timelocal( ...};
  is $num, $str, q{$num, $str};
  $T[5]+= 1900; ++$T[4];
  ok $str= $e->timelocal(reverse(@T[0..5])), q{$str= $e->timelocal( ...};
  is $num, $str, q{$num, $str};
  $str= sprintf "%04d/%02d/%02d %02d:%02d:%02d", reverse(@T[0..5]);
  ok $str= $e->timelocal($str), q{$str= $e->timelocal($str)};
  is $num, $str, q{$num, $str};


__DATA__
---
filename: etc/1.txt
value: |
  test1
---
filename: etc/2.txt
value: |
  test1
---
filename: etc/3.txt
value: |
  test1
---
filename: etc/1/1.txt
value: |
  test1
---
filename: etc/2/2.txt
value: |
  test1
---
filename: etc/3/3.txt
value: |
  test1
