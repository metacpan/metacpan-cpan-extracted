#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

use ok( 'HTTP::Promise::Body::Form' );
use utf8;

my @tests = (
    [ 'a;b', => { 'a' => undef, 'b'  => undef } ],
    [ 'a;b;a' => { 'a' => [ undef, undef ], 'b'  => undef } ],
    [ '%20a%20=%201%20' => { ' a ' => ' 1 ' } ],
    [ 'name=John+Doe+&foo=bar&foo=baz&foo=' => { name => 'John Doe ', foo => ['bar', 'baz', ''] } ],
    [ 'einstein=e%3Dmc2' => { einstein => 'e=mc2' } ],
);

foreach my $test ( @tests )
{
    my( $str, $check ) = @$test;
    my $f = HTTP::Promise::Body::Form->new( $str );
    diag( "Error creating a new form object with '$str': ", HTTP::Promise::Body::Form->error ) if( $DEBUG && !defined( $f ) );
    is( $f, $check, $str );
}

@tests = (
    [{ a => 'a1', b => [qw( b1 b2 )], c => 'foo ', tengu => '天狗' } => 'a=a1&b=b1&b=b2&c=foo+&tengu=%E5%A4%A9%E7%8B%97' ],
);

foreach my $test ( @tests )
{
    my( $hash, $check ) = @$test;
    my $f = HTTP::Promise::Body::Form->new( $hash );
    diag( "Error creating a new form object with '$hash': ", HTTP::Promise::Body::Form->error ) if( $DEBUG && !defined( $f ) );
    my $decoded = $f->as_string;
    diag( "Error creating a string representation: ", $f->error ) if( $DEBUG && !defined( $decoded ) );
    is( $decoded => $check, $check );
}

my $f = HTTP::Promise::Body::Form->new;
my $encoded = $f->encode( { tengu => '天狗' } );
diag( "Error encoding non-ascii word: ", $f->error ) if( $DEBUG && !defined( $encoded ) );
is( $encoded => 'tengu=%E5%A4%A9%E7%8B%97' );
is( $f->encode_string( '天狗' ), '%E5%A4%A9%E7%8B%97' );
is( $f->decode_string( '%E5%A4%A9%E7%8B%97' ) => '天狗' );

done_testing();

__END__

