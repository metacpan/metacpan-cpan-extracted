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

done_testing;
