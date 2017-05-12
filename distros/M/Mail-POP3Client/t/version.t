use strict;
use warnings;

use Test::More tests => 1;

use Mail::POP3Client;

my $Version  = Mail::POP3Client::Version();
like ($Version, qr/^\d\.\d\d$/, "Version number '$Version' found");
