# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More tests => 3;

use Mac::PropertyList::XS;

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string> Roscoe</string>
</array>
</plist>
HERE

my $dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe </string>
</dict>
</plist>
HERE

my $nested_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<dict>
		<key>Roscoe</key>
		<integer>1</integer>
		<key>Boolean</key>
		<true/>
	</dict>
</dict>
</plist>
HERE

my $nested_dict_alt =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<dict>
		<key>Boolean</key>
		<true/>
		<key>Roscoe</key>
		<integer>1</integer>
	</dict>
</dict>
</plist>
HERE

foreach my $start ( ( $array, $dict ) )
	{
	my $plist  = Mac::PropertyList::XS::parse_plist( $start );
	my $string = Mac::PropertyList::plist_as_string( $plist );
	is( $string, $start, 'Original and rewritten string match' );
	}

my $plist  = Mac::PropertyList::XS::parse_plist( $nested_dict );
my $string = Mac::PropertyList::plist_as_string( $plist );

print STDERR "\n$string\n" if $ENV{DEBUG};

ok( ($string eq $nested_dict) || ($string eq $nested_dict_alt), "Nested dict" );
