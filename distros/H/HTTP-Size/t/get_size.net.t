package HTTP::Size;
use strict;
use vars qw($INVALID_URL $ERROR $HTTP_STATUS);
use Test::More 'no_plan';

use_ok( 'HTTP::Size' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my $size = get_size('foo');
diag( "String 'foo' got back size [$size]" ) if defined $size;
ok( ! defined $size, "String 'foo' is not a valid absolute URI\n" );
is( $ERROR, $INVALID_URL, "get_size('foo') returned wrong error type" );

$size = get_size();
diag( "Empty string got back size [$size]" ) if defined $size;
ok( ! defined $size, "Empty string is not a valid absolute URI\n" );
is( $ERROR, $INVALID_URL, "get_size() returned wrong error type" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

SKIP: {
require LWP::Simple;
my $connected = LWP::Simple::get( 'http://www.google.com' ) ||
	LWP::Simple::get( 'http://www.yahoo.com' );

skip "I can't continue unless I'm connected to the net", 10 unless $connected;

require URI::file;
my $uri = URI::file->new_abs("t/test.html");

my @array = (
	[ $uri->canonical,                                          qw( 263 21879 2) ],
	[ qw( http://www.pair.com/~comdog/for/http-size/title.png      5398  5398 1) ],
	[ qw( http://www.pair.com/~comdog/for/http-size/size.txt         42    42 1) ],
	);

{
my $ftp_url = 'ftp://ftp.cpan.org/pub/CPAN/ROADMAP.html';
my $length = length(  LWP::Simple::get( $ftp_url) );
last unless $length;
diag( "Remote FTP URL has size $length" );

push @array, [ $ftp_url, $length, $length, 1 ];
}

foreach my $element ( @array )
	{		
	my $url          = $element->[0];
	my $true_size    = $element->[1];
	my $true_total   = $element->[2];
	my $image_count  = $element->[3];

	my $size = get_size($url);

	SKIP: {
		skip "I couldn't fetch $url", 
			4 + $image_count * 2
			unless $HTTP_STATUS == 200;

		ok( $size > 0, "Size is non-zero" );
		
		diag( "$url returned wrong length [$size] expected [$true_size].\n" .
			"Maybe someone changed the resource and it has a new size." ) 
			unless is( $size, $true_size, 
				"Message body for [$url] size is the right size" );		
			
		my( $total, $images ) = get_sizes( $url );
		$total ||= 0;
			
		diag( "[$url] returned wrong length",
			"Maybe someone changed the resource and it has a new size." )
			unless is( $total, $true_total, 
				"Total size for [$url] is right" );
		
		diag( "[$url] had the wrong number of images!" )
			unless is( $image_count, keys %$images, "Image count is right" );
					
		foreach my $key ( keys %$images )
			{
			local $^W = 0;
			diag( "I should be able to fetch [$url]\n", 
				"error: [$ERROR] ", "HTTP status: [$HTTP_STATUS]" )
				unless ok( $images->{$key}{size} > 0, "Image size is not zero" );
			diag( "[$url] returned unexpected HTTP status" )
				unless is( $images->{$key}{HTTP_STATUS}, 200, "HTTP status is OK" );
			}
		}
		
	}

}

