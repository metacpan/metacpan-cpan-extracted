#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

use Mac::PopClip::Quick::Generator;

my $g = Mac::PopClip::Quick::Generator->new(
    extension_name       => 'bob',
    regex                => 'foo',
    blocked_apps         => ['com.apple.TextEdit'],
    required_apps        => ['com.apple.Safari'],
    extension_identifier => 'com.twoshortplanks.testsuitetest',
    src                  => <<'PERL'
#!perl

use strict;
use warnings;

use Mac::PopClip::Quick;
print reverse popclip_text();
PERL
);

is $g->extension_name, 'bob', 'extension_name';

is $g->title, 'bob', 'title';

like $g->filename, qr/.[.]popclipextz\z/, 'filename';

is $g->extension_identifier, 'com.twoshortplanks.testsuitetest',
    'extension_identifier';

is $g->required_software_version, '701', 'required_software_version';

is $g->regex, 'foo', 'regex';

is_deeply $g->blocked_apps, ['com.apple.TextEdit'], 'blocked_apps';

is_deeply $g->required_apps, ['com.apple.Safari'], 'required_apps';

is $g->filtered_src, <<'PERL', 'filterd_src';
#!perl

use strict;
use warnings;

BEGIN{$INC{'Mac/PopClip/Quick.pm'}=1}sub popclip_text(){$ENV{POPCLIP_TEXT}} use Mac::PopClip::Quick;
print reverse popclip_text();
PERL

is $g->plist_xml, <<'XML', 'plist_xml';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Actions</key>
    <array>
      <dict>
        <key>Blocked Apps</key>
        <array>
            <string>com.apple.TextEdit</string>
        </array>

        <key>Regular Expression</key>
        <string>foo</string>

        <key>Required Apps</key>
        <array>
            <string>com.apple.Safari</string>
        </array>

        <key>Script Interpreter</key>
        <string>/usr/bin/perl</string>

        <key>Shell Script File</key>
        <string>script.pl</string>

        <key>Title</key>
        <string>bob</string>
      </dict>
    </array>

    <key>Extension Identifier</key>
    <string>com.twoshortplanks.testsuitetest</string>

    <key>Extension Name</key>
    <string>bob</string>

    <key>Required Software Version</key>
    <string>701</string>
    </dict>
  </plist>
XML

# default identifier?  need to create a new one and check that it's
# the right thing.  Can't specify exactly, because this'll be different
# on every mac

my $g2 = Mac::PopClip::Quick::Generator->new(
    extension_name => 'example',
    src            => 'dummy'
);

like $g2->extension_identifier,
    qr/\Acom[.]macnperl[.]macpopquickthirdparty[.]hash[a-f0-9]{32}\z/,
    'extension_identifier';
