package Language::Homespring::River;

$VERSION = 0.01;

use warnings;
use strict;

my $river_count = 0;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	my $options = shift;
	$self->{interp}		= $options->{interp};
	$self->{up_node}	= $options->{up_node} || undef;
	$self->{down_node}	= $options->{down_node} || undef;
	$self->{uid}		= ++$river_count;

	return $self;
}

1;
