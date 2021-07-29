#! perl

use Test2::V0;

require Hash::Wrap;

subtest 'api' => sub {

    like(
        dies { Hash::Wrap->import( { -recurse => 'aa' } ) },
        qr/-recurse must be.*recurse.t/,
        'not a number'
    );
};

subtest 'recursion' => sub {

    for my $recurse ( -1, 0 .. 3 ) {

        subtest "recurse => $recurse" => sub {
            my $new;

            ok(
                lives {
                    Hash::Wrap->import( { -as => \$new, -recurse => $recurse } )
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
                prop this    => hash { field l => 3; end; }
              };

            my $b = $recurse >= 2 || $recurse < 0
              ? object {
                call l => 2;
                call c => $c;
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
                call l => 1;
                call b => $b;
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
                    call l => 0;
                    call a => $a;
                },
                'object'
            );
        };
    }
};

# subtest q[don't touch objects] => sub {

# };

done_testing();
