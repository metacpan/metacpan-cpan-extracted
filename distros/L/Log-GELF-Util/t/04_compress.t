use strict;
use Test::More 0.91;
use Test::Exception;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use IO::Uncompress::Inflate qw(inflate $InflateError) ;
use JSON::MaybeXS qw(decode_json);

use Log::GELF::Util qw(encode compress uncompress);

throws_ok{
    my %msg = compress();
}
qr/0 parameters were passed.*/,
'mandatory parameter missing';

throws_ok{
    compress({});
}
qr/Parameter #1.*/,
'message parameters wrong type';

throws_ok{
    my %msg = compress(1,'wrong');
}
qr/compression type must be gzip \(default\) or zlib/,
'type parameters wrong';

throws_ok{
    my %msg = uncompress();
}
qr/0 parameters were passed.*/,
'mandatory parameter missing';

throws_ok{
    my %msg = uncompress(
       {},
    );
}
qr/Parameter #1.*/,
'message parameters wrong type';

lives_ok{
    compress( 1, 'gzip');
}
'gzips explicit ok';

lives_ok{
    compress( 1, 'zlib');
}
'zlib explicit ok';

my $msgz;
lives_ok{
    $msgz = compress(
        encode(
            {
                host           => 'host',
                short_message  => 'message',
            }
        )
    );
}
'gzips ok';

my $msgj;
gunzip \$msgz => \$msgj
  or die "gunzip failed: $GunzipError";
my $msg = decode_json($msgj);

is($msg->{version}, '1.1',  'correct default version');
is($msg->{host},    'host', 'correct default version');

lives_ok{
    $msg = decode_json(
        uncompress($msgz)
    );
}
'uncompresses gzip ok';

is($msg->{version}, '1.1',  'correct default version');
is($msg->{host},    'host', 'correct default version');

my $msgz;
lives_ok{
    $msgz = compress(
     encode(
            {
                host           => 'host',
                short_message  => 'message',
            }
        ),
        'zlib',
    );
}
'deflates ok';

my $msgj;
inflate \$msgz => \$msgj
  or die "inflate failed: $InflateError";
my $msg = decode_json($msgj);

is($msg->{version}, '1.1',  'correct default version');
is($msg->{host},    'host', 'correct default version');

lives_ok{
    $msg = decode_json(
        uncompress($msgz)
    );
}
'uncompresses zlib ok';

is($msg->{version}, '1.1',  'correct default version');
is($msg->{host},    'host', 'correct default version');

done_testing(19);

