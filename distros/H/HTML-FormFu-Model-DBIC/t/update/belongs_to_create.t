use strict;
use warnings;
use Test::More tests => 2;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->populate({
    elements => [
        {
            name => 'band',
        },
        {
            type => 'Block',
            nested_name => 'manager',
            elements => {
                name => 'name',
            }
        }
    ]
});

my $schema = new_schema();

my $rs = $schema->resultset('Band');
my $band = $rs->new_result({});

$form->process({ band => 'The Foobars', 'manager.name' => 'Mr Foo' });

$form->model('DBIC')->update($band);

is($band->band, 'The Foobars');
is($band->manager->name, 'Mr Foo');
