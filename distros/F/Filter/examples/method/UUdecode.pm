
package Filter::UUdecode ;

use Filter::Util::Call ;

use strict ;
use warnings ;

our $VERSION = '1.00' ;

sub import
{
    my($self) = @_ ;
    my ($count) = 0 ;

    filter_add( \$count ) ;
}

sub filter
{
    my ($self) = @_ ;
    my ($status) ;

    while (1) {

	return $status 
	    if ($status = filter_read() ) <= 0;

	chomp ;
	++ $$self ;

	# Skip the begin line (if it is there)
	($_ = ''), next if $$self == 1 and /^begin/ ;

	# is this the last line?
	if ($_ eq " " or length $_ <= 1) {
	    $_ = '' ;
	    # If there is an end line, skip it too
            return $status
	        if ($status = filter_read() ) <= 0 ;
            $_ = "\n" if /^end/ ;
	    filter_del() ;
	    return 1 ;
	}

	# uudecode the line
	$_ = unpack("u", $_) ;

	# return the uudecoded data
	return $status ;
    }
}

1 ;
