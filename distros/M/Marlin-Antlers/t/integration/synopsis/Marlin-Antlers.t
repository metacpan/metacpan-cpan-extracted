use Test2::V0;

package Local::Widget 1.0 {
	use Marlin::Antlers;

	has name => (
		is       => rw,
		isa      => Str,
		required => true,
	);

	our $NEXT_ID = 1;
	has id => sub { $NEXT_ID++ };

	sub dump ( $self ) {
		sprintf '%s[%d]', $self->name, $self->id;
	}
}

package Local::CoolWidget 1.0 {
	use Marlin::Antlers;
	extends 'Local::Widget 1.0';
}

my $w = Local::CoolWidget->new( name => 'Foo' );

is $w->dump, "Foo[1]";

done_testing;
