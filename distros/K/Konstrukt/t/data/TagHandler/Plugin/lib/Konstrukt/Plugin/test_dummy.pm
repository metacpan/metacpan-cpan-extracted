#test dummy

package Konstrukt::Plugin::test_dummy;

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

sub init { return 1; }

sub prepare_again { return 23; }
sub execute_again { return 42; }

sub prepare {
	my ($self, $tag) = @_;
	$tag->{dynamic} = 1;
	#return \"prepared";
	return undef;
}

sub execute {
	my ($self, $tag) = @_;
	return \"executed";
}

sub BEGIN { $Konstrukt::Plugin::test_dummy= __PACKAGE__->new() unless defined $Konstrukt::Plugin::test_dummy; }

1;
