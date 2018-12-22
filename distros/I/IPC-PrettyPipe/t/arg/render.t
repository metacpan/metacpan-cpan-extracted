#! perl

use Test2::V0;
use Test::Lib;

use IPC::PrettyPipe::Arg;
use My::Tests;

sub new { IPC::PrettyPipe::Arg->new( @_ ); }

sub run_test {

    my %args = @_;

    $args{render}  //= [];
    $args{methods} //= [];

    subtest $args{desc} => sub {

        my $arg;
        ok(
            lives {
                $arg = IPC::PrettyPipe::Arg->new( $args{new} );
                run_methods( $arg, @{ $args{methods} } );
            },
            'run_methods'
        );
        is( [ $arg->render ], $args{expect}, 'rendered correctly' );

      }

}



my @tests = (

    {
        desc => 'bool',
        new    => { name => 'a' },
        expect => ['a'],
    },

    {
        desc => 'value',
        new    => { name => 'a', value => 42 },
        expect => [ a    => 42 ],
    },

    {
        desc => 'pfx',
        new  => {
            name  => 'a',
            value => 42,
            pfx   => '--',
        },
        expect => [ '--a' => 42 ],
    },

    {
        desc => 'sep',
        new  => {
            name  => 'a',
            value => 42,
            sep   => '=',
        },
        expect => ['a=42'],
    },

    {
        desc => 'pfx+sep',
        new  => {
            name  => 'a',
            value => 42,
            pfx   => '--',
            sep   => '=',
        },
        expect => ['--a=42'],
    },


);

for my $test ( @tests ) {

    my %args = %$test;
    run_test( %args );

    $args{render} //= [ {} ];

    # now move sep & pfx to render
    $args{render}[0]{$_} = delete $args{new}{$_}
      for grep { exists $args{new}{$_} } qw[ argsep ];

    $args{desc} = 'render ' . $args{desc};
    run_test( %args );

}

done_testing;
