#+##############################################################################
#                                                                              #
# File: Messaging/Message/Generator.pm                                         #
#                                                                              #
# Description: versatile message generator                                     #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Messaging::Message::Generator;
use strict;
use warnings;
use 5.005; # need the four-argument form of substr()
our $VERSION  = "1.7";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use Digest::MD5 qw();
use Encode qw(decode FB_CROAK);
use Messaging::Message qw();
use MIME::Base64 qw(decode_base64 encode_base64);
use No::Worries::Die qw(dief);
use Params::Validate qw(validate :types);

#
# global variables
#

our(
    $_MD5,                       # the MD5 digester object
    $_UnicodeString,             # string with Unicode characters
);

#
# initialize what is needed for this module to work
#

sub _init () {
    $_MD5 = Digest::MD5->new();
    $_MD5->add($$ . "-" . time());
    # http://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-demo.txt
    $_UnicodeString = decode_base64(<<'EOT');
ClVURi04IGVuY29kZWQgc2FtcGxlIHBsYWluLXRleHQgZmlsZQrigL7igL7igL7igL7igL7igL7i
gL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL7i
gL7igL7igL7igL7igL7igL7igL7igL7igL7igL7igL4KCk1hcmt1cyBLdWhuIFvLiG1hyrNryopz
IGt1y5BuXSA8aHR0cDovL3d3dy5jbC5jYW0uYWMudWsvfm1nazI1Lz4g4oCUIDIwMDItMDctMjUK
CgpUaGUgQVNDSUkgY29tcGF0aWJsZSBVVEYtOCBlbmNvZGluZyB1c2VkIGluIHRoaXMgcGxhaW4t
dGV4dCBmaWxlCmlzIGRlZmluZWQgaW4gVW5pY29kZSwgSVNPIDEwNjQ2LTEsIGFuZCBSRkMgMjI3
OS4KCgpVc2luZyBVbmljb2RlL1VURi04LCB5b3UgY2FuIHdyaXRlIGluIGVtYWlscyBhbmQgc291
cmNlIGNvZGUgdGhpbmdzIHN1Y2ggYXMKCk1hdGhlbWF0aWNzIGFuZCBzY2llbmNlczoKCiAg4oiu
IEXii4VkYSA9IFEsICBuIOKGkiDiiJ4sIOKIkSBmKGkpID0g4oiPIGcoaSksICAgICAg4o6n4o6h
4o6b4pSM4pSA4pSA4pSA4pSA4pSA4pSQ4o6e4o6k4o6rCiAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAg4o6q4o6i4o6c4pSCYcKyK2LCsyDijp/ijqXijqoKICDiiIB4
4oiI4oSdOiDijIh44oyJID0g4oiS4oyK4oiSeOKMiywgzrEg4oinIMKszrIgPSDCrCjCrM6xIOKI
qCDOsiksICAgIOKOquKOouKOnOKUguKUgOKUgOKUgOKUgOKUgCDijp/ijqXijqoKICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDijqrijqLijpzijrcgY+KCiCAgIOKO
n+KOpeKOqgogIOKElSDiioYg4oSV4oKAIOKKgiDihKQg4oqCIOKEmiDiioIg4oSdIOKKgiDihIIs
ICAgICAgICAgICAgICAgICAgIOKOqOKOouKOnCAgICAgICDijp/ijqXijqwKICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDijqrijqLijpwg4oieICAgICDijp/ijqXi
jqoKICDiiqUgPCBhIOKJoCBiIOKJoSBjIOKJpCBkIOKJqiDiiqQg4oeSICjin6ZB4p+nIOKHlCDi
n6pC4p+rKSwgICAgICDijqrijqLijpwg4o6yICAgICDijp/ijqXijqoKICAgICAgICAgICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICDijqrijqLijpwg4o6zYeKBsS1i4oGx4o6f4o6l
4o6qCiAgMkjigoIgKyBP4oKCIOKHjCAySOKCgk8sIFIgPSA0Ljcga86pLCDijIAgMjAwIG1tICAg
ICDijqnijqPijp1pPTEgICAg4o6g4o6m4o6tCgpMaW5ndWlzdGljcyBhbmQgZGljdGlvbmFyaWVz
OgoKICDDsGkgxLFudMmZy4huw6bKg8mZbsmZbCBmyZnLiG7Jm3TEsWsgyZlzb8qKc2nLiGXEscqD
bgogIFkgW8uIyo9wc2lsyZRuXSwgWWVuIFtqyZtuXSwgWW9nYSBby4hqb8uQZ8mRXQoKQVBMOgoK
ICAoKFbijbNWKT3ijbPijbRWKS9W4oaQLFYgICAg4oy34oaQ4o2z4oaS4o204oiG4oiH4oqD4oC+
4o2O4o2V4oyICgpOaWNlciB0eXBvZ3JhcGh5IGluIHBsYWluIHRleHQgZmlsZXM6CgogIOKVlOKV
kOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKV
kOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKVkOKV
kOKVkOKVkOKVkOKVlwogIOKVkSAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgIOKVkQogIOKVkSAgIOKAoiDigJhzaW5nbGXigJkgYW5kIOKAnGRvdWJsZeKAnSBxdW90ZXMg
ICAgICAgICDilZEKICDilZEgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICDilZEKICDilZEgICDigKIgQ3VybHkgYXBvc3Ryb3BoZXM6IOKAnFdl4oCZdmUgYmVlbiBoZXJl
4oCdIOKVkQogIOKVkSAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIOKV
kQogIOKVkSAgIOKAoiBMYXRpbi0xIGFwb3N0cm9waGUgYW5kIGFjY2VudHM6ICfCtGAgIOKVkQog
IOKVkSAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIOKVkQogIOKVkSAg
IOKAoiDigJpkZXV0c2NoZeKAmCDigJ5BbmbDvGhydW5nc3plaWNoZW7igJwgICAgICAg4pWRCiAg
4pWRICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg4pWRCiAg4pWRICAg
4oCiIOKAoCwg4oChLCDigLAsIOKAoiwgM+KAkzQsIOKAlCwg4oiSNS8rNSwg4oSiLCDigKYgICAg
ICDilZEKICDilZEgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDilZEK
ICDilZEgICDigKIgQVNDSUkgc2FmZXR5IHRlc3Q6IDFsSXwsIDBPRCwgOEIgICAgIOKVkQogIOKV
kSAgICAgICAgICAgICAgICAgICAgICDila3ilIDilIDilIDilIDilIDilIDilIDilIDilIDila4g
ICAgICAgICDilZEKICDilZEgICDigKIgdGhlIGV1cm8gc3ltYm9sOiDilIIgMTQuOTUg4oKsIOKU
giAgICAgICAgIOKVkQogIOKVkSAgICAgICAgICAgICAgICAgICAgICDilbDilIDilIDilIDilIDi
lIDilIDilIDilIDilIDila8gICAgICAgICDilZEKICDilZrilZDilZDilZDilZDilZDilZDilZDi
lZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDi
lZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZDilZ0KCkNvbWJp
bmluZyBjaGFyYWN0ZXJzOgoKICBTVEFSR86bzIpURSBTRy0xLCBhID0gdsyHID0gcsyILCBh4oOR
IOKKpSBi4oORCgpHcmVlayAoaW4gUG9seXRvbmljKToKCiAgVGhlIEdyZWVrIGFudGhlbToKCiAg
zqPhvbIgzrPOvc+Jz4HhvbfOts+JIOG8gM+A4b24IM+E4b20zr0gzrrhvbnPiM63CiAgz4TOv+G/
piDPg8+AzrHOuM65zr/hv6Ygz4ThvbTOvSDPhM+Bzr/OvM61z4HhvbUsCiAgz4PhvbIgzrPOvc+J
z4HhvbfOts+JIOG8gM+A4b24IM+E4b20zr0g4b2Ez4jOtwogIM+Azr/hvbogzrzhvbIgzrLhvbfO
sSDOvM61z4TPgeG9sc61zrkgz4ThvbQgzrPhv4YuCgogIOG+v86Rz4Dhvr8gz4ThvbAgzrrhvbnO
us66zrHOu86xIM6yzrPOsc67zrzhvbPOvc63CiAgz4Thv7bOvSDhv77Olc67zrvhvbXOvc+Jzr0g
z4ThvbAg4byxzrXPgeG9sQogIM66zrHhvbYgz4PhvbDOvSDPgM+B4b+2z4TOsSDhvIDOvc60z4HO
tc65z4nOvOG9s869zrcKICDPh86x4b+Wz4HOtSwg4b2mIM+HzrHhv5bPgc61LCDhvr/Olc67zrXP
hc64zrXPgc654b2xIQoKICBGcm9tIGEgc3BlZWNoIG9mIERlbW9zdGhlbmVzIGluIHRoZSA0dGgg
Y2VudHVyeSBCQzoKCiAgzp/hvZDPh+G9tiDPhM6x4b2Qz4ThvbAgz4DOsc+B4b23z4PPhM6xz4TO
seG9tyDOvM6/zrkgzrPOuc6zzr3hvb3Pg866zrXOuc69LCDhvaYg4byEzr3OtM+BzrXPgiDhvr/O
kc64zrfOvc6x4b+Wzr/OuSwKICDhvYXPhM6xzr0gz4Thvr8gzrXhvLDPgiDPhOG9sCDPgM+B4b2x
zrPOvM6xz4TOsSDhvIDPgM6/zrLOu+G9s8+Iz4kgzrrOseG9tiDhvYXPhM6xzr0gz4DPgeG9uM+C
IM+Ezr/hvbrPggogIM674b25zrPOv8+Fz4Igzr/hvZPPgiDhvIDOus6/4b27z4nOhyDPhM6/4b26
z4IgzrzhvbLOvSDOs+G9sM+BIM674b25zrPOv8+Fz4Igz4DOtc+B4b22IM+Ezr/hv6YKICDPhM65
zrzPic+B4b21z4POsc+DzrjOsc65IM6m4b23zrvOuc+Az4DOv869IOG9gc+B4b+2IM6zzrnOs869
zr/OvOG9s869zr/Phc+CLCDPhOG9sCDOtOG9siDPgM+B4b2xzrPOvM6xz4Thvr8KICDOteG8sM+C
IM+Ezr/hv6bPhM6/IM+Az4HOv+G9tc66zr/Ovc+EzrEsICDhvaXPg8644b6/IOG9hc+Az4nPgiDO
vOG9tCDPgM61zrnPg+G9uc68zrXOuOG+vyDOseG9kM+Ezr/hvbYKICDPgM+B4b25z4TOtc+Bzr/O
vSDOus6xzrrhv7bPgiDPg8664b2zz4jOsc+DzrjOsc65IM604b2zzr/OvS4gzr/hvZDOtOG9s869
IM6/4b2Wzr0g4byEzrvOu86/IM68zr/OuSDOtM6/zrrOv+G/ps+DzrnOvQogIM6/4byxIM+E4b2w
IM+Ezr/Ouc6x4b+mz4TOsSDOu+G9s86zzr/Ovc+EzrXPgiDhvKIgz4ThvbTOvSDhvZHPgOG9uc64
zrXPg865zr0sIM+AzrXPgeG9tiDhvKfPgiDOss6/z4XOu8614b27zrXPg864zrHOuSwKICDOv+G9
kM+H4b22IM+E4b20zr0gzr/hvZbPg86xzr0gz4DOsc+BzrnPg8+E4b2xzr3PhM61z4Ig4b2Rzrzh
v5bOvSDhvIHOvM6xz4HPhOG9sc69zrXOuc69LiDhvJDOs+G9vCDOtOG9sywg4b2Fz4TOuSDOvOG9
s869CiAgz4DOv8+E4b6/IOG8kM6+4b+Gzr0gz4Thv4cgz4DhvbnOu861zrkgzrrOseG9tiDPhOG9
sCDOseG9kc+E4b+Gz4Ig4byUz4fOtc65zr0g4byAz4PPhs6xzrvhv7bPgiDOus6x4b22IM6m4b23
zrvOuc+Az4DOv869CiAgz4TOuc68z4nPgeG9tc+DzrHPg864zrHOuSwgzrrOseG9tiDOvOG9sc67
4b6/IOG8gM66z4HOuc6y4b+2z4Igzr/hvLbOtM6xzocg4byQz4Dhvr8g4byQzrzOv+G/piDOs+G9
sc+BLCDOv+G9kCDPgOG9sc67zrHOuQogIM6z4b2zzrPOv869zrXOvSDPhM6x4b+mz4Thvr8g4byA
zrzPhuG9uc+EzrXPgc6xzocgzr3hv6bOvSDOvOG9s869z4TOv865IM+A4b2zz4DOtc65z4POvM6x
zrkgz4TOv+G/ps644b6/IOG8sc66zrHOveG9uM69CiAgz4DPgc6/zrvOsc6yzrXhv5bOvSDhvKHO
vOG/ls69IM614by2zr3Osc65IM+E4b20zr0gz4DPgeG9vc+EzrfOvSwg4b2Fz4DPic+CIM+Ezr/h
vbrPgiDPg8+FzrzOvOG9sc+Hzr/Phc+CCiAgz4Phvb3Pg86/zrzOtc69LiDhvJDhvbDOvSDOs+G9
sM+BIM+Ezr/hv6bPhM6/IM6yzrXOss6x4b23z4nPgiDhvZHPgOG9sc+Bzr7hv4MsIM+E4b25z4TO
tSDOus6x4b22IM+AzrXPgeG9tiDPhM6/4b+mCiAgz4ThvbfOvc6xIM+EzrnOvM+Jz4HhvbXPg861
z4TOseG9tyDPhM65z4IgzrrOseG9tiDhvYPOvSDPhM+B4b25z4DOv869IOG8kM6+4b2zz4PPhM6x
zrkgz4POus6/z4DOteG/ls69zocgz4DPgeG9ts69IM604b2yCiAgz4ThvbTOvSDhvIDPgc+H4b20
zr0g4b2Az4HOuOG/ts+CIOG9kc+Azr/OuOG9s8+DzrjOsc65LCDOvOG9sc+EzrHOuc6/zr0g4byh
zrPOv+G/ps68zrHOuSDPgM61z4HhvbYgz4Thv4bPggogIM+EzrXOu861z4XPhOG/hs+CIOG9gc69
z4TOuc69zr/hv6bOvSDPgM6/zrnOteG/ls+DzrjOsc65IM674b25zrPOv869LgoKICDOlM63zrzO
v8+DzrjhvbPOvc6/z4XPgiwgzpPhv70g4b6/zp/Ou8+Fzr3OuM65zrHOuuG9uM+CCgpHZW9yZ2lh
bjoKCiAgRnJvbSBhIFVuaWNvZGUgY29uZmVyZW5jZSBpbnZpdGF0aW9uOgoKICDhg5Lhg5fhg67h
g53hg5Xhg5cg4YOQ4YOu4YOa4YOQ4YOV4YOUIOGDkuGDkOGDmOGDkOGDoOGDneGDlyDhg6Dhg5Th
g5Lhg5jhg6Hhg6Lhg6Dhg5Dhg6rhg5jhg5AgVW5pY29kZS3hg5jhg6Eg4YOb4YOU4YOQ4YOX4YOU
IOGDoeGDkOGDlOGDoOGDl+GDkOGDqOGDneGDoOGDmOGDoeGDnQogIOGDmeGDneGDnOGDpOGDlOGD
oOGDlOGDnOGDquGDmOGDkOGDluGDlCDhg5Phg5Dhg6Hhg5Dhg6Hhg6zhg6Dhg5Thg5Hhg5Dhg5Ms
IOGDoOGDneGDm+GDlOGDmuGDmOGDqiDhg5Lhg5Dhg5jhg5vhg5Dhg6Dhg5fhg5Thg5Hhg5AgMTAt
MTIg4YOb4YOQ4YOg4YOi4YOhLAogIOGDpS4g4YOb4YOQ4YOY4YOc4YOq4YOo4YOYLCDhg5Lhg5Th
g6Dhg5vhg5Dhg5zhg5jhg5Dhg6jhg5guIOGDmeGDneGDnOGDpOGDlOGDoOGDlOGDnOGDquGDmOGD
kCDhg6jhg5Thg7Dhg5nhg6Dhg5Thg5Hhg6Eg4YOU4YOg4YOX4YOQ4YOTIOGDm+GDoeGDneGDpOGD
muGDmOGDneGDoQogIOGDlOGDpeGDoeGDnuGDlOGDoOGDouGDlOGDkeGDoSDhg5jhg6Hhg5Thg5cg
4YOT4YOQ4YOg4YOS4YOU4YOR4YOo4YOYIOGDoOGDneGDkuGDneGDoOGDmOGDquGDkOGDkCDhg5jh
g5zhg6Lhg5Thg6Dhg5zhg5Thg6Lhg5gg4YOT4YOQIFVuaWNvZGUt4YOYLAogIOGDmOGDnOGDouGD
lOGDoOGDnOGDkOGDquGDmOGDneGDnOGDkOGDmuGDmOGDluGDkOGDquGDmOGDkCDhg5Phg5Ag4YOa
4YOd4YOZ4YOQ4YOa4YOY4YOW4YOQ4YOq4YOY4YOQLCBVbmljb2RlLeGDmOGDoSDhg5Lhg5Dhg5vh
g53hg6fhg5Thg5zhg5Thg5Hhg5AKICDhg53hg57hg5Thg6Dhg5Dhg6rhg5jhg6Phg5og4YOh4YOY
4YOh4YOi4YOU4YOb4YOU4YOR4YOh4YOQLCDhg5Phg5Ag4YOS4YOQ4YOb4YOd4YOn4YOU4YOc4YOU
4YOR4YOY4YOXIOGDnuGDoOGDneGDkuGDoOGDkOGDm+GDlOGDkeGDqOGDmCwg4YOo4YOg4YOY4YOk
4YOi4YOU4YOR4YOo4YOYLAogIOGDouGDlOGDpeGDoeGDouGDlOGDkeGDmOGDoSDhg5Phg5Dhg5vh
g6Phg6jhg5Dhg5Xhg5Thg5Hhg5Dhg6Hhg5Ag4YOT4YOQIOGDm+GDoOGDkOGDleGDkOGDmuGDlOGD
nOGDneGDleGDkOGDnCDhg5nhg53hg5vhg57hg5jhg6Phg6Lhg5Thg6Dhg6Phg5og4YOh4YOY4YOh
4YOi4YOU4YOb4YOU4YOR4YOo4YOYLgoKUnVzc2lhbjoKCiAgRnJvbSBhIFVuaWNvZGUgY29uZmVy
ZW5jZSBpbnZpdGF0aW9uOgoKICDQl9Cw0YDQtdCz0LjRgdGC0YDQuNGA0YPQudGC0LXRgdGMINGB
0LXQudGH0LDRgSDQvdCwINCU0LXRgdGP0YLRg9GOINCc0LXQttC00YPQvdCw0YDQvtC00L3Rg9GO
INCa0L7QvdGE0LXRgNC10L3RhtC40Y4g0L/QvgogIFVuaWNvZGUsINC60L7RgtC+0YDQsNGPINGB
0L7RgdGC0L7QuNGC0YHRjyAxMC0xMiDQvNCw0YDRgtCwIDE5OTcg0LPQvtC00LAg0LIg0JzQsNC5
0L3RhtC1INCyINCT0LXRgNC80LDQvdC40LguCiAg0JrQvtC90YTQtdGA0LXQvdGG0LjRjyDRgdC+
0LHQtdGA0LXRgiDRiNC40YDQvtC60LjQuSDQutGA0YPQsyDRjdC60YHQv9C10YDRgtC+0LIg0L/Q
viAg0LLQvtC/0YDQvtGB0LDQvCDQs9C70L7QsdCw0LvRjNC90L7Qs9C+CiAg0JjQvdGC0LXRgNC9
0LXRgtCwINC4IFVuaWNvZGUsINC70L7QutCw0LvQuNC30LDRhtC40Lgg0Lgg0LjQvdGC0LXRgNC9
0LDRhtC40L7QvdCw0LvQuNC30LDRhtC40LgsINCy0L7Qv9C70L7RidC10L3QuNGOINC4CiAg0L/R
gNC40LzQtdC90LXQvdC40Y4gVW5pY29kZSDQsiDRgNCw0LfQu9C40YfQvdGL0YUg0L7Qv9C10YDQ
sNGG0LjQvtC90L3Ri9GFINGB0LjRgdGC0LXQvNCw0YUg0Lgg0L/RgNC+0LPRgNCw0LzQvNC90YvR
hQogINC/0YDQuNC70L7QttC10L3QuNGP0YUsINGI0YDQuNGE0YLQsNGFLCDQstC10YDRgdGC0LrQ
tSDQuCDQvNC90L7Qs9C+0Y/Qt9GL0YfQvdGL0YUg0LrQvtC80L/RjNGO0YLQtdGA0L3Ri9GFINGB
0LjRgdGC0LXQvNCw0YUuCgpUaGFpIChVQ1MgTGV2ZWwgMik6CgogIEV4Y2VycHQgZnJvbSBhIHBv
ZXRyeSBvbiBUaGUgUm9tYW5jZSBvZiBUaGUgVGhyZWUgS2luZ2RvbXMgKGEgQ2hpbmVzZQogIGNs
YXNzaWMgJ1NhbiBHdWEnKToKCiAgWy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS18LS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tXQogICAg4LmPIOC5geC4nOC5iOC4meC4lOC4tOC4meC4ruC4seC5
iOC4meC5gOC4quC4t+C5iOC4reC4oeC5guC4l+C4o+C4oeC5geC4quC4meC4quC4seC4h+C5gOC4
p+C4iiAg4Lie4Lij4Liw4Lib4LiB4LmA4LiB4Lio4LiB4Lit4LiH4Lia4Li54LmK4LiB4Li54LmJ
4LiC4Li24LmJ4LiZ4LmD4Lir4Lih4LmICiAg4Liq4Li04Lia4Liq4Lit4LiH4LiB4Lip4Lix4LiV
4Lij4Li04Lii4LmM4LiB4LmI4Lit4LiZ4Lir4LiZ4LmJ4Liy4LmB4Lil4LiW4Lix4LiU4LmE4Lib
ICAgICAgIOC4quC4reC4h+C4reC4h+C4hOC5jOC5hOC4i+C4o+C5ieC5guC4h+C5iOC5gOC4guC4
peC4suC5gOC4muC4suC4m+C4seC4jeC4jeC4sgogICAg4LiX4Lij4LiH4LiZ4Lix4Lia4LiW4Li3
4Lit4LiC4Lix4LiZ4LiX4Li14LmA4Lib4LmH4LiZ4LiX4Li14LmI4Lie4Li24LmI4LiHICAgICAg
ICAgICDguJrguYnguLLguJnguYDguKHguLfguK3guIfguIjguLbguIfguKfguLTguJvguKPguLTg
uJXguYDguJvguYfguJnguJnguLHguIHguKvguJnguLIKICDguYLguK7guIjguLTguYvguJnguYDg
uKPguLXguKLguIHguJfguLHguJ7guJfguLHguYjguKfguKvguLHguKfguYDguKHguLfguK3guIfg
uKHguLIgICAgICAgICDguKvguKHguLLguKLguIjguLDguIbguYjguLLguKHguJTguIrguLHguYjg
uKfguJXguLHguKfguKrguLPguITguLHguI0KICAgIOC5gOC4q+C4oeC4t+C4reC4meC4guC4seC4
muC5hOC4quC5hOC4peC5iOC5gOC4quC4t+C4reC4iOC4suC4geC5gOC4hOC4q+C4siAgICAgIOC4
o+C4seC4muC4q+C4oeC4suC4m+C5iOC4suC5gOC4guC5ieC4suC4oeC4suC5gOC4peC4ouC4reC4
suC4quC4seC4jQogIOC4neC5iOC4suC4ouC4reC5ieC4reC4h+C4reC4uOC5ieC4meC4ouC4uOC5
geC4ouC4geC5g+C4q+C5ieC5geC4leC4geC4geC4seC4mSAgICAgICAgICDguYPguIrguYnguKrg
uLLguKfguJnguLHguYnguJnguYDguJvguYfguJnguIrguJnguKfguJnguIrguLfguYjguJnguIrg
uKfguJnguYPguIgKICAgIOC4nuC4peC4seC4meC4peC4tOC4ieC4uOC4ouC4geC4uOC4ouC4geC4
teC4geC4peC4seC4muC4geC5iOC4reC5gOC4q+C4leC4uCAgICAgICAgICDguIrguYjguLLguIfg
uK3guLLguYDguJ7guKjguIjguKPguLTguIfguKvguJnguLLguJ/guYnguLLguKPguYnguK3guIfg
uYTguKvguYkKICDguJXguYnguK3guIfguKPguJrguKPguLLguIbguYjguLLguJ/guLHguJnguIjg
uJnguJrguKPguKPguKXguLHguKIgICAgICAgICAgIOC4pOC5heC4q+C4suC5g+C4hOC4o+C4hOC5
ieC4s+C4iuC4ueC4geC4ueC5ieC4muC4o+C4o+C4peC4seC4h+C4geC5jCDguK8KCiAgKFRoZSBh
Ym92ZSBpcyBhIHR3by1jb2x1bW4gdGV4dC4gSWYgY29tYmluaW5nIGNoYXJhY3RlcnMgYXJlIGhh
bmRsZWQKICBjb3JyZWN0bHksIHRoZSBsaW5lcyBvZiB0aGUgc2Vjb25kIGNvbHVtbiBzaG91bGQg
YmUgYWxpZ25lZCB3aXRoIHRoZQogIHwgY2hhcmFjdGVyIGFib3ZlLikKCkV0aGlvcGlhbjoKCiAg
UHJvdmVyYnMgaW4gdGhlIEFtaGFyaWMgbGFuZ3VhZ2U6CgogIOGIsOGIm+GLrSDhiqDhi63hibPh
iKjhiLUg4YqV4YyJ4YilIOGKoOGLreGKqOGIsOGIteGNogogIOGJpeGIiyDhiqvhiIjhip0g4Yql
4YqV4Yuw4Yqg4Ymj4Ym0IOGJoOGJhuGImOGMoOGKneGNogogIOGMjOGMpSDhi6vhiIjhiaThibEg
4YmB4Yid4Yyl4YqTIOGKkOGLjeGNogogIOGLsOGIgCDhiaDhiJXhiI3hiJkg4YmF4YmkIOGJo+GL
reGMoOGMoyDhipXhjKPhibUg4Ymg4YyI4Yuw4YiI4YuN4Y2iCiAg4Yuo4Yqg4Y2NIOGLiOGIiOGI
neGJsyDhiaDhiYXhiaQg4Yqg4Yut4Ymz4Yi94Yid4Y2iCiAg4Yqg4Yut4YylIOGJoOGJoOGIiyDh
i7Phi4sg4Ymw4YiY4Ymz4Y2iCiAg4Yiy4Ymw4Yio4YyJ4YiZIOGLreGLsOGIqOGMjeGImeGNogog
IOGJgOGItSDhiaDhiYDhiLXhjaUg4YuV4YqV4YmB4YiL4YiNIOGJoOGKpeGMjeGIqSDhi63hiITh
i7PhiI3hjaIKICDhi7XhiK0g4Ymi4Yur4Yml4YitIOGKoOGKleGJoOGIsyDhi6vhiLXhiK3hjaIK
ICDhiLDhi40g4Yql4YqV4Yuw4Ymk4YmxIOGKpeGKleGMhSDhiqXhipXhi7Ag4YyJ4Yio4Ymk4Ymx
IOGKoOGLreGJsOGLs+GLsOGIreGIneGNogogIOGKpeGMjeGLnOGIrSDhi6jhiqjhjYjhibDhi43h
ipUg4YyJ4Yiu4YiuIOGIs+GLreGLmOGMi+GLjSDhiqDhi63hi7XhiK3hiJ3hjaIKICDhi6jhjI7h
iKjhiaThibUg4YiM4Ymj4Y2lIOGJouGLq+GLqeGJtSDhi63hiLXhiYUg4Ymj4Yur4Yup4Ym1IOGL
q+GMoOGIjeGJheGNogogIOGIpeGIqyDhiqjhiJjhjY3hibPhibUg4YiN4YyE4YqVIOGIi+GNi+GJ
s+GJteGNogogIOGLk+GJo+GLrSDhiJvhi7DhiKrhi6sg4Yuo4YiI4YuN4Y2lIOGMjeGKleGLtSDh
i63hi54g4Yut4Yue4Yir4YiN4Y2iCiAg4Yuo4Yql4Yi14YiL4YidIOGKoOGMiOGIqSDhiJjhiqsg
4Yuo4Yqg4Yie4YirIOGKoOGMiOGIqSDhi4vhiK3hiqvhjaIKICDhibDhipXhjIvhiI4g4Ymi4Ymw
4Y2JIOGJsOGImOGIjeGItiDhiaPhjYnhjaIKICDhi4jhi7PhjIXhiIUg4Yib4YitIOGJouGIhuGK
lSDhjKjhiK3hiLXhiIUg4Yqg4Ym14YiL4Yiw4YuN4Y2iCiAg4Yql4YyN4Yit4YiF4YqVIOGJoOGN
jeGIq+GIveGIhSDhiI3hiq0g4YuY4Yit4YyL4Y2iCgpSdW5lczoKCiAg4Zq74ZuWIOGas+GaueGa
q+GapiDhmqbhmqvhm48g4Zq74ZuWIOGbkuGaouGbnuGbliDhmqnhmr4g4Zqm4Zqr4ZuXIOGbmuGa
quGavuGbnuGbliDhmr7hmqnhmrHhmqbhmrnhm5bhmqrhmrHhm57hmqLhm5cg4Zq54ZuB4ZqmIOGa
puGaqiDhmrnhm5bhm6XhmqsKCiAgKE9sZCBFbmdsaXNoLCB3aGljaCB0cmFuc2NyaWJlZCBpbnRv
IExhdGluIHJlYWRzICdIZSBjd2FldGggdGhhdCBoZQogIGJ1ZGUgdGhhZW0gbGFuZGUgbm9ydGh3
ZWFyZHVtIHdpdGggdGhhIFdlc3RzYWUuJyBhbmQgbWVhbnMgJ0hlIHNhaWQKICB0aGF0IGhlIGxp
dmVkIGluIHRoZSBub3J0aGVybiBsYW5kIG5lYXIgdGhlIFdlc3Rlcm4gU2VhLicpCgpCcmFpbGxl
OgoKICDioYzioIHioKfioJEg4qC84qCB4qCSICDioY3ioJzioIfioJHioLnioLDioI4g4qGj4qCV
4qCMCgogIOKhjeKgnOKgh+KgkeKguSDioLrioIHioI4g4qCZ4qCR4qCB4qCZ4qCSIOKgnuKglSDi
oIPioJHioJvioJQg4qC64qCK4qC54qCyIOKhueKgu+KgkSDioIrioI4g4qCd4qCVIOKgmeKgs+Kg
g+KgngogIOKgseKggeKgnuKgkeKgp+KguyDioIHioIPioLPioJ4g4qC54qCB4qCe4qCyIOKhueKg
kSDioJfioJHioJvioIrioIzioLsg4qCV4qCLIOKgmeKgiuKgjiDioIPioKXioJfioIrioIHioIcg
4qC64qCB4qCOCiAg4qCO4qCK4qCb4qCd4qCrIOKgg+KguSDioLnioJEg4qCK4qCH4qC74qCb4qC5
4qCN4qCB4qCd4qCCIOKgueKgkSDioIrioIfioLvioIXioIIg4qC54qCRIOKgpeKgneKgmeKgu+Kg
nuKggeKgheKgu+KgggogIOKggeKgneKgmSDioLnioJEg4qCh4qCK4qCR4qCLIOKgjeKgs+Kgl+Kg
neKgu+KgsiDioY7ioIrioJfioJXioJXioJvioJEg4qCO4qCK4qCb4qCd4qCrIOKgiuKgnuKgsiDi
oYHioJ3ioJkKICDioY7ioIrioJfioJXioJXioJvioJHioLDioI4g4qCd4qCB4qCN4qCRIOKguuKg
geKgjiDioJvioJXioJXioJkg4qCl4qCP4qCV4qCdIOKgsOKhoeKggeKgneKgm+KgkeKggiDioIvi
oJXioJcg4qCB4qCd4qC54qC54qCU4qCbIOKgmeKgkQogIOKgoeKgleKgjuKgkSDioJ7ioJUg4qCP
4qCl4qCeIOKgmeKgiuKgjiDioJnioIHioJ3ioJkg4qCe4qCV4qCyCgogIOKhleKgh+KgmSDioY3i
oJzioIfioJHioLkg4qC64qCB4qCOIOKggeKgjiDioJnioJHioIHioJkg4qCB4qCOIOKggSDioJni
oJXioJXioJfioKTioJ3ioIHioIrioIfioLIKCiAg4qGN4qCU4qCZ4qCWIOKhiiDioJnioJXioJ3i
oLDioJ4g4qCN4qCR4qCB4qCdIOKgnuKglSDioI7ioIHioLkg4qC54qCB4qCeIOKhiiDioIXioJ3i
oKrioIIg4qCV4qCLIOKgjeKguQogIOKgquKgnSDioIXioJ3ioKrioIfioKvioJvioJHioIIg4qCx
4qCB4qCeIOKgueKgu+KgkSDioIrioI4g4qCP4qCc4qCe4qCK4qCK4qCl4qCH4qCc4qCH4qC5IOKg
meKgkeKggeKgmSDioIHioIPioLPioJ4KICDioIEg4qCZ4qCV4qCV4qCX4qCk4qCd4qCB4qCK4qCH
4qCyIOKhiiDioI3ioIrioKPioJ4g4qCZ4qCB4qCn4qCRIOKgg+KgkeKgsiDioJTioIrioIfioJTi
oKvioIIg4qCN4qC54qCO4qCR4qCH4qCL4qCCIOKgnuKglQogIOKgl+KgkeKgm+KgnOKgmSDioIEg
4qCK4qCV4qCL4qCL4qCU4qCk4qCd4qCB4qCK4qCHIOKggeKgjiDioLnioJEg4qCZ4qCR4qCB4qCZ
4qCR4qCMIOKgj+KgiuKgkeKgiuKgkSDioJXioIsg4qCK4qCX4qCV4qCd4qCN4qCV4qCd4qCb4qC7
4qC5CiAg4qCUIOKgueKgkSDioJ7ioJfioIHioJnioJHioLIg4qGD4qCl4qCeIOKgueKgkSDioLri
oIrioI7ioJnioJXioI0g4qCV4qCLIOKgs+KglyDioIHioJ3ioIrioJHioIzioJXioJfioI4KICDi
oIrioI4g4qCUIOKgueKgkSDioI7ioIrioI3ioIrioIfioJHioIYg4qCB4qCd4qCZIOKgjeKguSDi
oKXioJ3ioJnioIHioIfioIfioKrioKsg4qCZ4qCB4qCd4qCZ4qCOCiAg4qCp4qCB4qCH4qCHIOKg
neKgleKgniDioJnioIrioIzioKXioJfioIMg4qCK4qCe4qCCIOKgleKglyDioLnioJEg4qGK4qCz
4qCd4qCe4qCX4qC54qCw4qCOIOKgmeKgleKgneKgkSDioIvioJXioJfioLIg4qG54qCzCiAg4qC6
4qCK4qCH4qCHIOKgueKgu+KgkeKgi+KgleKgl+KgkSDioI/ioLvioI3ioIrioJ4g4qCN4qCRIOKg
nuKglSDioJfioJHioI/ioJHioIHioJ7ioIIg4qCR4qCN4qCP4qCZ4qCB4qCe4qCK4qCK4qCB4qCH
4qCH4qC54qCCIOKgueKggeKgngogIOKhjeKgnOKgh+KgkeKguSDioLrioIHioI4g4qCB4qCOIOKg
meKgkeKggeKgmSDioIHioI4g4qCBIOKgmeKgleKgleKgl+KgpOKgneKggeKgiuKgh+KgsgoKICAo
VGhlIGZpcnN0IGNvdXBsZSBvZiBwYXJhZ3JhcGhzIG9mICJBIENocmlzdG1hcyBDYXJvbCIgYnkg
RGlja2VucykKCkNvbXBhY3QgZm9udCBzZWxlY3Rpb24gZXhhbXBsZSB0ZXh0OgoKICBBQkNERUZH
SElKS0xNTk9QUVJTVFVWV1hZWiAvMDEyMzQ1Njc4OQogIGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3
eHl6IMKjwqnCtcOAw4bDlsOew5/DqcO2w78KICDigJPigJTigJjigJzigJ3igJ7igKDigKLigKbi
gLDihKLFk8WgxbjFvuKCrCDOkc6SzpPOlM6pzrHOss6zzrTPiSDQkNCR0JLQk9CU0LDQsdCy0LPQ
tAogIOKIgOKIguKIiOKEneKIp+KIquKJoeKIniDihpHihpfihqjihrvih6Mg4pSQ4pS84pWU4pWY
4paR4pa64pi64pmAIO+sge+/veKRgOKCguG8oOG4gtOl4bqEyZDLkOKNjteQ1LHhg5AKCkdyZWV0
aW5ncyBpbiB2YXJpb3VzIGxhbmd1YWdlczoKCiAgSGVsbG8gd29ybGQsIM6azrHOu863zrzhvbPP
gc6xIM664b25z4POvM61LCDjgrPjg7Pjg4vjg4Hjg48KCkJveCBkcmF3aW5nIGFsaWdubWVudCB0
ZXN0czogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICDilogKICAgICAg
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgIOKWiQogIOKVlOKVkOKVkOKVpuKVkOKVkOKVlyAg4pSM4pSA4pSA4pSs4pSA4pSA4pSQ
ICDila3ilIDilIDilKzilIDilIDila4gIOKVreKUgOKUgOKUrOKUgOKUgOKVriAg4pSP4pSB4pSB
4pSz4pSB4pSB4pSTICDilI7ilJLilI/ilJEgICDilbcgIOKVuyDilI/ilK/ilJMg4pSM4pSw4pSQ
ICAgIOKWiiDilbHilbLilbHilbLilbPilbPilbMKICDilZHilIzilIDilajilIDilJDilZEgIOKU
guKVlOKVkOKVp+KVkOKVl+KUgiAg4pSC4pWS4pWQ4pWq4pWQ4pWV4pSCICDilILilZPilIDilYHi
lIDilZbilIIgIOKUg+KUjOKUgOKVguKUgOKUkOKUgyAg4pSX4pWD4pWE4pSZICDilbbilLzilbTi
lbrilYvilbjilKDilLzilKgg4pSd4pWL4pSlICAgIOKWiyDilbLilbHilbLilbHilbPilbPilbMK
ICDilZHilILilbIg4pWx4pSC4pWRICDilILilZEgICDilZHilIIgIOKUguKUgiDilIIg4pSC4pSC
ICDilILilZEg4pSDIOKVkeKUgiAg4pSD4pSCIOKVvyDilILilIMgIOKUjeKVheKVhuKUkyAgIOKV
tSAg4pW5IOKUl+KUt+KUmyDilJTilLjilJggICAg4paMIOKVseKVsuKVseKVsuKVs+KVs+KVswog
IOKVoOKVoSDilbMg4pWe4pWjICDilJzilaIgICDilZ/ilKQgIOKUnOKUvOKUgOKUvOKUgOKUvOKU
pCAg4pSc4pWr4pSA4pWC4pSA4pWr4pSkICDilKPilL/ilb7ilLzilbzilL/ilKsgIOKUleKUm+KU
luKUmiAgICAg4pSM4pSE4pSE4pSQIOKVjiDilI/ilIXilIXilJMg4pSLIOKWjSDilbLilbHilbLi
lbHilbPilbPilbMKICDilZHilILilbEg4pWy4pSC4pWRICDilILilZEgICDilZHilIIgIOKUguKU
giDilIIg4pSC4pSCICDilILilZEg4pSDIOKVkeKUgiAg4pSD4pSCIOKVvSDilILilIMgIOKWkeKW
keKWkuKWkuKWk+KWk+KWiOKWiCDilIogIOKUhiDilY4g4pWPICDilIcg4pSLIOKWjgogIOKVkeKU
lOKUgOKVpeKUgOKUmOKVkSAg4pSC4pWa4pWQ4pWk4pWQ4pWd4pSCICDilILilZjilZDilarilZDi
lZvilIIgIOKUguKVmeKUgOKVgOKUgOKVnOKUgiAg4pSD4pSU4pSA4pWC4pSA4pSY4pSDICDilpHi
lpHilpLilpLilpPilpPilojilogg4pSKICDilIYg4pWOIOKVjyAg4pSHIOKUiyDilo8KICDilZri
lZDilZDilanilZDilZDilZ0gIOKUlOKUgOKUgOKUtOKUgOKUgOKUmCAg4pWw4pSA4pSA4pS04pSA
4pSA4pWvICDilbDilIDilIDilLTilIDilIDila8gIOKUl+KUgeKUgeKUu+KUgeKUgeKUmyAg4paX
4paE4paW4pab4paA4pacICAg4pSU4pWM4pWM4pSYIOKVjiDilJfilY3ilY3ilJsg4pSLICDiloHi
loLiloPiloTiloXilobilofilogKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAg
ICAgICAgICAgICDilp3iloDilpjilpniloTilp8K
EOT
    dief("corrupted inlined UTF-8 string: %d", length($_UnicodeString))
        unless length($_UnicodeString) == 14052;
    $_UnicodeString = decode("UTF-8", $_UnicodeString, FB_CROAK);
    dief("corrupted inlined Unicode string: %d", length($_UnicodeString))
        unless length($_UnicodeString) == 7621;
}

#
# return a reference to a random binary string of the given length
#

sub _rndbin ($) {
    my($length) = @_;
    my($string, $digest, $extra);

    return(\ "") unless $length > 0;
    $_MD5->add(rand());
    $string = "";
    while (length($string) < $length) {
        $digest = $_MD5->digest();
        $_MD5->add($digest);
        $string .= $digest;
    }
    $extra = length($string) - $length;
    substr($string, $length, $extra, "") if $extra > 0;
    return(\$string);
}

#
# return a reference to a random Unicode string of the given length
#

sub _rnduni ($) {
    my($length) = @_;
    my($string, $digest, $extra);

    return(\ "") unless $length > 0;
    $_MD5->add(rand());
    $string = "";
    while (length($string) < $length) {
        $digest = $_MD5->digest();
        $_MD5->add($digest);
        foreach my $n (unpack("n8", $digest)) {
            $string .= substr($_UnicodeString,
                              int(($n >> 6) * 7.3), ($n & 63) + 1);
        }
    }
    $extra = length($string) - $length;
    substr($string, $length, $extra, "") if $extra > 0;
    return(\$string);
}

#
# return a random integer according to the given specification
#

sub _rndint ($) {
    my($spec) = @_;
    my($rnd);

    if ($spec =~ /^(\d+)$/) {
        return($1);
    } elsif ($spec =~ /^(\d+)-(\d+)$/) {
        return($1 + int(rand($2 - $1 + 1)));
    } elsif ($spec =~ /^(\d+)\^(\d+)$/) {
        # see Irwin-Hall in http://en.wikipedia.org/wiki/Normal_distribution
        $rnd = rand(1) + rand(1) + rand(1) + rand(1) + rand(1) + rand(1) +
               rand(1) + rand(1) + rand(1) + rand(1) + rand(1) + rand(1);
        return($1 + int($rnd * ($2 - $1 + 1) / 12));
    }
    dief("unsupported random integer specification: %s", $spec);
}

#
# return a reference to a random string according to the given entropy
#

sub _rndstr ($$$) {
    my($text, $length, $entropy) = @_;
    my($string, $extra, $tmp);

    return(\ "") unless $length > 0;
    if ($entropy == 0) {
        $tmp = chr(65 + int(rand(26)));
        $string = $tmp x $length;
    } elsif ($entropy == 1) {
        $string = unpack("h*", ${ _rndbin(int($length / 2 + 0.5)) });
        $extra = length($string) - $length;
        substr($string, $length, $extra, "") if $extra > 0;
    } elsif ($entropy == 2) {
        $string = encode_base64(${ _rndbin(int($length * 0.75 + 1)) }, "");
        $string =~ tr{/+}{-_};
        $extra = length($string) - $length;
        substr($string, $length, $extra, "") if $extra > 0;
    } elsif ($entropy == 3) {
        $string = pack("c*", map(32 + int(rand(95)), 1 .. $length));
    } else {
        # directly return the reference!
        return($text ? _rnduni($length) : _rndbin($length));
    }
    return(\$string);
}

#
# constructor
#

my $optional_scalar = { optional => 1, type => SCALAR };
my $optional_rndint = { %{ $optional_scalar }, regex => qr/^(\d+[\-\^])?\d+$/ };

my %new_options = (
    "text"                 => $optional_rndint,
    "body-length"          => $optional_rndint,
    "body-entropy"         => $optional_rndint,
    "header-count"         => $optional_rndint,
    "header-name-prefix"   => $optional_scalar,
    "header-name-length"   => $optional_rndint,
    "header-name-entropy"  => $optional_rndint,
    "header-value-prefix"  => $optional_scalar,
    "header-value-length"  => $optional_rndint,
    "header-value-entropy" => $optional_rndint,
);

sub new : method {
    my($class, %option, $self);

    $class = shift(@_);
    %option = validate(@_, \%new_options) if @_;
    $option{"header-name-prefix"} = ""
        unless defined($option{"header-name-prefix"});
    $option{"header-value-prefix"} = ""
        unless defined($option{"header-value-prefix"});
    $self = \%option;
    _init() unless $_MD5;
    bless($self, $class);
    return($self);
}

#
# message generation
#

sub message : method {
    my($self) = @_;
    my(%option, $tmp, $name, $value);

    # generate text
    $tmp = _rndint($self->{"text"} || 0);
    $option{text} = $tmp ? 1 : 0;
    # generate body
    $option{body_ref} = _rndstr($option{text},
        _rndint($self->{"body-length"}  || 0),
        _rndint($self->{"body-entropy"} || 0));
    # generate header
    $tmp = _rndint($self->{"header-count"} || 0);
    if ($tmp) {
        $option{header} = {};
        while ($tmp-- > 0) {
            # generate header name
            $name = _rndstr(1,
                _rndint($self->{"header-name-length"}  || 0),
                _rndint($self->{"header-name-entropy"} || 0));
            $name = $self->{"header-name-prefix"} . ${ $name };
            # generate header value
            $value = _rndstr(1,
                _rndint($self->{"header-value-length"}  || 0),
                _rndint($self->{"header-value-entropy"} || 0));
            $value = $self->{"header-value-prefix"} . ${ $value };
            # store it
            $option{header}{$name} = $value;
        }
    }
    return(Messaging::Message->new(%option));
}

1;

__DATA__

=head1 NAME

Messaging::Message::Generator - versatile message generator

=head1 SYNOPSIS

  use Messaging::Message::Generator;

  # create the generator
  $mg = Messaging::Message::Generator->new(
      "text"                 => "0-1",
      "body-length"          => "0-1000",
      "body-entropy"         => "1-4",
      "header-count"         => "2^6",
      "header-name-length"   => "10-20",
      "header-name-entropy"  => "1-2",
      "header-name-prefix"   => "rnd-",
      "header-value-length"  => "20-40",
      "header-value-entropy" => "0-3",
  );

  # use it to generate 10 messages
  foreach (1 .. 10) {
      $msg = $mg->message();
      ... do something with it ...
  }

=head1 DESCRIPTION

This module provides a versatile message generator that can be useful
for stress testing or benchmarking messaging brokers or libraries.

=head1 METHODS

The following methods are available:

=over

=item new([OPTIONS])

return a new Messaging::Message::Generator object (class method)

=item message()

return a newly generated Messaging::Message object

=back

=head1 OPTIONS

When creating a message generator, the following options can be given:

=over

=item text

integer specifying if the body is text string (as opposed to binary
string) or not; supported values are C<0> (never text), C<1> (always
text) or C<0-1> (randomly text or not)

=item body-length

integer specifying the length of the body

=item body-entropy

integer specifying the entropy of the body

=item header-count

integer specifying the number of header fields

=item header-name-prefix

string to prepend to each header field name

=item header-name-length

integer specifying the length of each header field name (prefix not
included)

=item header-name-entropy

integer specifying the entropy of each header field name

=item header-value-prefix

string to prepend to each header field value

=item header-value-length

integer specifying the length of each header field value (prefix not
included)

=item header-value-entropy

integer specifying the entropy of each header field value

=back

All the options default to C<0> or the empty string.

All the I<integer> options can be given either:

=over

=item * a positive integer C<X>, meaning exactly this value

=item * a C<X-Y> range, meaning a discrete uniform distribution
between the two given integers, bounds included

=item * a C<X^Y> range, meaning a pseudo normal distribution between
the two given integers, bounds included

=back

All the I<entropy> options interpret their integer value this way:

=over

=item * C<0> means a single character, repeated

=item * C<1> means hexadecimal characters

=item * C<2> means Base64 characters (with C<-> instead of C</> and C<_> instead od C<+>)

=item * C<3> means printable 7-bit ASCII characters

=item * C<4> means random characters (including Unicode, except for binary bodies)

=back

=head1 SEE ALSO

L<Messaging::Message>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2021
