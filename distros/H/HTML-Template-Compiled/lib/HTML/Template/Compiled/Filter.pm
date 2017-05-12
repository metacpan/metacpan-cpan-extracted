package HTML::Template::Compiled::Filter;
our $VERSION = '1.003'; # VERSION
use strict;
use warnings;

use constant SUBS => 0;

sub new {
	my ($class, $spec) = @_;
	if (ref $spec eq __PACKAGE__) {
		return $spec;
	}
	my $self = [];
	bless $self, $class;
	$self->init($spec);
	return $self;
}

sub init {
	my ($self, $spec) = @_;
	if (ref $spec eq 'CODE') {
		$self->[SUBS] = [
			{
				code => $spec,
				format => 'scalar',
			},
		];
	}
	else {
		for my $filter (ref $spec eq 'ARRAY' ? @$spec : $spec) {
			push @{ $self->[SUBS] }, {
				format => $filter->{format} || 'scalar',
				code => $filter->{'sub'},
			};
		}
	}
}

sub filter {
	my ($self, $data) = @_;
	for my $filter (@{ $self->[SUBS] }) {
		if ($filter->{format} eq 'scalar') {
			$filter->{code}->(\$data);
		}
		else {
			my $lines = [split /(?:\n)/, $data];
			$filter->{code}->($lines);
			$data = join '', @$lines;
		}
	}
	# inplace edit
	$_[1] = $data;
}

1;
__END__

=pod

=head1 NAME

HTML::Template::Compiled::Filter - Filter functions for HTML::Template::Compiled

=cut

