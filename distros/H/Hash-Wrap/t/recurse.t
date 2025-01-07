#! perl

use Test2::V0;

use Scalar::Util 'refaddr';
use Hash::Util 'lock_hash';
require Hash::Wrap;

subtest 'api' => sub {

    like(
        dies { Hash::Wrap->import( { -recurse => 'aa' } ) },
        qr/-recurse must be.*recurse.t/,
        'not a number'
    );
};

subtest '-recurse' => sub {

    for my $recurse ( -1, 0 .. 3 ) {

        subtest "recurse => $recurse" => sub {
            my $new;

            ok(
                lives {
                    Hash::Wrap->import( {
                            -as      => \$new,
                            -recurse => $recurse,
                            -methods => { say => sub { $_[1] } },
                            -exists  => '_exists'
                        } )
                },
                'constructor'
            ) or note $@;

            my $obj;
            ok(
                lives {
                    $obj = $new->( {
                            l => 0,
                            a => {
                                l => 1,
                                b => { l => 2, c => { l => 3 } },
                            } } );
                },
                'construct object'
            );

            my $c = $recurse >= 3 || $recurse < 0
              ? object {
                call l => 3;
              }
              : meta {
                prop blessed => undef;
                prop reftype => 'HASH';
                prop this => hash { field l => 3; end; }
              };

            my $b = $recurse >= 2 || $recurse < 0
              ? object {
                call l                  => 2;
                call c                  => $c;
                call [ _exists => 'c' ] => T();
              }
              : meta {
                prop blessed => undef;
                prop reftype => 'HASH';
                prop this    => hash {
                    field l => 2;
                    field c => $c;
                    end;
                }
              };

            my $a = $recurse >= 1 || $recurse < 0
              ? object {
                call l                  => 1;
                call b                  => $b;
                call [ _exists => 'b' ] => T();
              }
              : meta {
                prop blessed => undef;
                prop reftype => 'HASH';
                prop this    => hash {
                    field l => 1;
                    field b => $b;
                    end;
                }
              };

            is(
                $obj,
                object {
                    call l                  => 0;
                    call a                  => $a;
                    call [ _exists => 'a' ] => T();
                },
                'object'
            );
        };
    }
};

subtest '-copy -recurse' => sub {

    my %hash = (
        a => {
            b => {
                c => {
                    d => {
                        e => 2,
                    },
                },
            },
        },
    );

    my ( $func )
      = Hash::Wrap->import( { -as => '-return', -copy => 1, -recurse => -1 } );
    my $wrap = $func->( \%hash );

    subtest '$wrap is copy of %hash' => sub {
        isnt( $wrap, exact_ref( \%hash ), 'refaddr($wrap) != refaddr($hash)' );

        note 'hash at level 1 still shared with original';
        is( $wrap->{a}, exact_ref( $hash{a} ), 'refaddr($wrap->{a}) == refaddr($hash{a})' );

    };

    subtest 'use of method for level 1 creates copy' => sub {
        isnt( $wrap->a, exact_ref( $hash{a} ), 'refaddr($wrap->a) != refaddr($hash{a})' );
        is( $wrap->a, exact_ref( $wrap->{a} ), 'refaddr($wrap->a) == refaddr($wrap->{a})' );

        note 'hash at level 2 still shared with original';
        is( $wrap->a->{b}, exact_ref( $hash{a}{b} ), 'refaddr($wrap->a->{b}) == refaddr($hash{a}{b})' );

    };

    subtest 'use of method for level 2 creates copy' => sub {
        isnt( $wrap->a->b, exact_ref( $hash{a}{b} ), 'refaddr($wrap->a->b) != refaddr($hash{a}{b})' );
        is( $wrap->a->b, exact_ref( $wrap->{a}{b} ), 'refaddr($wrap->a->b) == refaddr($wrap->{a}{b}})' );

        note 'hash at level 3 still shared with original';
        is(
            $wrap->a->b->{c},
            exact_ref( $hash{a}{b}{c} ),
            'refaddr($wrap->a->b->{c}) == refaddr($hash{a}{b}{c})'
        );

    };

};

subtest '-copy -recurse -immutable' => sub {

    my %hash = (
        a => {
            b => {
                c => {
                    d => {
                        e => 2,
                    },
                },
            },
        },
    );

    my ( $func ) = Hash::Wrap->import( {
        -as        => '-return',
        -immutable => 1,
        -copy      => 1,
        -recurse   => -1
    } );
    my $wrap = $func->( \%hash );

    subtest '$wrap is copy of %hash' => sub {
        isnt( $wrap, exact_ref( \%hash ), 'refaddr($wrap) != refaddr($hash)' );

        note 'hash at level 1 still shared with original';
        is( $wrap->{a}, exact_ref( $hash{a} ), 'refaddr($wrap->{a}) == refaddr($hash{a})' );

    };

    subtest 'use of method for level 1 creates copy' => sub {
        isnt( $wrap->a, exact_ref( $hash{a} ), 'refaddr($wrap->a) != refaddr($hash{a})' );
        is( $wrap->a, exact_ref( $wrap->{a} ), 'refaddr($wrap->a) == refaddr($wrap->{a})' );

        note 'hash at level 2 still shared with original';
        is( $wrap->a->{b}, exact_ref( $hash{a}{b} ), 'refaddr($wrap->a->{b}) == refaddr($hash{a}{b})' );

    };

    subtest 'use of method for level 2 creates copy' => sub {
        isnt( $wrap->a->b, exact_ref( $hash{a}{b} ), 'refaddr($wrap->a->b) != refaddr($hash{a}{b})' );
        is( $wrap->a->b, exact_ref( $wrap->{a}{b} ), 'refaddr($wrap->a->b) == refaddr($wrap->{a}{b}})' );

        note 'hash at level 3 still shared with original';
        is(
            $wrap->a->b->{c},
            exact_ref( $hash{a}{b}{c} ),
            'refaddr($wrap->a->b->{c}) == refaddr($hash{a}{b}{c})'
        );

    };

};

subtest '-copy -recurse -immutable on immutable hash' => sub {

    my %hash = (
        a => {
            b => {
                c => 1,
            },
        },
    );

    # lock_hash_recurse is only available in Perl v5.18, so do this
    # manually.
    lock_hash( %{ $hash{a}{b} } );
    lock_hash( %{ $hash{a} } );
    lock_hash( %hash );

    # just to make sure, as this test will also pass if the hash isn't
    # locked.
    ok( dies { $hash{a}{b}{c} = 3 }, 'locked hash at b' );
    ok( dies { $hash{a}{b}    = 3 }, 'locked hash at a' );
    ok( dies { $hash{a}       = 3 }, 'locked hash at top' );

    my ( $func ) = Hash::Wrap->import( {
        -as        => '-return',
        -immutable => 1,
        -copy      => 1,
        -recurse   => -1
    } );
    my $wrap = $func->( \%hash );

    subtest '$wrap is copy of %hash' => sub {
        isnt( $wrap, exact_ref( \%hash ), 'refaddr($wrap) != refaddr($hash)' );

        note 'hash at level 1 still shared with original';
        is( $wrap->{a}, exact_ref( $hash{a} ), 'refaddr($wrap->{a}) == refaddr($hash{a})' );

    };

    subtest 'use of method for level 1 creates copy' => sub {
        isnt( $wrap->a, exact_ref( $hash{a} ), 'refaddr($wrap->a) != refaddr($hash{a})' );
        is( $wrap->a, exact_ref( $wrap->{a} ), 'refaddr($wrap->a) == refaddr($wrap->{a})' );

        note 'hash at level 2 still shared with original';
        is( $wrap->a->{b}, exact_ref( $hash{a}{b} ), 'refaddr($wrap->a->{b}) == refaddr($hash{a}{b})' );

    };

    subtest 'use of method for level 2 creates copy' => sub {
        isnt( $wrap->a->b, exact_ref( $hash{a}{b} ), 'refaddr($wrap->a->b) != refaddr($hash{a}{b})' );
        is( $wrap->a->b, exact_ref( $wrap->{a}{b} ), 'refaddr($wrap->a->b) == refaddr($wrap->{a}{b}})' );

    };

};

{
    package MyObject;
    sub new { bless {}, $_[0]; }
    sub foo { return 'bar'; }
    sub bar { return 'foo'; }
}

subtest '-recurse with object' => sub {

    my %hash = (
        a => {
            b => {
                c => MyObject->new,
            },
        },
    );

    my ( $func ) = Hash::Wrap->import( {
        -as        => '-return',
        -recurse   => -1,
    } );

    my $wrap = $func->( \%hash );

    is ( $wrap->a->b->c->foo, 'bar' );

};

done_testing;

