#! perl

use Test2::V0;
use Iterator::Flex::Common 'izip';
use Data::Dump 'pp';

use experimental 'declared_refs';


## no critic (DiamondDefaultAssignment)

subtest truncate => sub {

    my @a = ( 0,  10, 20 );
    my @b = ( 30, 40, 50, 60 );
    my @c = ( 70, 80, 90 );


    my @exp_arrayref = ( [ 0, 30, 70 ], [ 10, 40, 80 ], [ 20, 50, 90 ], );

    my @exp_hashref
      = ( { a => 0, b => 30, c => 70 }, { a => 10, b => 40, c => 80 }, { a => 20, b => 50, c => 90 }, );
    subtest 'array' => sub {

        my $iter = izip \@a, \@b, \@c;

        is( $iter->drain, \@exp_arrayref, 'first' );
        $iter->reset;
        is( $iter->drain, \@exp_arrayref, 'reset' );
    };

    subtest 'hashref' => sub {

        my $iter = izip a => \@a, b => \@b, c => \@c;

        is( $iter->drain, \@exp_hashref, 'first' );
        $iter->reset;
        is( $iter->drain, \@exp_hashref, 'reset' );
    };
};

subtest throw => sub {

    my @a = ( 0,  10, 20 );
    my @b = ( 30, 40, 50, 60 );
    my @c = ( 70, 80, 90 );


    my @exp_arrayref = ( [ 0, 30, 70 ], [ 10, 40, 80 ], [ 20, 50, 90 ], );

    my @exp_hashref
      = ( { a => 0, b => 30, c => 70 }, { a => 10, b => 40, c => 80 }, { a => 20, b => 50, c => 90 }, );
    subtest 'array' => sub {

        my $iter = izip \@a, \@b, \@c, { on_exhaustion => 'throw' };

        my @got;
        isa_ok(
            my $err = dies {
                push @got, $_ while <$iter>;
            },
            ['Iterator::Flex::Failure::Truncated'],
            'throws'
        );

        is( $err->msg, [ 0, 2 ], 'truncated iterators' )
          or diag pp $err->msg;

        is( \@got, \@exp_arrayref, 'results' );

    };

    subtest 'hashref' => sub {

        my $iter = izip
          a => \@a,
          b => \@b,
          c => \@c,
          { on_exhaustion => 'throw' };

        my @got;
        isa_ok( my $err = dies { push @got, $_ while <$iter> },
            ['Iterator::Flex::Failure::Truncated'], 'throws' );

        is( $err->msg, [ 'a', 'c' ], 'truncated iterators' );

        is( \@got, \@exp_hashref, 'results' );

    };
};

subtest insert => sub {

    subtest 'array' => sub {

        subtest 'no truncations' => sub {

            my @a = ( 0,  10, 20 );
            my @b = ( 30, 40, 50 );
            my @c = ( 70, 80, 90 );

            my @exp_arrayref = ( [ 0, 30, 70 ], [ 10, 40, 80 ], [ 20, 50, 90 ] );

            my $iter = izip \@a, \@b, \@c,
              {
                on_exhaustion => {
                    0 => '100',
                    2 => '200'
                },
              };

            my $got;
            ok( lives { $got = $iter->drain }, 'iterate' );

            is( $got, \@exp_arrayref, 'results' )
              or diag pp $got;
        };

        subtest 'no effective truncations' => sub {

            my @a = ( 0,  10, 20 );
            my @b = ( 30, 40, 50, 60 );
            my @c = ( 70, 80, 90 );

            my @exp_arrayref = ( [ 0, 30, 70 ], [ 10, 40, 80 ], [ 20, 50, 90 ], [ 100, 60, 200 ], );

            my $iter = izip \@a, \@b, \@c,
              {
                on_exhaustion => {
                    0 => '100',
                    2 => '200'
                },
              };

            my $got;
            ok( lives { $got = $iter->drain }, 'iterate' );

            is( $got, \@exp_arrayref, 'results' )
              or diag pp $got;
        };

        subtest 'truncations' => sub {

            my @a = ( 0,  10, 20 );
            my @b = ( 30, 40, 50, 60, 65 );
            my @c = ( 70, 80, 90, 100 );

            my $iter = izip \@a, \@b, \@c,
              {
                on_exhaustion => {
                    0 => '25',
                },
              };

            my $got;
            ok( lives { $got = $iter->drain }, 'iterate' );

            is( $got, [ [ 0, 30, 70 ], [ 10, 40, 80 ], [ 20, 50, 90, ], [ 25, 60, 100, ], ], 'results' )

              or diag pp $got;
        };

    };

    subtest 'hashref' => sub {

        subtest 'no truncations' => sub {

            my @a = ( 0,  10, 20 );
            my @b = ( 30, 40, 50 );
            my @c = ( 70, 80, 90 );


            my $iter = izip
              a => \@a,
              b => \@b,
              c => \@c,
              {
                on_exhaustion => {
                    0 => '100',
                    2 => '200'
                },
              };


            my $got;
            ok( lives { $got = $iter->drain }, 'iterate' );

            is( $got,
                [ { a => 0, b => 30, c => 70 }, { a => 10, b => 40, c => 80 }, { a => 20, b => 50, c => 90 }, ],
                'results' );

        };

        subtest 'no effective truncations' => sub {

            my @a = ( 0,  10, 20 );
            my @b = ( 30, 40, 50, 60 );
            my @c = ( 70, 80, 90 );


            my $iter = izip
              a => \@a,
              b => \@b,
              c => \@c,
              {
                on_exhaustion => {
                    0 => '100',
                    2 => '200'
                },
              };


            my $got;
            ok( lives { $got = $iter->drain }, 'iterate' );

            is(
                $got,
                [
                    { a => 0,   b => 30, c => 70 },
                    { a => 10,  b => 40, c => 80 },
                    { a => 20,  b => 50, c => 90 },
                    { a => 100, b => 60, c => 200 },
                ],
                'results'
            );

        };

        subtest 'truncations' => sub {

            my @a = ( 0,  10, 20 );
            my @b = ( 30, 40, 50, 60, 65 );
            my @c = ( 70, 80, 90, 100 );

            my $iter = izip
              a => \@a,
              b => \@b,
              c => \@c,
              {
                on_exhaustion => {
                    0 => '25',
                },
              };

            my $got;
            ok( lives { $got = $iter->drain }, 'iterate' );

            is(
                $got,
                [
                    { a => 0,  b => 30, c => 70 },
                    { a => 10, b => 40, c => 80 },
                    { a => 20, b => 50, c => 90, },
                    { a => 25, b => 60, c => 100, },
                ],
                'results'
              )

              or diag pp $got;
        };

    };
};

subtest rewind => sub {

    my @a = ( 0,  10, 20 );
    my @b = ( 30, 40, 50, 60 );
    my @c = ( 70, 80, 90 );

    my $iter = izip \@a, \@b, \@c;

    is( $iter->next, [ 0,  30, 70 ], '1' );
    is( $iter->next, [ 10, 40, 80 ], '2' );

    ok( lives { $iter->rewind }, 'rewind method succeeds' )
      or note $@;

    is( $iter->current, [ 10, 40, 80 ], 'current' );

    is( $iter->next, [ 0, 30, 70 ], '1' );

};

subtest reset => sub {

    my @a = ( 0,  10, 20 );
    my @b = ( 30, 40, 50, 60 );
    my @c = ( 70, 80, 90 );

    my $iter = izip \@a, \@b, \@c;

    is( $iter->next, [ 0,  30, 70 ], '1' );
    is( $iter->next, [ 10, 40, 80 ], '2' );

    ok( lives { $iter->reset }, 'reset method succeeds' )
      or note $@;

    is( $iter->current, undef, 'current' );

    is( $iter->next, [ 0, 30, 70 ], '1' );

};

done_testing;
