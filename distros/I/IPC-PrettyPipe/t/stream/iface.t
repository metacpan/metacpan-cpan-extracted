#! perl

use strict;
use warnings;

use IPC::PrettyPipe::Stream;

use Test::More;
use Test::Exception;

use Test::Lib;
use My::Tests;

sub new { IPC::PrettyPipe::Stream->new( @_ ) }

test_attr(
    \&new,

    {
        desc     => 'just a spec',
        new      => ['2>&3'],
        expected => { spec => '2>&3' }
    },

    {
        desc => 'spec+file',
        new      => [ [ '>' => 'output' ] ],
        expected => {
            spec   => '>',
            file => 'output'
        }
    },

    {
        desc => '> no file, strict = 0',
        new      => [
                      { spec => '>', strict => 0 }
                    ],
        expected => { requires_file => 1 }
    },

);


throws_ok {

    new( '>>>' );

}
qr/cannot parse/, "bad spec";

throws_ok {

    new( '>' );

}
qr/requires a file/, '> no file';


throws_ok {

    new( '<' );

}
qr/requires a file/, '< no file';

done_testing;
