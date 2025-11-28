package ExtUtils::Builder::FileSet;
$ExtUtils::Builder::FileSet::VERSION = '0.018';
use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		entries    => [],
		dependents => [],
		callback   => $args{callback},
	}, $class;
	return $self;
}

sub entries {
	my $self = shift;
	return @{ $self->{entries} };
}

sub add_dependent {
	my ($self, $dep) = @_;
	push @{ $self->{dependents} }, $dep;
	for my $file (@{ $self->{entries} }) {
		$dep->add_input($file);
	}
	return;
}

sub _pass_on {
	my ($self, $entry) = @_;
	push @{ $self->{entries} }, $entry;
	$self->{callback}->($entry) if $self->{callback};
	for my $dependent (@{ $self->{dependents} }) {
		$dependent->add_input($entry);
	}
	return;
}

1;
