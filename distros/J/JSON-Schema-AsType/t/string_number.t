use strict;
use warnings;

use Test::More tests => 2;

use JSON::Schema::AsType;


subtest 'strict' => sub {
    for ( 3,4 ) {
        local $JSON::Schema::AsType::strict_string = 1;
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( 123 ), "v$_ - number" );

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( 123 ), "v$_ - number" );

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( "1" ), "v$_ - string" );

        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( "1" ), "v$_ - string" );

        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( undef ), "v$_ - undef is not number" );
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( undef ), "v$_ - undef is not string" );
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( [] ), "v$_ - ref is not number" );
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( [] ), "v$_ - ref is not string" );
    }
};

subtest 'lax' => sub {
    for ( 3,4 ) {
        local $JSON::Schema::AsType::strict_string = 0;

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( "123" ), "v$_ - string" );

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( 123 ), "v$_ - number" );

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( "1" ), "v$_ - string" );

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( 123 ), "v$_ - number" );

        ok( JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( "1" ), "v$_ - number" );

        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( undef ), "v$_ - undef is not number" );
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( undef ), "v$_ - undef is not string" );
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'number' },
        )->check( [] ), "v$_ - ref is not number" );
        ok( !JSON::Schema::AsType->new(
            draft_version => $_,
            schema => { type => 'string' },
        )->check( [] ), "v$_ - ref is not string" );
    }
}
