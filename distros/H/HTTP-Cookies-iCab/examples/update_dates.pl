use HTTP::Cookies::Omniweb;
use HTTP::Cookies::Safari;

my $updated_jar = HTTP::Cookies::Safari->new( 
	File => 'safari2.plist',
	);

bless $updated_jar, 'HTTP::Cookies::Omniweb';
$updated_jar->save( 'cookies.xml' );
