use strict;
use warnings;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use lib "$FindBin::Bin/TestApp/lib";
    chdir("$FindBin::Bin/TestApp") || die;
}

use Jifty::Test tests => 9;
use Jifty::Test::WWW::Mechanize;
use Encode;
use Encode::Guess;

my $server = Jifty::Test->make_server;
my $server_url = $server->started_ok;

# create instance
ok(Jifty->app_class('Notification', 'ISO2022JP')->new, 'new()');

# send
my $notification = Jifty->app_class('Notification', 'ISO2022JP')->new(
    from    => '山田 太郎 <taro@null.in>',
    to      => '山田 花子 <hanako@null.in>',
    subject => 'こんにちは',
    body    => 'リボルテック ダンボー アマゾンverは目が光る!!',
);
$notification->send;
is((Jifty::Test->messages), 1, 'one mail arrived');

# check sent message
my ($sent) = Jifty::Test->messages;
is($sent->header('To'), '=?ISO-2022-JP?B?GyRCOzNFRBsoQiAbJEIyVjtSGyhC?= <hanako@null.in>', "To:");
is($sent->header('From'), '=?ISO-2022-JP?B?GyRCOzNFRBsoQiAbJEJCQE86GyhC?= <taro@null.in>', "From:");
is($sent->header('Subject'), '=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTxsoQg==?=', "Subject:");
is($sent->header('Content-Transfer-Encoding'), '7bit', "Content-Transfer-Encoding:");
like($sent->header('Content-Type'), qr{text/plain}i, "Content-Type:");
like($sent->header('Content-Type'), qr{charset=.?ISO-2022-JP.?}i, "Content-Type:");
#ok( guess_encoding($sent->body, 'ISO-2022-JP'), 'body encoded.');

1;
