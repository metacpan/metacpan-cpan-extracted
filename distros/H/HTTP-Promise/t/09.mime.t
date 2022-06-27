#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::MIME' );
};

my $m = HTTP::Promise::MIME->new;
isa_ok( $m => [qw( HTTP::Promise::MIME )] );
is( $m->types->length, 767, 'mime types inline' );

my $f = file( __FILE__ )->parent->child( 'mime.types' );
my $m2 = HTTP::Promise::MIME->new( $f );
isa_ok( $m2 => [qw( HTTP::Promise::MIME )] );
is( $m2->types->length, 767, 'mime types from separate file' );

is( $m->suffix( 'text/plain' ) => 'txt', 'suffix from mime type' );

done_testing();

__END__

