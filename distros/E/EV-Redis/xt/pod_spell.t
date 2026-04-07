use Test::More;
eval q{ use Test::Spelling };

plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(<DATA>);
set_spell_cmd("aspell -l en list");

all_pod_files_spelling_ok();

__DATA__
vividsnow
Daisuke
Murase
typester
KAYAC
anyevent
EV
hostname
redis
hiredis
str
utf-8
backend
reconnection
libev
TLS
tls
SSL
ssl
SNI
keepalive
keepalives
IPv4
IPv6
NAT
capath
OpenSSL
TCP
RESP3
CLOEXEC
cloexec
reuseaddr
exec
multi
homed
unacknowledged
psubscribe
ssubscribe
