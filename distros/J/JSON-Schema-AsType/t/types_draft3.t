use 5.10.0;

use strict;
use warnings;

use Test::More;

use JSON;

use JSON::Schema::AsType::Draft3::Types '-all';

test_type( Disallow[Integer],
    [ { foo => 1 }, "banana" ], [ 1 ]
);


done_testing;

sub test_type {
    my( $type, $good, $bad ) = @_;

    subtest $type => sub {

        subtest 'valid values' => sub {
            for my $test ( @$good ) {
                ok $type->check($test), join '', 'value: ', explain $test;
            }
        } if $good;

        subtest 'bad values' => sub {
            my $printed = 0;
            for my $test ( @$bad ) {
                my $error = $type->validate($test);
                ok $error, join '', 'value: ', explain $test;
                diag $error unless $printed++;
            }
        } if $bad;
    };

}
