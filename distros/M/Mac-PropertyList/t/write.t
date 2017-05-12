use Test::More tests => 8;

use Mac::PropertyList;

my $array =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<string>Mimi</string>
	<string>Roscoe</string>
</array>
</plist>
HERE

my $dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Mimi</key>
	<string>Roscoe</string>
</dict>
</plist>
HERE

my $nested_dict =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

my $array_various =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<array>
	<data>
	RHJpbmsgeW91ciBvdmFsdGluZS4=
	</data>
	<data></data>
	<date>2009-07-11T18:40:29Z</date>
</array>
</plist>
HERE

foreach my $start ( ( $array, $dict ) )
	{
	my $plist  = Mac::PropertyList::parse_plist( $start );
	my $string = Mac::PropertyList::plist_as_string( $plist );
	is( $string, $start, 'Original and rewritten string match' );
	}

my $plist  = Mac::PropertyList::parse_plist( $nested_dict );
my $string = Mac::PropertyList::plist_as_string( $plist );

print STDERR "\n$string\n" if $ENV{DEBUG};

ok( ($string eq $nested_dict) || ($string eq $nested_dict_alt), "Nested dict" );

$plist = Mac::PropertyList::parse_plist( $array_various );
is($plist->[0]->value, 'Drink your ovaltine.', 'data decode');
is($plist->[1]->value, '', 'empty data');
is($plist->[2]->value, '2009-07-11T18:40:29Z', 'date value');
$string = Mac::PropertyList::plist_as_string( $plist );
$string = &canonicalize_data_elts($string);
is($string, &canonicalize_data_elts($array_various),
   'Original and rewritten string match');
is_deeply($plist, Mac::PropertyList::parse_plist($string),
   "canonicalization doesn't break test");


sub canonicalize_data_elts {
    my($string) = @_;
    
    # Whitespace is ignored inside <data>
    $string =~ s#(\<data\>)([a-zA-Z0-9_+=\s]+)(\</data\>)# my($b64) = $2; $b64 =~ y/a-zA-Z0-9_+=//cd; $1.$b64.$3; #gem;
    $string;
}
