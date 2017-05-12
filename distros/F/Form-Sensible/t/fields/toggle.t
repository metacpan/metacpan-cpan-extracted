use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Data::Dumper;
use Form::Sensible;

use Form::Sensible::Form;

my $lib_dir = $FindBin::Bin;
my @dirs = split '/', $lib_dir;
pop @dirs;
$lib_dir = join('/', @dirs);


my $form = Form::Sensible->create_form( {
    name => 'test',
    fields => [
        {
            field_class => 'Toggle',
            name => 'toggle',
            on_value => '100',
            off_value => '0'
        },
    ],
} );

my $toggle_field = $form->field('toggle');

is($toggle_field->on_value, 100, 'ON state value should be 100');
is($toggle_field->off_value, 0, 'OFF state value should be 0');

done_testing();
