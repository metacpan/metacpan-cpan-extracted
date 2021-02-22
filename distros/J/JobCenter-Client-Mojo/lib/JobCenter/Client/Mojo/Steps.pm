package JobCenter::Client::Mojo::Steps;

use Mojo::Base -base;
use Mojo::IOLoop;

use Carp qw(croak);

has ioloop    => sub { Mojo::IOLoop->singleton };
has _remaining => sub { [] };
has _errcb => sub { sub { say STDERR "caught >>> $_[0] <<<" } };

sub steps {
	my ($self, $cbs, $errcb, @args) = @_;
	croak "no callbacks" unless ref $cbs eq 'ARRAY';
	# todo: check that array elements are coderefs
	$self->_remaining($cbs);
	$self->_errcb($errcb) if ref $errcb eq 'CODE';
	
	$self->ioloop->next_tick(sub { $self->_next(@args) });
	return $self;
}

sub next {
	my ($self) = @_;
	return sub { $self->_next(@_) };
}

sub _next {
	my $self = shift;
	my $cb = shift @{$self->_remaining}
		or return;
	unless (eval { $cb->($self, @_); 1 }) {
		my $e = $@;
		eval { $self->_errcb->($e) };
		warn $@ if $@;
	}
}

#sub DESTROY {
#	say STDERR "destroying $_[0]";
#}

1;


=encoding utf8

=head1 NAME

JobCenter::Client::Mojo::Steps - simplistic chained callbacks

=cut

