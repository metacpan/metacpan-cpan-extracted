use Test::More;

BEGIN { use_ok('Mail::Chimp3'); };

my $apikey = $ENV{MAILCHIMP_APIKEY} || 'bogus-us1';

my $mailchimp = Mail::Chimp3->new( api_key => $apikey );
isa_ok($mailchimp, 'Mail::Chimp3');
is($mailchimp->base_url, 'https://' . $mailchimp->datacenter . '.api.mailchimp.com/3.0', 'base_url as expected');

done_testing;
