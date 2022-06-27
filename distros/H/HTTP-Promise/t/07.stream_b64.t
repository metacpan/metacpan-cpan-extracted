#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use HTTP::Promise::Stream::Base64;
    use Module::Generic::File qw( file tempfile );
    use Module::Generic::Scalar;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $f = file( __FILE__ )->parent->child( 'testin/mignonne-ronsard.txt' );
my $check = file( __FILE__ )->parent->child( 'testin/mignonne-ronsard.txt.b64' )->load;
my $str = $f->load;
diag( "String is:\n$str" ) if( $DEBUG );
my $s = HTTP::Promise::Stream::Base64->new( debug => $DEBUG );
isa_ok( $s => ['HTTP::Promise::Stream::Base64'] );
my $enc = Module::Generic::Scalar->new;
my $rv = $s->encode( $f => $enc, eol => undef );
diag( "Base64 text is:\n$enc" ) if( $DEBUG );
is( "$enc" => $check );

my $dec = Module::Generic::Scalar->new;
my $dec_io = $dec->open( '>' );
$s->decode( $enc => $dec_io );
is( "$dec" => $str );

done_testing();

__END__

