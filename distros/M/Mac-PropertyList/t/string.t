use Test::More tests => 3;

use Mac::PropertyList;

########################################################################
# Test the string bits
subtest empty_object => sub {
	my $string = Mac::PropertyList::string->new();
	isa_ok( $string, "Mac::PropertyList::string", 'Make empty object' );
	};

subtest parse => sub {
	my $plist = <<"HERE";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<string>Mimi</string>
</plist>
HERE

	$plist = Mac::PropertyList::parse_plist( $plist );
	isa_ok( $plist, "Mac::PropertyList::string", "Make object from plist string" );
	};

subtest create => sub {
	Mac::PropertyList->import( 'create_from_string' );
	ok( defined &create_from_string );

	my $plist = create_from_string( 'Roscoe' );

	like $plist, qr|<string>Roscoe</string>|, 'Has the string node';
	};
