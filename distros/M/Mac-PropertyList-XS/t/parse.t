# Stolen from Mac::PropertyList (by comdog) for use in Mac::PropertyList::XS (by kulp)

use Test::More tests => 24;

use Mac::PropertyList::XS;

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

my $string1_0 =<<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>This is it</string>
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

########################################################################
my $plist = Mac::PropertyList::XS::parse_plist( $array );

isa_ok( $plist, 'Mac::PropertyList::array' );
is(     $plist->type, 'array', 'Item is an array type' );
isa_ok( $plist->value, 'Mac::PropertyList::array' );

{
my @elements = @{ $plist->value };
isa_ok( $elements[0], 'Mac::PropertyList::string' );
isa_ok( $elements[1], 'Mac::PropertyList::string' );
is( $elements[0]->value, 'Mimi',   'Mimi string is right'   ); 
is( $elements[1]->value, 'Roscoe', 'Roscoe string is right' );
}


########################################################################
$plist = Mac::PropertyList::XS::parse_plist( $dict );
isa_ok( $plist, 'Mac::PropertyList::dict' );
is( $plist->type, 'dict', 'item is a dict type'       );
isa_ok( $plist->value, 'Mac::PropertyList::dict' );

{
my $hash = $plist->value;
ok( exists $hash->{Mimi},           'Mimi key exists for dict'         );
isa_ok( $hash->{Mimi}, 'Mac::PropertyList::string' );
is( $hash->{Mimi}->value, 'Roscoe', 'Mimi string has right value'      );
}

########################################################################
foreach my $string ( ( $string1_0 ) )
	{
	my $plist = Mac::PropertyList::XS::parse_plist( $string );

	isa_ok( $plist, 'Mac::PropertyList::string' );
	is( $plist->type, 'string',      'type key has right value for string' );
	is( $plist->value, 'This is it', 'value is right for string'           );
	}
	
$plist = Mac::PropertyList::XS::parse_plist( $nested_dict );

isa_ok( $plist, 'Mac::PropertyList::dict'            );
is( $plist->type, 'dict', 'type key has right value for nested dict' );
isa_ok( $plist->value, 'HASH'   );
		
########################################################################
my $hash = $plist->value->{Mimi};

isa_ok( $plist, 'Mac::PropertyList::dict'                     );
is( $plist->type, 'dict', 'item is a dict type'                       );
isa_ok( $plist->value, 'Mac::PropertyList::dict'            );
is( $hash->value->{Roscoe}->value, 1,       'Roscoe string has right value'   );
is( "".$hash->value->{Boolean}->value, 'true', 'Boolean string has right value'  );
