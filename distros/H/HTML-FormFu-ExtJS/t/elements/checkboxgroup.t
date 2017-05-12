use Test::More;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;

$form->populate(
    {
        elements => [
            {
                type    => 'Checkboxgroup',
                default => [ 1, 3 ],
                options => [
                    { label => 'bar',    value => 1, },
                    { label => 'foo',    value => 2, },
                    { label => 'foobar', value => 3, }
                ]
            }
        ]
    }
);

is_deeply(  $form->_render->{items}->[0]->{items}, [
  {
    'checked' => 'checked',
    'inputValue' => 1,
    'boxLabel' => 'bar',
    'name' => undef
  },
  {
    'inputValue' => 2,
    'boxLabel' => 'foo',
    'name' => undef
  },
  {
    'checked' => 'checked',
    'inputValue' => 3,
    'boxLabel' => 'foobar',
    'name' => undef
  }
]
 );

done_testing;
