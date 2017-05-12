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
            field_class => 'Trigger',
            name => 'trigger',
        },
    ],
} );

my $trigger_field = $form->field('trigger');
is(defined $trigger_field, 1, 'is trigger exist');

done_testing();
