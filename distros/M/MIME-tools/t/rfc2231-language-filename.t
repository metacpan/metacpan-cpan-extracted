use strict;
use warnings;
use Test::More tests => 5;

use MIME::Head;

sub filename {
    my $head = MIME::Head->new(["Content-Disposition: attachment; $_[0]\n"]);
    return $head->recommended_filename();
}

is(filename("filename*=utf-8'en-US'payload.exe"), 'payload.exe',
   'Language tag with a hyphen is ignored');
is(filename("filename*=''payload.exe"), 'payload.exe',
   'Empty charset and language are allowed');
is(filename(q{filename*="us-ascii'?Q?safe.txt?= =?x'payload.exe"}), 'payload.exe',
   'Language tag cannot add an encoded word');
is(filename(q{filename*="us-ascii?Q?safe.txt?= =?x''payload.exe"}), 'payload.exe',
   'Charset cannot add an encoded word');
is(filename("filename*=utf-8'en'payload.exe"), 'payload.exe',
   'Language tag without a hyphen is ignored');
