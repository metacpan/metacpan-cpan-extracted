package t::Test;

use strict;
use warnings;

use File::Temp qw/ tempdir /;
use File::Spec::Functions qw/ canonpath catfile catdir /;

my $base64;
sub base64 {
    return $base64 ||= canonpath '/usr/bin/base64';
}

sub data {
    my $base64 = base64;
    my $binary1source = canonpath 't/assets/binary1.base64';
    my $binary2source = canonpath 't/assets/binary2.base64';
    my $binarydiffsource = canonpath 't/assets/binarydiff.base64';
    my $dir = tempdir( CLEANUP => 1 );
    my $binary1 = catfile( $dir, 'binary1' );
    my $binary2 = catfile( $dir, 'binary2' );
    my $binarydiff = catfile( $dir, 'binarydiff' );
    
    system( "$base64 -d $binary1source > $binary1" );
    system( "$base64 -d $binary2source > $binary2" );
    system( "$base64 -d $binarydiffsource > $binarydiff" );

    my @data = map {
        open( my $handle, $_ ) or die $!;
        sysread( $handle, my $data, 10000 ) or die $!;
        close $handle;
        $data;
    } ( $binary1, $binary2, $binarydiff );

    return ( binary1 => $data[0], binary2 => $data[1], binarydiff => $data[2] );
}

1;
