# -*- perl -*-

# t/02_basic.t - generate basic email

use Test::Most tests => 16 + 1;
use Test::NoWarnings;

use Mail::Builder;

my $mailbuilder = Mail::Builder->new();

isa_ok($mailbuilder,'Mail::Builder');

# Test address accessors
ok($mailbuilder->from('from@test.com'),'Set from');
isa_ok($mailbuilder->from,'Mail::Builder::Address');
is($mailbuilder->from->email,'from@test.com','Has correct email address');
$mailbuilder->from->name('tester');

# Test basic accessor
ok(!$mailbuilder->has_organization,'Has no organization');
ok($mailbuilder->organization('organization'),'Set organization');
ok($mailbuilder->has_organization,'Has organization');
is($mailbuilder->organization,'organization','Has correct organization');

# Test recipient address
$mailbuilder->to(Mail::Builder::Address->new(email => 'to@test.com'));
isa_ok($mailbuilder->to,'Mail::Builder::List');

# Add required fields
$mailbuilder->plaintext('testcontent');
$mailbuilder->subject('test');

# Build address
my $mime = $mailbuilder->build_message();
isa_ok($mime,'MIME::Entity');

isa_ok($mime->head,'MIME::Head');
like($mime->head->get('Date'),qr/^(Sun|Mon|Tue|Wed|Thu|Fri|Sat),\s\d/,'Date ok');
is($mime->head->get('To'),'to@test.com'."\n",'Recipient in MIME object ok');
is($mime->head->get('From'),'"tester" <from@test.com>'."\n",'From in MIME object ok');
is($mime->head->get('X-Priority'),'3'."\n",'Priority in MIME object ok');
is($mime->head->get('Subject'),'test'."\n",'Subject in MIME object ok');

