use strict;
use Test::More tests => 2;
use Test::Requires 'LWPx::Record::DataSection';

ok !$LWPx::Record::DataSection::Data->{'GET http://localhost/'};

LWPx::Record::DataSection->load_data;

ok $LWPx::Record::DataSection::Data->{'GET http://localhost/'};

__DATA__

@@ GET http://localhost/
HTTP/1.0 200 OK
Content-Type: text/plain

hello, localhost
