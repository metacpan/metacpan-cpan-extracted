use strict;
use warnings;
use Test::More;

# Author test: POD spelling. Needs Test::Spelling and a spell checker (aspell/
# hunspell/ispell). Run with `prove -l xt/`.
eval "use Test::Spelling 0.12; 1"
    or plan skip_all => "Test::Spelling required for spelling tests";

add_stopwords(<DATA>);
all_pod_files_spelling_ok('lib');

__DATA__
EV
libev
libwebsockets
WebSocket
WebSockets
websocket
wss
ws
TLS
SSL
OpenSSL
picotls
mTLS
CA
Feersum
PSGI
psgix
endjinn
vhost
vhosts
subprotocol
hashref
filehandle
fd
backpressure
keepalive
reassembled
unsent
mid
runtime
lifecycle
RFC
UTF
IPv
IPv4
IPv6
dotted
quad
gid
uid
Sec
init
ssl
refcount
vividsnow
Renew
plaintext
unicode
roundtrip
lws
wsi
Conns
conns
DESTROYed
FEERSUM
TCP
auth
