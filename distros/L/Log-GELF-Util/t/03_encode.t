use strict;
use Test::More 0.98;
use Test::Exception;
use JSON::MaybeXS qw(decode_json);

use Log::GELF::Util qw(encode decode);

throws_ok{
    my %msg = encode();
}
qr/0 parameters were passed.*/,
'mandatory encode parameter missing';

throws_ok{
    my %msg = encode({});
}
qr/Mandatory parameter 'short_message' missing.*/,
'mandatory encode parameters missing';

my $msg;
lives_ok{
    $msg = decode_json(encode(
        {
            host           => 'host',
            short_message  => 'message',
        }
    ));
}
'encodes ok';

is($msg->{version}, '1.1',  'correct default version');
is($msg->{host},    'host', 'correct default version');

throws_ok{
    my %msg = decode();
}
qr/0 parameters were passed.*/,
'mandatory decode parameter missing';

throws_ok{
    my %msg = decode("{}");
}
qr/Mandatory parameter 'short_message' missing.*/,
'mandatory encode parameters missing';

lives_ok{
    $msg = decode(encode(
        {
            host           => 'host',
            short_message  => 'message',
        }
    ));
}
'encodes ok';

is($msg->{version}, '1.1',  'correct default version');
is($msg->{host},    'host', 'correct default version');

done_testing(10);

