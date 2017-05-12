use strict;

use Test::More tests => 4;

use Mac::PropertyList::XS;

########################################################################
my $bad =<<HERE;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<bad version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
	<key>Buster</key>
	<string>Juliet</string>
</dict>
</bad>
HERE

my $bad2 =<<HERE;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<bad>
	<key>Mimi</key>
	<string>Roscoe</string>
	<key>Buster</key>
	<string>Juliet</string>
</bad>
</plist>
HERE

my $bad3 =<<HERE;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>
        <key>Buster</key>
    </key>
	<string>Juliet</string>
</dict>
</plist>
HERE

my $bad4 =<<HERE;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>
        <string>Buster</string>
    </key>
	<string>Juliet</string>
</dict>
</plist>
HERE

my $plist;
eval { $plist = Mac::PropertyList::XS::parse_plist( $bad ); };
ok($@, "parsing bad plist top-level croaks as expected");

eval { $plist = Mac::PropertyList::XS::parse_plist( $bad2 ); };
ok($@, "parsing bad plist second-level croaks as expected");

eval { $plist = Mac::PropertyList::XS::parse_plist( $bad3 ); };
ok($@, "parsing bad plist (nested key) croaks as expected");

eval { $plist = Mac::PropertyList::XS::parse_plist( $bad4 ); };
ok($@, "parsing bad plist (<string/> inside <key/>) croaks as expected");

