package Eixo::Queue::SocketPairDriver;

use strict;
use Eixo::Base::Clase;

use Socket;
use IO::Handle;
use IO::Select;

has(

	a=>undef,
	b=>undef,

	t=>undef,
);

sub DESTROY{

	close $_[0]->{t} if($_[0]->{t});
}

sub open{

	my ($a, $b);

	socketpair($a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC);

	$a->autoflush(1);
	$b->autoflush(1);
	
	return __PACKAGE__->new(

		a=>$a,

		b=>$b,

	);
	
}

sub send{
	my ($self, $message) = @_;
	
	my $s = $self->{t};

	chomp($message);

	$message .= "\n";

	print $s $message;

}

sub receive{
	my ($self) = @_;

	my $s = $self->{t};

	my $ret = <$s>;

	$ret;
}


sub A{
	my ($self) = @_;

	close $self->{b};

	$self->__prepare($self->a);
}

sub B{
	my ($self) = @_;

	close $self->{a};

	$self->__prepare($self->b);
}

	sub __prepare{
		my ($self, $i) = @_;

		$self->{t} = $i;

	}

1;
