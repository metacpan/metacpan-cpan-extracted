# -*- perl -*-

# t/001_basic.t - perform basic tests

use Test::More qw( no_plan );
use strict;
use warnings;
use Scalar::Util ();

BEGIN { use_ok( 'Getopt::Class' ) || BAIL_OUT( "Unable to load Getopt::Class" ); }

our( $dict, $DEBUG, $VERBOSE, $VERSION, $HELP, $MAN );

require( './t/dictionary.pl' );

my $opt = Getopt::Class->new({
    dictionary => $dict,
    debug => 0,
}) || BAIL_OUT( Getopt::Class->error, "\n" );
# $opt->message( $opt->dumper( $dict ) ); exit;
# my $params = $opt->parameters;
# my $options = $opt->options;
# $opt->message( $opt->dumper( $options ) );
# $opt->message( $opt->dumper( $params ) ); exit;
isa_ok( $opt, 'Getopt::Class' );

{
    local @ARGV = qw( --debug 3 --dry-run --name Bob --created 2020-04-12T07:30:10 --langs en ja );
    my $opts = $opt->exec || diag( "Error: " . $opt->error );
    ok( defined( $opts ), 'No Getopt::Long error' );
    is( Scalar::Util::reftype( $opts ), 'HASH', 'Expecting a hash reference' );
    is( $opts->{dry_run}, 1, 'Boolean option enabled' );
    is( $opts->{debug}, 3, 'Scalar reference of integer set' );
    is( $opts->{name}, 'Bob', 'String assignment' );
    isa_ok( $opts->{created}, 'DateTime', 'DateTime object set' );
    SKIP:
    {
        if( !ref( $opts->{created} ) || ref( $opts->{created} ) ne 'DateTime' )
        {
            skip( 'DateTime object failed', 2 );
        }
        my $dt = $opts->{created};
        is( $dt->year, 2020, 'DateTime year property' );
        is( $dt->iso8601, '2020-04-12T07:30:10', 'DateTime value' );
    };
    is( Scalar::Util::reftype( $opts->{langs} ), 'ARRAY', 'Array type' );
    is( scalar( @{$opts->{langs}} ), 2, 'Array size' );
    is( join( ',', @{$opts->{langs}} ), 'en,ja', 'Array values' );
}

my $props = $opt->class_properties( 'product' );
is( Scalar::Util::reftype( $props ), 'ARRAY', 'Class property as array reference' );
is( scalar( @$props ), 4, 'Number of class properties' );
my $peopel_props = $opt->class_properties( 'person' );
is( scalar( @$peopel_props ), 4, 'Number of class properties (bis)' );

