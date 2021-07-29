#! perl

use Test2::V0;
require Hash::Wrap;

subtest 'api' => sub {

    like( dies { Hash::Wrap->import( {-as => {} } ) },
          qr{-as must be .* at t/as_scalar_ref.t},
          'not a string'
        );

    like( dies { Hash::Wrap->import( {-as => \(my $func), -class => '-caller' } ) },
          qr{not a plain string at t/as_scalar_ref.t},
          "can't mix -as => \$scalar and -class => -caller"
        );
};

subtest 'functionality' => sub {

    my $func;
    ok(
       lives { Hash::Wrap->import( { -as => \$func } ) },
       'construct'
       ) or note $@;

    ref_ok( $func, 'CODE', 'we got a code ref!' );

    # check that we can reuse $func
    ok(
       lives { Hash::Wrap->import( { -as => \$func } ) },
       'reuse non-empty scalar'
       ) or note $@;

};

done_testing();
