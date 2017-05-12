use MIME::Words qw(:all);
use MIME::WordDecoder;
use Encode;
my $s = "Служба поддержки";

use Test::More tests => 2;

is(MIME::Words::encode_mimewords($s, Charset => 'utf-8'), '=?UTF-8?Q?=D0=A1=D0=BB=D1=83=D0=B6=D0=B1=D0=B0=20?= =?UTF-8?Q?=D0=BF=D0=BE=D0=B4=D0=B4=D0=B5=D1=80=D0=B6=D0=BA=D0=B8?=');

is(decode_mimewords('=?UTF-8?Q?=D0=A1=D0=BB=D1=83=D0=B6=D0=B1=D0=B0=20?= =?UTF-8?Q?=D0=BF=D0=BE=D0=B4=D0=B4=D0=B5=D1=80=D0=B6=D0=BA=D0=B8?='), $s);
