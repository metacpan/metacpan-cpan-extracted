use Test::More;

use HTML::FormFu::ExtJS;
use strict;
use warnings;

my $form = new HTML::FormFu::ExtJS;

$form->populate({elements => [{type => 'Checkbox', default => '1'},{type => 'Checkbox', default => '0'}]});

is(${ $form->_render->{items}->[0]->{checked} } , 1);
is(${ $form->_render->{items}->[1]->{checked} } , 0);

done_testing;