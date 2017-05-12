package
  Include ;
 
use Filter::Util::Call ;
use IO::File ;
use Carp ;
 
sub import
{
    my ($self) = shift ;
    my ($filename) = shift ;
    my $fh = new IO::File "<$filename" 
	or croak "Cannot open file '$filename': $!" ;

    my $first_time = 1 ;
    my ($orig_filename, $orig_line) = (caller)[1,2] ;
    ++ $orig_line ;

    filter_add(
	sub 
	{
	    $_ = <$fh> ;

	    if ($first_time) {
	        $_ = "#line 1 $filename\n$_"  ;
	        $first_time = 0 ;
	    }

	    if ($fh->eof) {
	        $fh->close ;
		$_ .= "#line $orig_line $orig_filename\n" ;
	        filter_del() ;
	    }
	    1 ;
	}) 
}
 
1 ;

