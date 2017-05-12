package List::Enumerator::Sub;
use strict;
use warnings;

use base qw/List::Enumerator::Role/;
use overload
	'@{}' => \&getarray,
	fallback => 1;

__PACKAGE__->mk_accessors(qw/next_sub rewind_sub/);

sub BUILD {
	my ($self, $params) = @_;
	
	$self->next_sub($params->{next});
	$self->rewind_sub($params->{rewind} || sub {});
}

sub _next {
	my ($self, $new) = @_;

	local $_ = $self;
	$self->next_sub->($self);
}

sub _rewind {
	my ($self, $new) = @_;

	local $_ = $self;
	$self->rewind_sub->($self);
	$self;
}

sub getarray {
	my ($self) = @_;
	my @temp;
	tie @temp, __PACKAGE__, $self;
	\@temp;
}

sub TIEARRAY {
	my ($class, $arg) = @_;
	bless $arg, $class;
}

sub FETCHSIZE {
	0;
}

sub FETCH { #TODO orz orz orz
	my ($self, $index) = @_;
	$self->rewind;
	$self->next while ($index--);
	$self->next;
}

1;
__END__
