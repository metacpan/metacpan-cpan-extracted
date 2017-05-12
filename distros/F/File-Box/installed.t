use File::Box;
use IO::Extended qw(:all);

my $box = File::Box->new( env => { SOURCE => '/home/path/src' } );

my $file = $box->request( 'success.txt' );

open( FILE, $file ) or die "File::Box not working: $!"; 

while( <FILE> )
{
	print;
}



