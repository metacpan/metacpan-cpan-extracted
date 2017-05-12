package received;
use strict;
use warnings;
use base qw( Test::Class );

use Test::More;

use Mail::Header::Generator ();

local $ENV{TZ} = 'UTC';

sub startup : Test(startup)
{
	my ($self) = @_;
	$self->{gen} = Mail::Header::Generator->new({
		# Force specific timestamp for consistency in testing
		timestamp      => 1195000000,
	});
}

sub blank_received_header : Test(1)
{
	my ($self) = @_;

	is(
		$self->{gen}->received({}),
		"Received: (from $ENV{USER}\@localhost); Wed, 14 Nov 2007 00:26:40 +0000",
		'->received() with no args'
	);
}

sub class_blank_received_header : Test(1)
{
	my (undef, undef, undef, $mday, $mon, $year, $wday) = localtime(time);
	$year += 1900;
	$wday = (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday];
	$mon  = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[$mon];
	like(
		Mail::Header::Generator->received({}),
		qr/Received: \(from $ENV{USER}\@localhost\); $wday, $mday $mon $year \d{2}:\d{2}:\d{2} \+0000/,
		'->received() with no args (class method)'
	);
}

sub no_env_user : Test(1)
{
	my (undef, undef, undef, $mday, $mon, $year, $wday) = localtime(time);
	$year += 1900;
	$wday = (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday];
	$mon  = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[$mon];

	local $ENV{USER};
	like(
		Mail::Header::Generator->received({}),
		qr/Received: \(from unknown\@localhost\); $wday, $mday $mon $year \d{2}:\d{2}:\d{2} \+0000/,
		'->received() with no args (class method)'
	);
}

sub with_values : Test(1)
{
	my ($self) = @_;

	my $r_hdr = qr/^from loser \Q(broken.dynamic.server.example.com [999.888.777.666])
	by mail.roaringpenguin.com (envelope-sender <dmo\E\@example.net>\Q)\E with ESMTP id lAE0Qe..\d{6}\n\tfor <dmo\@example\.com>; Wed, 14 Nov 2007 00:26:40 \+0000$/;

	my $generated = $self->{gen}->received({
		header_name => undef,
		helo =>'loser',
		protocol => 'ESMTP',
		queue_id => 'lAE0Qear032519',
		relay_address => '999.888.777.666',
		relay_hostname => 'broken.dynamic.server.example.com',
		hostname => 'mail.roaringpenguin.com',
		sender         => 'dmo@example.net',
		recipients     => [
			'dmo@example.com',
		],
	});
	like(
		$generated,
		$r_hdr,
		'->received() with some args set'
	);
}

__PACKAGE__->runtests unless caller();
