#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';

use_ok 'Form';

my $form = Form->new();
isa_ok $form, 'HTML::FormHandler';

ok my $field = $form->field('a'), 'field';

note chomp(my $output = $field->render);

is $output,
'<input name="a" type="checkbox" value="2" x-field-method="a" x-form-method="a" x-form-method-a="b">',
  'expected output';

done_testing;
