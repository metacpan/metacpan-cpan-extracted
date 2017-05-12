use strict;
use warnings;
use Test::More;
use JSON;
use Digest::MD5 qw(md5_hex);

BEGIN {
  plan skip_all => '$ENV{MAILCHIMP_APIKEY} not set, skipping live tests' unless defined $ENV{MAILCHIMP_APIKEY}; 

  plan tests => 3;
  use_ok('Mail::Chimp3');
}

my $apikey = $ENV{MAILCHIMP_APIKEY};
my $mailchimp = Mail::Chimp3->new( api_key => $apikey );

my $lists = $mailchimp->lists;
my $list_id = $lists->{content}{lists}[0]->{id};

my %info1 = qw(email_address foo@foobar.com status subscribed);
my %info2 = qw(email_address baz@quux.com status subscribed);
my $batch = [
    {
        method => 'POST',
        path   => "lists/$list_id/members",
        body   => encode_json(\%info1),
    },
    {
        method => 'POST',
        path   => "lists/$list_id/members",
        body   => encode_json(\%info2),
    },
];

#my $listBatchSubscribe_expected = { add_count => 2, error_count => 0, errors => [], update_count => 0 };
my $listBatchSubscribe = $mailchimp->add_batch( operations => $batch );

is(
    $listBatchSubscribe->{code},
    200,
    'listBatchSubscribe succeeded'
);

#my $listBatchUnsubscribe_expected = { success_count => 2, error_count => 0, errors => [] };
my $hash1 = md5_hex('foo@foobar.com');
my $hash2 = md5_hex('baz@quux.com');
my $listBatchUnsubscribe = $mailchimp->add_batch( operations => [
    {
        method => 'DELETE',
        path   => "lists/$list_id/members/$hash1",
    },
    {
        method => 'DELETE',
        path   => "lists/$list_id/members/$hash2",
    },
] );

is(
    $listBatchUnsubscribe->{code},
    200,
    'listBatchUnsubscribe succeeded'
);
