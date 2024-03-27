use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Exception;

{

	package Center;

	use strict;
	use warnings;

	use Form::Tiny -strict;
	use Types::Standard 'Bool';

	form_field pixcent => (
		type => Bool,
	);
}

{

	package ECF;

	use strict;
	use warnings;

	use Form::Tiny -strict;

	form_field center => (
		type => Center->new,
		default => sub { {} },
	);
}

{

	package Calc;

	use strict;
	use warnings;

	use Form::Tiny -strict;

	form_field ecf => (
		type => ECF->new,
		default => sub { {} },
	);
}

lives_ok {
	my $form = ECF->new;
	$form->set_input({center => {pixcent => bless [], 'Foo'}});
	$form->valid;
} 'level 1 form valid ok';

lives_ok {
	my $form = Calc->new;
	$form->set_input({ecf => {center => {pixcent => bless [], 'Foo'}}});
	$form->valid;
} 'level 2 form valid ok';

done_testing;

