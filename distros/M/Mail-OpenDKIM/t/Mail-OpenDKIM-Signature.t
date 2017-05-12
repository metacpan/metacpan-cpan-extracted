#!/usr/bin/perl -wT

use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mail-OpenDKIM-Signature.t'

#########################

use Test::More tests => 5;
BEGIN { use_ok('Mail::OpenDKIM::Signature') };

#########################

my $key = <<'EOF';
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAu7azXvQR9nTJRRU5SCO0l3gg2CSU6NCjcx8OreFw/U1YDn3j
/tk/IvqqriWX5xPktPHautWcKE3/fCIUBY0FlxtwdJ3aQw/x83R9uACqbsb1qTrV
Cefxz/wQ/pTit6f6oE2KuS2+PWo7V4Mj30zMqoCCShUGT1dnxUltzAHbiFaHw5Em
Ph+dPgJd04qUWQM8jKoiR8QpWqJ5uhlnRXu8XVpi2MVVqVe6sbBPJC26ZfiTHsba
PWYpPy+kKbX3ag1NGCJYCMqJLXxbE2HykbwwQ3/kUxm7a/5YUXJJ+WcFMwVKnGyX
gCRxVevR+WIQoTirDpwYYmtekdCp8MBZg+f5UQIDAQABAoIBAHuTIzJ3avvclkOs
XTFokBLHOpgQPRengnLfF0LRDxkyOa4Qom+7hRz5+DL8/KtbJU0Ziu1EgrDl6DNI
G/YriGqZ3cZnxLAxZw7muXzQs2KKCF+II4eJ8l8Big6O5VISe6PcaF7QBlVYAgjy
hEMUxAfa4erzPFwvJllypZ2P+34clmYAj0/9VtWNq9QixJEJ/5vKhlF2Wc84D3Mq
GMMzolagQWBxBVTu0Odh1HdUx5ny3eHUM5CgB75J2Uds1ranuP6/YXvgV7w6E9UD
ycCNPZFtaWc2hZl6gv/TpTywJi5D9VRXthRDZg1Fjw6HxMUPmT4JENqms7vUZCbX
Xo3jc4ECgYEA9guNiOLkxOmpPW2yCPJAqst6fmfd3IIOt9Y1+8sXwU6pxYtpX8tK
wAJGpZJr9RpjSLDvSQN/XuS3PmLRXzqrlMNTP929n7yLSjnkN9LWJBYE6Pd/U8OT
TWFggkM0Shhs8ihHc54XxdnhFw9aJbHmOdCSbTCBl0eTI26TJwExtd0CgYEAw074
tnbURYnRpFnMDlh6+3soIKWUfeVV0X0DlJorLMqaouY+EXV/3e4CD/P2d7DqKoyv
O/F9dGWp3N5y3rQE65tYd9iiLiYq1c24mSjOzIebMkymn5OH+OK9HOqekDONEvUW
ma1lzYQK8Rl1mU6dHv4hgTXbEpuyQGzXlCukXAUCgYEA3Aciz+oPqORH+24Qix2Q
pOwII+hgqCQKY24FoqFRIgZlngn49riGpUSjxsc1EeBCLyxDICkni0W/dOPL1nxS
Glu+I9v5ClMCwSMaKq254FVsmKVT0SWRod5V/sd4iFZlfvx0QTl8ius39nY9KH55
ovQZLdn12cIhG8tzfqr7uGUCgYAg77RpsOhjQbak7K/Iy4sR1dcSilncUUyDo31z
Ffyp9RDW39UfxJznpDec0RuDW8Zhno/+n970PiDDKpBclicuRGhK7bGL7svSenri
+UrGmyfE98AxsQOBKVuTAM30q3zi8Yn6KI++dMITnqOCUwuUKm8kBx0GqlMJIlHI
nwN8sQKBgFY0LVuVjPNrQDoyDMEM1F3THlT9Fl7n0WC6Ci0ppX2/tzUKFwtM40yr
K41ZoAC0yg71WKrmQ8MQcD5vRwltnNxExHAIXTV7py+qCgOvRsIBX92zum0pvSJ/
/im7Nc8lUx+mSQ/Xs9ZUlv4XOMhcgBf17vnXGg12foEXVoxCenNM
-----END RSA PRIVATE KEY-----
EOF

my $signature = new_ok('Mail::OpenDKIM::Signature' => [
		Algorithm => 'rsa-sha1',
		Method => 'relaxed',
		Domain => 'example.com',
		Selector => 'example',
		Data => $key,
	]
);

my $s = 'v=1; a=rsa-sha1; c=relaxed; d=mailermailer.com; h=from:to:subject; s=mailermailer; bh=TozDQdcuD/NljOIYtF7AyqaxB8s=; b=dMk1p8wJdpHEFOk2pbtSScD3c2spKGkEo917Plae1weNhdrPvZOWvpZYnQL4/S9iQQtXpUByhjU0ObbWE/SgOhpFS216C847c+3RJCESNMJqxSzf65cuGPLffKQg4dboVKS759wC3hDhIMIPmdLABaK4crFAZcBnl+AQP1QpV4H9jUydiU1CqLURpZgeRd3uqhtua/wJTz3t7ad7YfPhQst7pYD7m97xp0PZURjPTYEKTHSJfhfT4zVDXl1+/HeNc3SV+nT9trpIj9ZOfmhotPYGE1PLX5ZyhZmskff7jQDALJxj6z2jICTCKhwLOtuENf9tCYiyYlMcYuij+hTSBg==';

ok($signature->data($s) eq $s);

ok($signature->data() eq $s);

ok($signature->as_string() eq "DKIM-Signature: $s");
