#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin . "/lib";

use HTML::QRCode;
use CGI;

my $q = CGI->new;
my $text = $q->param('text') || 'http://blog.hide-k.net/';
my $qrcode = HTML::QRCode->new->plot($text);
print $q->header;
print <<"HTML";
<html>
<head></head>
<body>
$qrcode
</body>
</html>
HTML
