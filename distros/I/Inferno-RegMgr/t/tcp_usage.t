# TODO иногда приходит "лишний" event/IN с текстом 000001 (обычно первый
# приходящий это 000002)
# http://code.google.com/p/inferno-os/issues/detail?id=179
use t::share;

use Inferno::RegMgr::TCP;


plan tests => 19;

throws_ok { Inferno::RegMgr::TCP->new()              } qr/{host} required/;
throws_ok { Inferno::RegMgr::TCP->new({})            } qr/{host} required/;
throws_ok { Inferno::RegMgr::TCP->new({host=>undef}) } qr/{host} required/;
lives_ok  { Inferno::RegMgr::TCP->new({host=>q{}})   } 'new() accept empty {host}';
lives_ok  { Inferno::RegMgr::TCP->new({
            host        => '127.0.0.172',
            port_new    => 1,
            port_find   => 2,
            port_event  => 3,
            }) } 'new() with all params';

my $reg = Inferno::RegMgr::TCP->new({host=>'127.0.0.172'});

throws_ok { $reg->open_event()              } qr/{cb} required/;
throws_ok { $reg->open_event({})            } qr/{cb} required/;
throws_ok { $reg->open_event({cb=>undef})   } qr/{cb} required/;
lives_ok  { $reg->open_event({cb=>q{}})     } 'open_event() accept empty {cb}';

throws_ok { $reg->open_new()                } qr/{name} required/;
throws_ok { $reg->open_new({})              } qr/{name} required/;
throws_ok { $reg->open_new({name=>undef})   } qr/{name} required/;
throws_ok { $reg->open_new({name=>q{}})     } qr/{cb} required/;
throws_ok { $reg->open_new({name=>q{},cb=>undef}) } qr/{cb} required/;
lives_ok  { $reg->open_new({name=>q{},cb=>q{}}) } 'open_new() accept empty {name} and {cb}';

throws_ok { $reg->open_find()               } qr/{cb} required/;
throws_ok { $reg->open_find({})             } qr/{cb} required/;
throws_ok { $reg->open_find({cb=>undef})    } qr/{cb} required/;
lives_ok  { $reg->open_find({cb=>q{}})      } 'open_find() accept empty {cb}';

