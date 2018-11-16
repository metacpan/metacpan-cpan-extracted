#! perl

use Test2::V0;

use IPC::PrettyPipe::Stream;

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
        new => [ [ '>' => 'output' ] ],
        expected => {
            spec => '>',
            file => 'output'
        }
    },

    {
        desc => '> no file, strict = 0',
        new      => [               { spec => '>', strict => 0 } ],
        expected => { requires_file => 1 }
    },

);


like( dies { new( '>>>' ) }, qr/cannot parse/, "bad spec" );

like( dies { new( '>' ) }, qr/requires a file/, '> no file' );

like( dies { new( '<' ) }, qr/requires a file/, '< no file' );

done_testing;
