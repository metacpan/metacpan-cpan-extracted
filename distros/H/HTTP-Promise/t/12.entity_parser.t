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

BEGIN
{
    use ok( 'HTTP::Promise::Parser' );
};

use strict;
use warnings;

my $dir = file( './t/testout' );
bail_out( "No output directory $dir" ) if( !$dir->is_dir || !$dir->can_write );
$_->unlink for( $dir->glob( '[a-z]*' ) );
my $dir_in = file( './t/testin' );
bail_out( "No input directory $dir_in" ) if( !$dir->is_dir || !$dir->can_read );

my $parser = HTTP::Promise::Parser->new( debug => $DEBUG );
$parser->output_dir( $dir );

my $f1 = $dir_in->child( 'multi-nested.msg' );
my $fh = $f1->open( '<' ) || bail_out( $f1->error );
my $ent = $parser->parse( $fh );
diag( "Error parsing file $f1: ", $parser->error ) if( $DEBUG && !defined( $ent ) );
isa_ok( $ent => ['HTTP::Promise::Entity'], 'Parse of nested multipart' );
# $ent->dump_skeleton;
# my $parts = $ent->parts;
# is( -s( "$dir/3d-vise.gif" ), 419, "vise gif size ok" );
# is( -s( "$dir/3d-eye.gif" ) , 357, "3d-eye gif size ok" );
# for $msgno ( 1..4 )
# {
#     ok( -s( "$dir/message-$msgno.dat" ), "message $msgno has a size" );
# }

done_testing();

__END__

