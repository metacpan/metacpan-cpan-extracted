use strict;
use warnings;
use Test::More tests => 1;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use HTMLFormFu::MockContext;
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/options_from_model/many_to_many_select_restricted.yml');

my $schema = new_schema();

my $context = HTMLFormFu::MockContext->new( {
    model => $schema->resultset('Band'),
} );

$form->stash( { context => $context } );

my $master = $schema->resultset('Master')->create({ id => 1 });

my $band1;

# filler rows
{
    # user 1
    my $u1 = $master->create_related( 'user', { name => 'John' } );

    # band 1
    $band1 = $u1->add_to_bands( { band => 'the beatles', manager => 1 } );
}

# rows we're going to use
{
    # user 2
    my $u2 = $master->create_related( 'user', { name => 'Paul' } );

    $u2->add_to_bands($band1);

    # band 2
    $u2->add_to_bands( { band => 'wings', manager => 1 } );

    # band 3
    $schema->resultset('Band')->create( { band => 'the kinks', manager => 2 } );
}

{
    $form->process;

    is_deeply(
        $form->get_field('bands')->options,
        [ {     'label_attributes'     => {},
                'value'                => '1',
                'label'                => 'the beatles',
                'attributes'           => {},
                'container_attributes' => {},
            },
            {   'label_attributes'     => {},
                'value'                => '2',
                'label'                => 'wings',
                'attributes'           => {},
                'container_attributes' => {},
            },
        ],
        "Options set from the model"
    );
}
