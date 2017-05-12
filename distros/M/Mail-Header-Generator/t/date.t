package date;
use strict;
use warnings;
use base qw( Test::Class );

use Test::More;

use Mail::Header::Generator ();

local $ENV{TZ}   = 'UTC';
local $ENV{LANG} = 'C';

sub startup : Test(startup)
{
	my ($self) = @_;
	$self->{gen} = Mail::Header::Generator->new({
		# Force specific timestamp for consistency in testing
		timestamp      => 1195000000,
	});
}

sub date_no_args : Test(1)
{
	my ($self) = @_;
	is(
		$self->{gen}->date(),
		'Date: Wed, 14 Nov 2007 00:26:40 +0000',
		'->date() with no args using object timestamp'
	);
}

sub class_date_no_args : Test(1)
{
	my (undef, undef, undef, $mday, $mon, $year, $wday) = localtime(time);
	$year += 1900;
	$wday = (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday];
	$mon  = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[$mon];
	like(
		Mail::Header::Generator->date(),
		qr/Date: $wday, $mday $mon $year \d{2}:\d{2}:\d{2} \+0000/,
		'->date() with no args (class method)'
	);
}

sub date_with_name : Test(2)
{
	my ($self) = @_;
	is(
		$self->{gen}->date({ header_name => 'X-Wacky-Date' }),
		'X-Wacky-Date: Wed, 14 Nov 2007 00:26:40 +0000',
		'->date() with different header name using object timestamp'
	);

	is(
		$self->{gen}->date({ header_name => 'X-Wacky-Date', timestamp => 1195000000 }),
		'X-Wacky-Date: Wed, 14 Nov 2007 00:26:40 +0000',
		'->date() with different header name (class method)'
	);

}

__PACKAGE__->runtests unless caller();
