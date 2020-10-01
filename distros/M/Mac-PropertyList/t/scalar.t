use Test::More tests => 28;

use Mac::PropertyList;

########################################################################
# Test the data bits
my $date = Mac::PropertyList::date->new();
isa_ok( $date, "Mac::PropertyList::date" );

########################################################################
# Test the real bits
my $real = Mac::PropertyList::real->new();
isa_ok( $real, "Mac::PropertyList::real" );

{
my $value = 3.15;
$string = Mac::PropertyList::real->new( $value );
isa_ok( $string, "Mac::PropertyList::real" );
is( $string->value, $value );
is( $string->type, 'real' );
is( $string->write, "<real>$value</real>" );
}

########################################################################
# Test the integer bits
my $integer = Mac::PropertyList::integer->new();
isa_ok( $integer, "Mac::PropertyList::integer" );

{
my $value = 37;
$string = Mac::PropertyList::integer->new( $value );
isa_ok( $string, "Mac::PropertyList::integer" );
is( $string->value, $value );
is( $string->type, 'integer' );
is( $string->write, "<integer>$value</integer>" );
}

########################################################################
# Test the uid bits
my $uid = Mac::PropertyList::uid->new();
isa_ok( $uid, "Mac::PropertyList::uid" );

{
my $value = 37;
$string = Mac::PropertyList::uid->integer( $value );
isa_ok( $string, "Mac::PropertyList::uid" );
is( $string->value, sprintf '%x', $value );
is( $string->type, 'uid' );
# Per plutil, this is the xml1 representation of a UID.
is( $string->write, "<dict>
	<key>CF\$UID</key>
	<integer>$value</integer>
</dict>" );
}

########################################################################
# Test the string bits
my $string = Mac::PropertyList::string->new();
isa_ok( $string, "Mac::PropertyList::string" );

{
my $value = 'Buster';
$string = Mac::PropertyList::string->new( $value );
isa_ok( $string, "Mac::PropertyList::string" );
is( $string->value, $value );
is( $string->type, 'string' );
is( $string->write, "<string>$value</string>" );
}

########################################################################
# Test the data bits
my $data = Mac::PropertyList::data->new();
isa_ok( $data, "Mac::PropertyList::data" );


########################################################################
# Test the boolean bits
my $true = Mac::PropertyList::true->new;
isa_ok( $true, "Mac::PropertyList::true" );
is( $true->value, 'true' );
is( $true->write, '<true/>' );

my $false = Mac::PropertyList::false->new;
isa_ok( $false, "Mac::PropertyList::false" );
is( $false->value, 'false' );
is( $false->write, '<false/>' );


