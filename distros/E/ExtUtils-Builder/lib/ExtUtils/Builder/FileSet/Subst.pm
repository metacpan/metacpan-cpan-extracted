package ExtUtils::Builder::FileSet::Subst;
$ExtUtils::Builder::FileSet::Subst::VERSION = '0.019';
use strict;
use warnings;

use base 'ExtUtils::Builder::FileSet';

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{subst} = $args{subst} or Carp::croak("No subst given");
	return $self;
}

sub add_input {
	my ($self, $source) = @_;

	my $target = $self->{subst}->($source);
	$self->_pass_on($target);
	return $target;
}

1;
