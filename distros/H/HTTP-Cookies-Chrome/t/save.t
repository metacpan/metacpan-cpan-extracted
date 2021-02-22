use Test::More 'no_plan';

use File::Spec::Functions;

my $class = 'HTTP::Cookies::Chrome';
use_ok( $class );

my $file = catfile( qw( test-corpus cookies.db ) );
my $new_file = "$file.save";
END { unlink $new_file };

my $password = '1fFTtVFyMq/J03CMJvPLDg==';

my $jar = $class->new(
	chrome_safe_storage_password => $password,
	file => $file
	);
isa_ok( $jar, $class );
can_ok( $jar, 'save' );

$jar->save( $new_file );

my $jar2 = $class->new(
	chrome_safe_storage_password => $password,
	file => $new_file
	);
isa_ok( $jar2, $class );

#is_deeply( $jar, $jar2 );



