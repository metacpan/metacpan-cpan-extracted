package message_id;
use strict;
use warnings;
use base qw( Test::Class );

use Test::More;
use POSIX ();

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

sub no_args : Test(1)
{
	my ($self) = @_;

	like(
		$self->{gen}->message_id({}),
		qr/Message-ID: <200711140026\.\d{6}\@localhost>/,
		'->message_id() with no args'
	);
}

sub now_timestamp : Test(2)
{
	my ($self) = @_;

	my $now = time();
	my $timestamp = POSIX::strftime("%Y%m%d%H%M", localtime($now));

	is(
		$self->{gen}->message_id({
			header_name => undef,
			timestamp => $now,
			hostname  => 'foo.example.com',
			queue_id  => 'blurble'
		}),
		"<$timestamp.blurble\@foo.example.com>",
		'->message_id() with timestamp, hostname and queue_id'
	);

	$timestamp =~ s/\d{2}\d{2}$/\\d{2}\\d{2}/;
	like(
		Mail::Header::Generator->message_id({
			header_name => undef,
			hostname  => 'foo.example.com',
			queue_id  => 'blurble'
		}),
		qr/<$timestamp\.blurble\@foo\.example\.com>/,
		'->message_id() as class method with hostname and queue_id'
	);
}

__PACKAGE__->runtests unless caller();
