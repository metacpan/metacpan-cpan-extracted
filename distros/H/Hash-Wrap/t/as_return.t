#! perl

use Test2::V0;
require Hash::Wrap;

my @func;
ok(
    lives {
        @func = Hash::Wrap->import( { -as => '-return', -class => 'A1' },
            { -as => '-return', -class => 'A2' }, );
    },
    'constructor'
) or note $@;

like(
    dies { wrap_hash( {} ) },
    qr{undefined subroutine.*wrap_hash.* at t/as_return.t}i,
    "constructor wasn't inserted into our namespace"
);

ref_ok( $func[0], 'CODE', 'we got a code ref!' );
ref_ok( $func[1], 'CODE', 'we got another code ref!' );

for my $test ( [ $func[0], 'A1' ], [ $func[1], 'A2' ] ) {
    my ( $func, $class ) = @$test;

    subtest $class => sub {
        my $obj;
        ok( lives { $obj = $func->( { answer => 42 } ) }, 'create object' )
          or note $@;

        is(
            $obj,
            meta {
                prop blessed => $class;
                prop this    => object {
                    call answer => 42;
                };
            },
            "object works!"
        );
    };
}

done_testing();
