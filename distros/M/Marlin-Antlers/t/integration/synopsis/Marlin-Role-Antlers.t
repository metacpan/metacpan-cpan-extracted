use utf8;
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

package Local::CoolerDump 2.0 {
	use Marlin::Role::Antlers;

	requires "dump";

	has emoji => sub { "✨" };

	around dump => sub ( $next_method, $self, @args ) {
		my $emoji = $self->emoji;
		my $dump  = $self->$next_method( @args );
		return $emoji . $dump . $emoji;
	};
}

package Local::CoolWidget 1.0 {
	use Marlin::Antlers;
	extends 'Local::Widget 1.0';
	with 'Local::CoolerDump 2.0';
}

my $w = Local::CoolWidget->new( name => 'Foo' );

is $w->dump, "✨Foo[1]✨";

done_testing;
