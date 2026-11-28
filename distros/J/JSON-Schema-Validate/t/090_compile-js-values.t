#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use lib './lib';
use Test::More;
use JSON ();
use File::Temp ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

my( $node ) = grep{ -x "$_/node" } split( /:/, $ENV{PATH} || '' );
plan( skip_all => 'Node.js is not available' ) unless( defined( $node ) );
$node .= '/node';
my $json = JSON->new->allow_nonref->ascii->canonical;
my $run = sub
{
    my( $schema, $opts, @instances ) = @_;
    my $code = JSON::Schema::Validate->new( $schema )->compile_js( $opts );
    my $fh = File::Temp->new( SUFFIX => '.js' );
    binmode( $fh, ':encoding(UTF-8)' );
    print( $fh $code, "\nvar out = [];\n" );
    foreach my $inst ( @instances )
    {
        print( $fh 'out.push(module.exports.validate(JSON.parse(', $json->encode( $json->encode( $inst ) ), ")).length ? 1 : 0);\n" );
    }
    print( $fh "console.log(out.join(','));\n" );
    close( $fh );
    open( my $pipe, '-|', $node, "$fh" ) or die( "Unable to execute Node.js: $!" );
    my $result = do{ local $/; <$pipe> };
    close( $pipe ) or die( "Node.js failed: $?" );
    chomp( $result );
    return( $result );
};
my $schema = { '$defs' => { a => { type => 'integer' } }, allOf => [{ '$ref' => '#/$defs/a', minimum => 2 }, { '$ref' => '#/$defs/a', maximum => 4 }] };
is( $run->( $schema, {}, 1, 2, 5 ), '1,0,1', 'cached references retain their sibling constraints' );
$schema = { '$defs' => { a => { type => 'integer' } }, allOf => [{ '$ref' => '#/$defs/a' }, { not => { '$ref' => '#/$defs/a', type => 'integer', maximum => 4 } }] };
is( $run->( $schema, {}, 5, 2 ), '0,1', 'reference siblings are respected under not' );
$schema = { '$defs' => { a => { type => 'integer' } }, '$ref' => '#/$defs/a', minimum => 2 };
my $opts = { max_errors => 0 };
is( $run->( $schema, $opts, 1, 2 ), '1,0', 'unlimited errors do not skip sibling constraints' );
is_deeply( $opts, { max_errors => 0 }, 'compilation does not modify caller options' );
is( $run->( { '$defs' => { a => { '$anchor' => 'item', type => 'integer' } }, '$ref' => '#item' }, {}, 1, 'x' ), '0,1', 'plain anchor resolves without recursion' );
is( $run->( { '$ref' => '#', type => 'integer' }, {}, 1, 'x' ), '0,1', 'self-reference terminates and checks sibling' );
is( $run->( JSON::false, {}, 1 ), '1', 'false root rejects' );
is( $run->( JSON::true, {}, 1 ), '0', 'true root accepts' );
is( $run->( { enum => [1, JSON::true, undef] }, {}, 1, '1', JSON::true, undef, 'true' ), '0,1,0,0,1', 'enum preserves JSON types' );
is( $run->( { const => { a => [1, JSON::false] } }, {}, { a => [1, JSON::false] }, { a => ['1', JSON::false] } ), '0,1', 'complex const compares JSON values' );
is( $run->( { const => JSON::false }, {}, JSON::false, 'false', 0 ), '0,1,1', 'boolean const preserves type' );
is( $run->( { if => { type => 'integer' }, else => JSON::false }, {}, 1, 'x' ), '0,1', 'else without then generates valid JavaScript' );
is( $run->( { if => JSON::true, then => JSON::false }, {}, 1 ), '1', 'false then schema is not ignored' );
is( $run->( { prefixItems => [{ type => 'string' }], items => JSON::false }, {}, ['x'], ['x', 1] ), '0,1', 'items starts after prefixItems' );
is( $run->( { maxLength => 1 }, {}, '𠮷', '𠮷𠮷' ), '0,1', 'astral characters count as one' );
is( $run->( { properties => { "a\nbar\x{2028}" => { type => 'integer' } } }, {}, { "a\nbar\x{2028}" => 1 }, { "a\nbar\x{2028}" => 'x' } ), '0,1', 'line separators in schema paths do not break JavaScript' );
is( $run->( { contains => { type => 'integer' }, maxContains => 2 }, {}, [], [1], [1,2,3] ), '1,0,1', 'contains defaults to one match with maxContains' );

done_testing();

__END__
