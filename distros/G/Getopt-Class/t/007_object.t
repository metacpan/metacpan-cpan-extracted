# -*- perl -*-
# t/007_object.t - Checks access to option values as methods
use Test::More qw( no_plan );
use strict;
use warnings;
use lib './lib';

BEGIN { use_ok( 'Getopt::Class' ) || BAIL_OUT( "Unable to load Getopt::Class" ); }

our( $dict, $DEBUG, $VERBOSE, $VERSION, $HELP, $MAN );
our $_DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

require( './t/dictionary.pl' );

my $opt = Getopt::Class->new({
    dictionary => $dict,
    debug => $_DEBUG,
}) || BAIL_OUT( Getopt::Class->error, "\n" );

{
    local @ARGV = qw( --debug 3 --dry-run --name Bob --created 2020-04-12T07:30:10 --langs en ja --define transaction_id=123 --define customer_id=456 --age 30 );
    my $obj = $opt->exec || diag( "Error: " . $opt->error );
    diag( "\$obj is $obj (", overload::StrVal( $obj ), ")" ) if( $_DEBUG );
    isa_ok( $obj, 'Getopt::Class::Values', 'Returning a Getopt::Class::Values' );
    my $rv = $obj->debug;
    diag( "\$obj->debug returned '", ( $rv // 'undef' ), "' (", overload::StrVal( $rv ), ")" ) if( $_DEBUG );
    diag( "debug value is $obj->{debug}" ) if( $_DEBUG );
    is( $obj->debug, 3, 'Checking option value for scalar' );
    isa_ok( $obj->debug, 'Module::Generic::Scalar', 'Class for scalar' );
    isa_ok( $obj->dry_run, 'Module::Generic::Boolean', 'Class for boolean' );
    isa_ok( $obj->created, 'DateTime', 'Class for datetime' );
    isa_ok( $obj->age, 'Module::Generic::Number', 'Class for numbers' );
    is( $obj->name->length, 3, 'Accessing scalar method' );
    isa_ok( $obj->langs, 'Module::Generic::Array', 'Class for array' );
    is( $obj->langs->length, 2, 'Accessing array length' );
    is( $obj->langs->join( ',' ), 'en,ja', 'Accessing array join' );
    isa_ok( $obj->define, 'Getopt::Class::Define', 'Dynamic class for hash' );
    is( $obj->define->transaction_id, 123, 'Accessing hash property as method' );
    is( $obj->define->transaction_id->length, 3, 'Accessing hash property recursively' );
}
