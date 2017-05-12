#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Image::PNG::QRCode 'qrpng';
use URI::Escape;

my $request = $ENV{QUERY_STRING};
if ($request) {
    my %params;
    my @params = split /\&/, $request;
    for my $param (@params) {
	my ($k, $v) = split /=/, $param;
	if ($k && $v) {
	    $v =~ s/\+/ /g;
	    $params{$k} = uri_unescape ($v);
	}
    }
    if ($params{w}) {
	send_qr_code (%params);
    }
}
print <<EOF;
Content-Type: text/plain
Status: 400

You didn't send anything, use me like this: qrpng.cgi?w=message-to-encode
EOF
exit;

sub send_qr_code
{
    my (%params) = @_;
    my $w = $params{w};
    my $s;
    eval {
	qrpng (text => $w, out => \$s);
    };
    if ($@) {
	print <<EOF;
Content-Type: text/plain
Status: 500

qrpng failed like this: $@
EOF
	exit;
    }
    binmode STDOUT, ":raw";
    my $l = length $s;
    print <<EOF;
Content-Type: image/png
Content-Length: $l

$s
EOF
    exit;
}
