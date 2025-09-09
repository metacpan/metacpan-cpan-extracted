#!/usr/bin/env perl

use Test2::V0 -target => 'Game::Entities';;
use Test2::Tools::Spec;

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

@Prefix::Named::ISA = 'Named';
@Prefix::Aging::ISA = 'Aging';
@Prefix::Other::ISA = 'Other';

describe 'Basic operations' => sub {
    my $prefix;

    case 'With prefix' => sub { $prefix = 'Prefix' };
    case 'No prefix'   => sub { $prefix = undef    };

    it Works => { flat => 1 } => sub {
        my $base   = $prefix ? "${prefix}::" : '';
        my $marker = $prefix ? ':'           : '';

        my $R = Game::Entities->new( prefix => $prefix );

        my ( $a, $b ) = map $R->create, 1 .. 2;

        is $R->check( $a, "${marker}Named" ), F,
            "A does not have ${base}Named";

        $R->add( $a, "${base}Named"->new( name => 'old' ) );
        $R->add( $a, "${base}Named"->new( name => 'new' ) );

        is $R->check( $a, "${marker}Named" ), T,
            "A has ${base}Named";

        if ( $prefix ) {
            is $R->check( $a,   'Named' ), F, 'No colon does not use prefix';
            is $R->check( $a, '::Named' ), F, 'Double colon does not use prefix';
        }

        is $R->check( $b, "${marker}Named" ), F,
            "B does not have ${base}Named";

        is $R->get( $a, "${marker}Named" )->name, 'new',
            'Adding component replaces';

        ref_is $R->delete( $a, "${marker}Named" ), $R;

        is $R->check( $a, "${marker}Named" ), F,
            "A does not have ${base}Named";

        $R->delete( $a, "${marker}Named" );

        is $R->check( $a, "${marker}Named" ), F,
            'Deleting is idempotent';

        is $R->get( $a, "${marker}Named" ), U,
            'Getting returns undef when no component';
    };
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
    ok  $R->valid(10), 'Entity is valid';
    ok !$R->valid(11), 'Entity is not valid';

    # Delete the entities we've just generated
    # Will mark their IDs as ready to be recycled
    $R->delete($_) for @e;

    is  $R->created, 10, 'Created counts all created entities';
    is  $R->alive,    0, 'Right number of alive entities when all dead';
    ok !$R->valid(10),   'Entity is not valid';

    # Create 20 entities
    # They should re-use the first 10 IDs and use the next 10 ( 0 .. 19 )
    @e = map $R->create( Other->new ), 0 .. 19;
    is [ sort { $a <=> $b } map $_ & 0xFFFFF, @e ],
        [ 1 .. 20 ],
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
        is [ sort map {
                    my $name = $R->get( $_, 'Named' );
                    $name ? $name->name : ();
                } $R->view('Named')->entities
            ],
            [qw( Mit Most Pat Tim )], 'entities';

        is [ sort map {
                    my ($name) = @$_;
                    $name ? $name->name : ();
                } $R->view('Named')->components
            ],
            [qw( Mit Most Pat Tim )], 'components';

        is [ sort map {
                    my ( $guid, $age ) = ( $_->[0], @{ $_->[1] } );
                    $age->age;
                } @{ $R->view('Aging') }
            ],
            [ 10, 2, 20, 200 ], 'deref';

        {
            my @first = $R->view('Aging')->first( sub { $_[1]->age > 100 } );
            is [ $first[0], $first[1]->age ], [ 6, 200 ],
                'first with match returns flat list';
        }

        {
            my @first = $R->view('Aging')->first;
            is [ $first[0], $first[1]->age ], [ 2, 10 ],
                'first with no matcher returns first element';
        }

        is [ $R->view('Aging')->first( sub { $_[1]->age > 1000 } ) ],
            [], 'first with no match returns empty list';

        my @set;
        $R->view('Aging')->each( sub ( $guid, $age ) {
            push @set, $age->age;
        });

        is [ sort @set ], [ 10, 2, 20, 200 ], 'each';
    };

    subtest 'Complex view' => sub {
        is [ sort map {
                    my ( $name, $age ) = $R->get( $_, 'Named', 'Aging' );
                    join ':', $age->age, $name->name;
                } $R->view('Aging', 'Named')->entities
            ],
            [qw( 200:Most 20:Tim 2:Mit )], 'entities';

        is [ sort map {
                    my ($age, $name) = @$_;
                    join ':', $age->age, $name->name;
                } $R->view('Aging', 'Named')->components
            ],
            [qw( 200:Most 20:Tim 2:Mit )], 'components';

        is [ sort map {
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

        is [ sort @age_name ], [qw( 200:Most 20:Tim 2:Mit )], 'each';
        is [ sort @age_name ], [ sort @name_age ], 'order';
    };

    subtest 'Global view' => sub {
        my @set;
        $R->view->each( sub ($guid) {
            push @set, $guid . ':' . ( defined $R->get( $guid, 'Aging' ) ? 1 : 0 );
        });

        is [ sort @set ], [qw( 1:0 2:1 3:1 5:1 6:1 )],
            'Iterate over all entities';
    };

    subtest 'View with prefix' => sub {
        my $R = Game::Entities->new( prefix => 'Prefix' );

        my $aging = $R->create( Prefix::Aging->new( age  =>  1  ) );
        my $named = $R->create(         Named->new( name => 'x' ) );

        my $both = $R->create(
            Prefix::Aging->new( age  =>  2  ),
                    Named->new( name => 'y' ),
        );

        is [ $R->view(qw( :Aging Named ))->entities ], [ $both ],
            'Views can use prefixes';
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

    is [ sort @x ], [ 11, 6, 9 ], 'View can modify components';

    my @y;
    $R->view->each( sub ($e) {
        return unless my $y = $R->get( $e, 'Y' );
        push @y, $y->value;
    });

    is [ sort @y ], [ 10, 11, 7 ], 'Other component is left alone';

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

