use v5.10;
use strict;
use warnings;
use Test::More;

package Form
{
	use Form::Tiny;

	use namespace::autoclean;
}

my $form = Form->new;
can_ok $form, 'form_meta';
is $form->form_meta->package, 'Form';

done_testing;
