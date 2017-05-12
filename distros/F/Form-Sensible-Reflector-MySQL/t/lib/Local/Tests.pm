use strict;
use warnings;

package Local::Tests;

use Test::More;
sub positive_form_tests {
	my $form = shift;
	foreach my $f ( $form->get_fields ){
		next if $f->field_type eq 'trigger';
		 isnt( $f->value, undef, $f->name .' has value');	
		 ok( $f->value, $f->name .' is true');	
	}
	
	TODO: {
	  local $TODO = 'Form::Sensible does not (yet) support multiple selections: http://search.cpan.org/~jayk/Form-Sensible-0.20002/lib/Form/Sensible/Field/Select.pm#METHODS';
		is(
			$form->field('my_set')->value, 'two,three', 'Allow set with multiple values'
		);
	}
}

1;

