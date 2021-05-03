use strict;
use warnings;

use File::Spec;

use Test::More 0.88;

require_ok('Exception::Class');

# no problems here
{
    my $rc = eval {
        Exception::Class->import(
            'GoodFields' => { fields => [qw( foo )] },
        );
        'success';
    };
    is( $rc, 'success', 'GoodFields did not have a problem' );
}

# problems here

my @bad_fields = ( '$foo', q(f'oo), 'f oo' );

my $n = 0;
foreach my $bad_field (@bad_fields) {
    $n++;
    my $rc = eval {
        Exception::Class->import(
            "GoodFields$n" => { fields => [$bad_field] },
        );
        q(we should not get this far);
    };
    my $error = $@;
    ok( !defined $rc, "Field name <$bad_field> throws an error" );
    like $error, qr/Invalid field name/,
        'Error messages notes invalid field name';
}

done_testing();
