use strict;
use warnings;
use Test::More tests => 6;
use Hash::Path qw(hash_path);

my $some_array_ref = [qw(1 2 3 4)];

my $other_hash_ref = { key1 => 'some value', key2 => $some_array_ref, };

my $hash = {
    key1 => {
        key2 => {
            key3 => 'key1->key2->key3 value',
            key4 => {
                key5 => {
                    key6 => 'key1->key2->key4->key5->key6 value',
                    key7 => 'other value'
                }
            }
        }
    },
    key1b => { key2b => $other_hash_ref, },
};

is( hash_path( $hash, qw{key1 key2 key3} ), 'key1->key2->key3 value' );
is( hash_path( $hash, qw{key1 key2 key4 key5 key6} ),
    'key1->key2->key4->key5->key6 value' );
is( hash_path( $hash, qw{non existant path} ), undef );
is( hash_path( $hash, qw{key1b key2b} ),       $other_hash_ref );
is( hash_path( $hash, qw{key1b key2b key1} ),  'some value' );
is( hash_path( $hash, qw{key1b key2b key2} ),  $some_array_ref );
