use strict;
use warnings;

use Test::More;

use Devel::Hide 'Hash::Util::FieldHash';
use ok 'Hash::Util::FieldHash::Compat' => qw(fieldhash idhash register id id_2obj idhashes fieldhashes);

{
    my %hash = (
        foo   => 'bar',
        gorch => 'baz',
    );

    fieldhash %hash;

    is_deeply( \%hash, { foo => 'bar', gorch => 'baz' }, 'setting fieldhash retains values' );

    my $obj = bless {}, 'blah';

    $hash{$obj} = 'oink';

    is( scalar(keys %hash), 3, 'three keys now' );
    is( scalar(grep { ref } keys %hash), 0, 'no refs in the keys' );

    ok( !ref(id($obj)), 'id($obj) returns a nonref' );

    ok( exists($hash{$obj}), 'key by ref' );
    ok( exists($hash{id($obj)}), 'key by ref' );
    is( $hash{$obj}, $hash{id($obj)}, '$hash{$obj} eq $hash{id($obj)}' );

    undef $obj;

    is( scalar(keys %hash), 2, '$obj key disappeared' );

    my $destroyed = 0;
    sub zot::DESTROY { $destroyed++ };

    $obj = bless {}, "blah";

    $hash{$obj} = bless {}, "zot";

    is( $destroyed, 0, "no value destructions yet" );
    is( scalar(keys %hash), 3, "three keys" );

    undef $obj;

    is( $destroyed, 1, "one value destroyed" );
    is( scalar(keys %hash), 2, "two keys in hash" );
}

{

    idhash my %id_hash;

    my $obj = bless {}, "blah";

    $id_hash{$obj} = "zoink";

    is( scalar(keys %id_hash), 1, "one key in the hash" );
    is_deeply([ keys %id_hash ], [ id($obj) ], "key is ID" );
    ok( exists($id_hash{$obj}), 'key by ref' );
    ok( exists($id_hash{id($obj)}), 'key by ref' );
    is( $id_hash{$obj}, $id_hash{id($obj)}, '$hash{$obj} eq $hash{id($obj)}' );

}

{
    my %hash;

    my $obj_1 = bless {}, "blah";
    my $obj_2 = bless {}, "blah";

    $hash{id($obj_1)} = "first";
    $hash{id($obj_2)} = "second";

    is_deeply([ sort keys %hash ], [ sort map { id($_) } $obj_1, $obj_2 ], "keys" );

    is( id_2obj(id($obj_1)), undef, "can't id_2obj yet" );
    is( id_2obj(id($obj_2)), undef, "can't id_2obj yet" );

    register($obj_1, \%hash);

    is( id_2obj(id($obj_1)), $obj_1, "id_2obj on registered object" );
    is( id_2obj(id($obj_2)), undef, "can't id_2obj on unregistered object" );

    undef $obj_1;
    undef $obj_2;

    TODO: {
        local $TODO;
        $TODO = 'newer perls do not do this well' if $] >= '5.009003';
        is( scalar(keys %hash), 1, "one key left" );
        is_deeply([ values %hash ], [qw(second)], "second object remained" );
    }
}

{
    my @id_hashes = idhashes({ foo => "bar" }, { gorch => "baz" });
    my @field_hashes = idhashes({ foo => "bar" }, { gorch => "baz" });

    is_deeply($_, [{ foo => "bar" }, { gorch => "baz" }], "plural form") for \@id_hashes, \@field_hashes;
}

done_testing;
