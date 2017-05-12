
#!/usr/bin/perl -w

=head1 NAME

01_basic.t

=head1 DESCRIPTION

test module Device::BlinkStick

=head1 AUTHOR

kevin mulholland, moodfarm@cpan.org

=cut

use v5.10 ;
use strict ;
use warnings ;
use Test::More tests => 2 ;

BEGIN { 
    $ENV{PERL_INLINE_DIRECTORY}= '/tmp' ;

    use_ok('Device::BlinkStick') ;
 }

SKIP: {
    if ( $ENV{AUTHOR_TESTING} ) {

        # these tests need a blink stick to be attached
        subtest 'authors_own' => sub {
            my $bs    = Device::BlinkStick->new() ;
            my $stick = $bs->first() ;
            my $info  = $stick->info() ;
            ok( $info->{serial_number}, "has a serial number" ) ;
            ok( $info->{manufacturer},  "has a manufacturer" ) ;
            ok( $info->{product},       "has a product" ) ;
            ok( $info->{device_name},   "has a infoblock 1" ) ;
            ok( $info->{access_token},  "has a infoblock 2" ) ;

            my ( $r, $g, $b ) = $stick->get_color() ;
            ok( defined $r && defined $g && defined $b, "has a color" ) ;

            my $tok   = $stick->get_access_token() ;
            my $info2 = "test $$" ;
            $stick->set_access_token($info2) ;
            ok( $info2 eq $stick->get_access_token(), "set_access_token" ) ;
            # reset the token
            $stick->set_access_token($tok) ;

            my ( $r1, $g1, $b1 ) = $stick->get_color() ;
            $stick->set_color( 0, 0,   0 ) ;
            $stick->set_color( 0, 255, 0 ) ;
            ( $r, $g, $b ) = $stick->get_color() ;
            # diag "$r-$g-$b" ;
            ok( "$r-$g-$b" eq '0-255-0', "set color 0-255-0" ) ;
            $stick->led( color => 'blue' ) ;
            ( $r, $g, $b ) = $stick->get_color() ;
            ok( "$r-$g-$b" eq '0-0-255', "set color blue" ) ;
            
            # reset the color
            $stick->set_color( $r1, $g1, $b1 ) ;
        } ;
    } else {
        skip "Author testing", 1 ;
    }
}
