#!/usr/bin/env perl
use strict;
use warnings;
use lib ('lib', 't/lib');
use Horris::Message;
use Horris::Instance;
use Horris::Connection::Plugin::Twitter;
use Test::MockObject::Extends;
use Test::More (tests => 3);

my @sample_tweets = (
    'http://twitter.com/#!/umma_coding_bot/status/8721128864350209', 
    'https://twitter.com/#!/umma_coding_bot/status/8721128864350209', 
    'http://twitter.com/#!/umma_coding_bot/statuses/8721128864350209', 
    'http://twitter.com/umma_coding_bot/status/8721128864350209', 
    'https://twitter.com/umma_coding_bot/statuses/8721128864350209', 
    'something!http://twitter.com/#!/umma_coding_bot/status/8721128864350209'
);

my $mobile_tweet_url = 'http://mobile.twitter.com/alexbonkoo/status/9181735065493504';

my $plugin_name = 'Twitter';
my $horris = Horris::Instance->new([$plugin_name]);
my $plugin = Horris::Connection::Plugin::Twitter->new({
    parent => $horris->{conn}, 
    name => $plugin_name, 
    $plugin_name => {} # other configuration here
});

my $conn = Test::MockObject::Extends->new('Horris::Connection');
$plugin->_connection($conn);

my @result;
my $event = 'irc_privmsg';

$conn->mock($event, sub {
    my ($self, $args) = @_;
    push @result, $args->{message} if defined $args->{message};
});

foreach my $url (@sample_tweets) {
	my $message = Horris::Message->new(
		channel => '#test', # not used, but required for L<Horris::Connection>
		message => $url, 
		from	=> 'test',  # not used, but required for L<Horris::Connection>
	);

    $plugin->$event($message);
}

is(scalar @result, scalar @sample_tweets, 'trying count');
my %hash;
for my $result (@result) {
	$hash{$result}++;
}
is(scalar keys %hash, 1, 'all equal');
diag($result[0]) if @result;

$conn->mock($event, sub {
    my ($self, $args) = @_;
    diag($args->{message}) if $args->{message};
    like($args->{message}, qr/perl/, 'mobile tweet');
});

my $message = Horris::Message->new(
    channel => '#test',
    message => $mobile_tweet_url, 
    from	=> 'test',
);

$plugin->irc_privmsg($message);
