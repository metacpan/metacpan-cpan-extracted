#! perl

use strict;
use warnings;

use IPC::PrettyPipe::Arg;

use Test::More;
use Test::Exception;

use Test::Lib;
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

throws_ok {

    my $arg = new( value => 'b' );

}
qr/missing/i, 'value, no name';

for my $test (
    [ [], 'array' ],
    [ {}, 'hash' ],
    [ \'a',  'scalar ref' ],
    [ undef, 'undef' ],
  )
{

    dies_ok { new( name => $test->[0] ) } "bad name: $test->[1]";
    dies_ok { new( name => 'a', value => $test->[0] ) } "bad value: $test->[1]";
}

done_testing;
