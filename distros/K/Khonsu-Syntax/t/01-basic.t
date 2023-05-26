use Test::More;

use Khonsu;

Khonsu->load_plugin(qw/+Syntax/);

my $k = Khonsu->new('test', page_args => {padding => 20});

my $test = q|package Test::Package;

use Moo;

has one => ( 
	is => 'rw',
	other => sub { ... }
);

sub two {
	my ($self, %attributes) = @_;

	my $one = $self->one();

	return $one;
}

1;|;

$k->add_syntax(
	text => $test,
	y => 20,
);

my $json = q|{
	"one": 1,
	"two": 2,
	"three": 3,
	"four": 4
}|;

$k->add_syntax(
	syntax => 'JSON',
	line_numbers => 1,
	text => $json
);

$k->save();

ok(1);

done_testing();
