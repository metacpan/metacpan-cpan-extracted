#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use Module::Generic::File qw( cwd file );
    use Scalar::Util;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

BEGIN
{
    use ok( 'HTTP::Promise::Parser' );
};

my $dir = file( './t/testout' );
bail_out( "No output directory $dir" ) if( !$dir->is_dir || !$dir->can_write );
$_->unlink for( $dir->glob( '[a-z]*' ) );

my $parser = HTTP::Promise::Parser->new( debug => $DEBUG );
$parser->output_dir( $dir );

my $data = <<END;
Content-Type: multipart/form-data; boundary="foo"

--foo

--foo

--foo

--foo--
END

SKIP:
{
    my $entity = $parser->parse_data( $data );
    isa_ok( $entity => ['HTTP::Promise::Entity'] );
    diag( "Error parsing data: ", $parser->error ) if( $DEBUG && !defined( $entity ) );
    skip( "Failed to parse data.", 5 ) if( !defined( $entity ) );
    is( $entity->mime_type, 'multipart/form-data' );
    is( $entity->parts->length, 3, 'Got three parts' );
    is( $entity->parts->index(0)->mime_type( 'text/plain' ), 'text/plain', 'with default value' );
    is( $entity->parts->index(0)->mime_type, '' );
    is( $entity->parts->index(1)->mime_type, '' );
    is( $entity->parts->index(2)->mime_type, '' );
};

done_testing();

__END__

