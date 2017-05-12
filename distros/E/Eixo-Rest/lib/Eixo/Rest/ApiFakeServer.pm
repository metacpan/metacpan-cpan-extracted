package Eixo::Rest::ApiFakeServer;

use strict;
use Eixo::Base::Clase;

has(

	listeners=>{},

	cgi=>undef,

);

sub initialize{
	my ($self, %args) = @_;

	$self->{cgi} = $args{cgi};	
	$self->{listeners} = $args{listeners};	
	
	# we treat special routes, ie. with placeholders...

	my $routes = [];

	foreach my $r (keys(%{$args{listeners}})){

		if($r =~ /\:/){

			my $n = $r;

			while($r =~ /\:(\w+)/g){

				$n =~ s/\:$1/\[\^\/\]\+/;
			}

			$n .= '$';

			$n = qr/$n/;

			push @$routes, {

				tester=>sub {
			
					$_[0] =~ /$n/;
				
				},

				route=>$r
			}

		}
		else{
			unshift @$routes, {

				tester=>sub {

					$_[0] eq $r;
				},

				route=>$r
			}
		}

	}

	$self->{routes} = $routes;

	foreach(values(%{$self->{listeners}})){

		$_->{type} = "GET" unless($_->{type});
	}

	$self;
}

sub start{
	my ($self, $port) = @_;

	return Eixo::Rest::ApiFakeServerProcess::start_server(

		$port,

		$self
	);

}

sub process{
	my ($self, $cgi) = @_;

	$self->cgi($cgi);

	my $listener = $self->__getListener($cgi) || $self->__defaultListener;

	$self->__send(

		$listener
	);

}

sub __getListener{
	my ($self, $cgi) = @_;

	foreach my $r (@{$self->{routes}}){

		if($r->{tester}->($cgi->path_info)){

			my $method = $self->{listeners}->{$r->{route}};

			return $method if($method->{type} eq '*');

			return $method if(lc($method->{type}) eq lc($cgi->request_method));
		}
	}

}

sub __defaultListener{
	{}
}

sub __send{
	my ($self, $response) = @_;

	($response->{header}) ? $response->{header}->($self) : $self->__header;

	($response->{body}) ? $response->{body}->($self) : $self->__body;

}

sub __header{

	print "HTTP/1.0 200 OK\r\n";
	print $_[0]->cgi->header(-type  =>  'text/plain');
}

sub __body{

}

package Eixo::Rest::ApiFakeServerProcess;

use strict;
use parent qw(HTTP::Server::Simple::CGI);

sub start_server{
	my ($port, $api) = @_;

	my $server = __PACKAGE__->new;

	$server->{api} = $api;

	$server->port($port);
	
	$server->background();

}

sub handle_request{
	my ($self, $cgi) = @_;

	$self->{api}->process($cgi);

}

1;
