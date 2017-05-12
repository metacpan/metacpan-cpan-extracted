use Test::More tests => 1;
use Mac::PropertyList::XS qw(parse_plist_file);

my $result = parse_plist_file(\*DATA);
ok(defined($result), "interim");

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
	<key>Buster</key>
	<string>Juliet</string>
</dict>
</plist>


