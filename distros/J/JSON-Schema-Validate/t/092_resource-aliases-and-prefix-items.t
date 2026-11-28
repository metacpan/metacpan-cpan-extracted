#!/usr/bin/env perl
use strict;
use warnings;
use lib './lib';
use Test::More;
use JSON ();
use File::Temp ();

BEGIN
{
    use_ok( 'JSON::Schema::Validate' ) || BAIL_OUT( "Unable to load JSON::Schema::Validate" );
};

for my $compile (0, 1)
{
    subtest "compile=$compile" => sub
    {
        my $canonical = 'https://example.test/canonical';
        my $a = 'https://example.test/a';
        my $b = 'https://example.test/b';
        my $document =
        {
            '$id' => $canonical,
            '$defs' => { value => { '$anchor' => 'value', type => 'integer', minimum => 2 } },
            '$ref' => '#value',
        };
        my $schema = { allOf => [{ '$ref' => $a }, { '$ref' => "$b#value" }, { '$ref' => $canonical }] };
        my $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        my @uris;
        $js->set_resolver( sub
        {
            push( @uris, $_[0] );
            return( $document );
        });
        ok( $js->validate(2), 'identical external schema can have several retrieval URIs' ) or diag( $js->error );
        is_deeply( \@uris, [$a, "$b#value"], 'canonical resource is reused after retrieval through aliases' );
        ok( !$js->validate(1), 'alias does not bypass numeric constraint' );
        ok( !$js->validate('x'), 'alias does not bypass type constraint' );

        $js->set_resolver( sub
        {
            return( $_[0] eq $a ? $document : { '$id' => $canonical, type => 'string' } );
        });
        ok( !$js->validate(2), 'different schemas claiming the same canonical identifier are rejected' );
        like( $js->error . '', qr/conflicting schema resource/, 'conflict is reported explicitly' );

        $js->set_resolver( sub
        {
            return( $document ) if( $_[0] eq $a );
            my $invalid = { '$id' => $canonical };
            $invalid->{not} = $invalid;
            return( $invalid );
        });
        my $valid = eval{ $js->validate(2) };
        ok( !$valid && !$@, 'non-JSON resolver output is rejected without throwing' );

        $schema = { '$ref' => $a };
        $js = JSON::Schema::Validate->new( $schema, compile => $compile );
        $js->set_resolver( sub{ { '$id' => $canonical, '$defs' => { embedded => { '$id' => $a, type => 'integer' } } } } );
        ok( !$js->validate(2), 'retrieval URI cannot silently replace another embedded resource' );
    };
}

subtest 'Generated JavaScript' => sub
{
    my( $node ) = grep{ -x "$_/node" } split( /:/, $ENV{PATH} || '' );
    plan( skip_all => 'Node.js is not available' ) unless( defined( $node ) );
    $node .= '/node';
    my $json = JSON->new->allow_nonref(1)->ascii(1);
    my $run = sub
    {
        my( $schema, @instances ) = @_;
        my $code = JSON::Schema::Validate->new( $schema )->compile_js( ecma => 5 );
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
    my $schema = { prefixItems => [{ type => 'string' }], items => { type => 'integer' } };
    is( $run->( $schema, ['x', 1], [JSON::true, 1], [1, 1], ['x', 'x'], [], ['x'] ), '0,1,1,1,0,0', 'tuple position and trailing items use separate constraints' );
    is( $run->( { prefixItems => [JSON::false] }, [], [1] ), '0,1', 'false tuple schema is enforced without items' );
    is( $run->( { prefixItems => [{ type => 'integer' }, { type => 'string' }], items => JSON::false }, [], [1], [1, 'x'], [1, 2], [1, 'x', 3] ), '0,0,0,1,1', 'partial tuples and forbidden trailing items' );
    $schema = { '$defs' => { x => { type => 'integer' } }, prefixItems => [{ '$ref' => '#/$defs/x', minimum => 2 }, { '$ref' => '#/$defs/x', maximum => 4 }] };
    is( $run->( $schema, [2, 4], [1, 4], [2, 5] ), '0,1,1', 'tuple references retain their sibling constraints' );
};

done_testing();

__END__
