#! perl

use Test2::V0;
use Test::Lib;

use IPC::PrettyPipe::Arg;

use My::Tests;

sub new { IPC::PrettyPipe::Arg->new( @_ ) }

my @tests = (

    {
        desc => 'name',
        new      => [ name => 'a' ],
        expected => {
            name      => 'a',
            has_value => !!0
        }
    },


    {
        desc => 'name + value',
        new      => [ name => 'a', value => 'b' ],
        expected => {
            name  => 'a',
            value => 'b'
        },
    },

    # alternate construction syntax
    {
        desc     => 'alt: name',
        new      => ['a'],
        expected => { name => 'a' },
    },

    {
        desc => 'alt: [ name, value ] ',
        new => [ [ 'a', 'b' ] ],
        expected => {
            name  => 'a',
            value => 'b'
        },
    },

);


test_attr( \&new, \@tests );

# missing/bad attributes

like(
    dies {
        my $arg = new( value => 'b' );
    },
    qr/missing/i,
    'value, no name'
);

for my $test (
    [ [], 'array' ],
    [ {}, 'hash' ],
    [ \'a',  'scalar ref' ],
    [ undef, 'undef' ],
  )
{
    like(
        dies { new( name => $test->[0] ) },
        qr/did not pass/,
        "bad name: $test->[1]"
    );
    like(
        dies { new( name => 'a', value => $test->[0] ) },
        qr/did not pass/,
        "bad value: $test->[1]"
    );
}

done_testing;
