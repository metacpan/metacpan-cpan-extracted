package Gtk::LWP::http;
require LWP::Protocol::http;

@ISA = qw(LWP::Protocol::http);

sub _new_socket {
	my ($self, $host, $port, $timeout) = @_;
	my $sock = $self->SUPER::_new_socket($host, $port, $timeout);
	bless $sock, "Gtk::io::INET";
}

sub request {
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    $timeout = 0; # so that Select isn't called
    $self->SUPER::request($request, $proxy, $arg, $size, $timeout);
}

1;

