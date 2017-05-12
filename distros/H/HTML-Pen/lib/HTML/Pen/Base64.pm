use MIME::Base64 ;

package Pen ;

sub base64 {
	return encode( MIME::Base64::encode_base64( $_[0] ) ) ;
	}

1
