package Filter::Decompress ;
# For usage see examples/filtdef
 
use Filter::Util::Call ;
use Compress::Zlib ;
use Carp ;

use strict ;
use warnings ;

our $VERSION = '1.02' ;

sub import
{
    my ($self) = @_ ;

    # Initialise an inflation stream.
    my $x = inflateInit()
        or croak "Internal Error inflateInit" ;
    filter_add(
        sub 
        { 
            my ($status, $err) ;
            if (($status = filter_read()) >0) {
                ($_, $err) = $x->inflate($_) ;
                return -1 unless $err == Z_OK or $err == Z_STREAM_END ;
            }
            $status ;
        })
}

1 ;
__END__
