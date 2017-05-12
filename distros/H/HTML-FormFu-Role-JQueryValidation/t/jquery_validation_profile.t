use strict;
use warnings;

use Test::More tests => 3;

use HTML::FormFu;

my $form = HTML::FormFu->new(
    { tt_args => { INCLUDE_PATH => 'share/templates/tt/xhtml' } } );

$form->load_config_file('t/jquery_validation_profile.yml');

is_deeply(
    $form->jquery_validation_profile,
    {
        rules => {
            foo => {
                required => 1,
                email    => 1,
            },
        },
        messages => {
            foo => {
                required => 'This field is required',
                email    => 'This field must contain an email address',
            },
        },
    }
);

my $json = $form->jquery_validation_json;

like( $json, qr/"required":"This field is required"/ );
like( $json, qr/"email":"This field must contain an email address"/ )
