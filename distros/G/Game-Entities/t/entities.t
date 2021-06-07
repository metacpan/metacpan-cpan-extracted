#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Game::Entities;

use experimental 'signatures';

package Named {
    sub new  ( $class, %args ) { bless \%args, $class }
    sub name ( $self ) { $self->{name} // '' }
}

package Aging {
    sub new ( $class, %args ) { bless \%args, $class }
    sub age ( $self ) { $self->{age} // '' }
}

package Other {
    sub new ( $class, %args ) { bless \%args, $class }
}

sub exception :prototype(&;@) {
    my ( $code, $check, $message ) = @_;
    is eval { $code->() }, undef, $message;
    like $@, $check, 'error message';
}

subtest 'Basic operations' => sub {
    my $R = Game::Entities->new;

    my ( $a, $b ) = map $R->create, 1 .. 2;

    ok !$R->check( $a, 'Named' ), 'A does not have Named';

    $R->add( $a, Named->new( name => 'old' ) );
    $R->add( $a, Named->new( name => 'new' ) );

    ok  $R->check( $a, 'Named' ), 'A has Named';
    ok !$R->check( $b, 'Named' ), 'B does not have Named';

    is  $R->get( $a, 'Named' )->name, 'new', 'Adding component replaces';

    ok !$R->delete( $a, 'Named' ), 'delete returns falsy';
    ok !$R->check(  $a, 'Named' ), 'A does not have Named';

    $R->delete( $a, 'Named' );

    ok !$R->check( $a, 'Named' ), 'Deleting is idempotent';
    ok !$R->get(   $a, 'Named' ), 'Getting returns undef when no component';
};

subtest 'Delete entities' => sub {
    my $R = Game::Entities->new;

    my $a = $R->create( Named->new( name => 'a' ), Other->new );

    ok $R->valid($a),          'A is valid';
    ok $R->get( $a, 'Other' ), 'A has Other';
    ok $R->get( $a, 'Named' ), 'A has Named';

    $R->delete($a);

    ok !$R->valid($a),          'A is not valid';
    ok !$R->get( $a, 'Other' ), 'A does not have Other';
    ok !$R->get( $a, 'Named' ), 'A does not have Named';
};

subtest 'Recycling GUIDs' => sub {
    my $R = Game::Entities->new;

    is $R->alive, 0, 'Right number of alive entities when none created';

    # Create 10 entities; will use the first 10 entity IDs ( 0 .. 9 )
    my @e = map $R->create, 1 .. 10;

    is  $R->alive, 10, 'Right number of alive entities when all alive';
    ok  $R->valid(9),  'Entity is valid';
    ok !$R->valid(10), 'Entity is not valid';

    # Delete the entities we've just generated
    # Will mark their IDs as ready to be recycled
    $R->delete($_) for @e;

    is  $R->created, 10, 'Created counts all created entities';
    is  $R->alive,    0, 'Right number of alive entities when all dead';
    ok !$R->valid(9),    'Entity is not valid';

    # Create 20 entities
    # They should re-use the first 10 IDs and use the next 10 ( 0 .. 19 )
    @e = map $R->create( Other->new ), 0 .. 19;
    is_deeply [ sort { $a <=> $b } map $_ & 0xFFFFF, @e ],
        [ 0 .. 19 ],
        'Recycled and generated the right IDs';

    ok $R->valid($e[8]), 'Entity is valid';
    is $R->alive, 20,    'Recorded the right number of alive entities after recycling';

    @e = $R->view('Other')->entities;
    is @e, 20, 'Only alive entities match view';

    $R->clear;
    is $R->alive,   0, 'Clear invalidates all entities';
    is $R->created, 0, 'No records remain';
};

subtest 'View' => sub {
    my $R = Game::Entities->new;

    my $named   = $R->create;
    my $aging   = $R->create;
    my $both    = $R->create;
    my $dead    = $R->create;
    my $reverse = $R->create;
    my $extra   = $R->create;

    $R->delete($dead);

    $R->add( $named   => Named->new( name => 'Pat'  ) );
    $R->add( $aging   => Aging->new( age  => 10     ) );

    $R->add( $both    => Aging->new( age  => 20     ) );
    $R->add( $both    => Named->new( name => 'Tim'  ) );

    $R->add( $reverse => Named->new( name => 'Mit'  ) );
    $R->add( $reverse => Aging->new( age  => 2      ) );

    $R->add( $extra   => Named->new( name => 'Most' ) );
    $R->add( $extra   => Aging->new( age  => 200    ) );
    $R->add( $extra   => Other->new                   );

    subtest 'Simple view' => sub {
        is_deeply [ sort map {
                    my $name = $R->get( $_, 'Named' );
                    $name ? $name->name : ();
                } $R->view('Named')->entities
            ],
            [qw( Mit Most Pat Tim )], 'entities';

        is_deeply [ sort map {
                    my ($name) = @$_;
                    $name ? $name->name : ();
                } $R->view('Named')->components
            ],
            [qw( Mit Most Pat Tim )], 'components';

        is_deeply [ sort map {
                    my ( $guid, $age ) = ( $_->[0], @{ $_->[1] } );
                    $age->age;
                } @{ $R->view('Aging') }
            ],
            [ 10, 2, 20, 200 ], 'deref';

        my @set;
        $R->view('Aging')->each( sub ( $guid, $age ) {
            push @set, $age->age;
        });

        is_deeply [ sort @set ], [ 10, 2, 20, 200 ], 'each';
    };

    subtest 'Complex view' => sub {
        is_deeply [ sort map {
                    my ( $name, $age ) = $R->get( $_, 'Named', 'Aging' );
                    join ':', $age->age, $name->name;
                } $R->view('Aging', 'Named')->entities
            ],
            [qw( 200:Most 20:Tim 2:Mit )], 'entities';

        is_deeply [ sort map {
                    my ($age, $name) = @$_;
                    join ':', $age->age, $name->name;
                } $R->view('Aging', 'Named')->components
            ],
            [qw( 200:Most 20:Tim 2:Mit )], 'components';

        is_deeply [ sort map {
                    my ($age, $name) = @{ $_->[1] };
                    join ':', $age->age, $name->name;
                } @{ $R->view('Aging', 'Named') }
            ],
            [qw( 200:Most 20:Tim 2:Mit )], 'deref';

        my @age_name;
        $R->view('Aging', 'Named')->each( sub ( $guid, $age, $name ) {
            push @age_name, join ':', $age->age, $name->name;
        });

        my @name_age;
        $R->view('Named', 'Aging')->each( sub ( $guid, $name, $age ) {
            push @name_age, join ':', $age->age, $name->name;
        });

        is_deeply [ sort @age_name ], [qw( 200:Most 20:Tim 2:Mit )], 'each';
        is_deeply [ sort @age_name ], [ sort @name_age ], 'order';
    };

    subtest 'Global view' => sub {
        my @set;
        $R->view->each( sub ($guid) {
            push @set, $guid . ':' . ( defined $R->get( $guid, 'Aging' ) ? 1 : 0 );
        });

        is_deeply [ sort @set ], [qw( 0:0 1:1 2:1 4:1 5:1 )],
            'Iterate over all entities';
    };
};

subtest 'Modifying view' => sub {
    my $R = Game::Entities->new;

    package X {
        sub new ( $class, %args ) {
            bless { value => 10, %args }, $class;
        }

        sub value : lvalue { shift->{value} }
    }

    @Y::ISA = 'X';

    $R->create( Y->new( value => 7 ), X->new( value => 7 ) );
    $R->create( Y->new( value => 5 ), X->new( value => 5 ) );
    $R->create( Y->new,               X->new               );

    $R->view('X', 'Y')->each( sub ( $e, $x, $y ) {
        if ( --$x->value < 5 ) {
            $R->delete($e);
            $R->create( X->new( value => 11 ) );
            $R->create( Y->new( value => 11 ) );
        }
    });

    my @x;
    $R->view->each( sub ($e) {
        return unless my $x = $R->get( $e, 'X' );
        push @x, $x->value;
    });

    is_deeply [ sort @x ], [ 11, 6, 9 ], 'View can modify components';

    my @y;
    $R->view->each( sub ($e) {
        return unless my $y = $R->get( $e, 'Y' );
        push @y, $y->value;
    });

    is_deeply [ sort @y ], [ 10, 11, 7 ], 'Other component is left alone';

    $R->_dump_entities;
    like $R->_dump_entities, qr/SPARSE/, 'Generated dump';
};

subtest 'Component types' => sub {
    my $R = Game::Entities->new;

    subtest 'Good components' => sub {
        for (
            [ 'unblessed reference', 'HASH', {}  ],
            [ 'blessed reference',   'Other', Other->new ],
        ) {
            my ( $message, $type, $component ) = @$_;

            my $guid = $R->create( $component );
            is $R->get( $guid, $type ), $component, $message;

            $R->clear;
        }
    };

    subtest 'Bad components' => sub {
        for (
            [ 'undef',        undef ],
            [ 'plain scalar', 123   ],
        ) {
            my ( $message, $component ) = @$_;

            exception { $R->create( $component ) }
                qr/Component must be a reference/,
                "$message on create";

            my $guid = $R->create;

            exception { $R->add( $guid => $component ) }
                qr/Component must be a reference/,
                "$message on add";

            is $R->alive, 1, 'Did not create entities';
            $R->clear;
        }
    };

    subtest 'Components instead of names' => sub {
        my $guid = $R->create;
        for (
            [ undef => undef ],
            [ ref   => {}    ],
        ) {
            my ( $name, $input ) = @$_;

            exception { $R->check( $guid => $input ) }
                qr/Component name must be defined and not a reference/,
                "$name on check";

            exception { $R->get( $guid => $input ) }
                qr/Component name must be defined and not a reference/,
                "$name on get";
        }
    };

};

done_testing;

