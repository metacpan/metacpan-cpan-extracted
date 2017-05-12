package IO::Socket::Socks::Wrapped;

no warnings 'redefine';
use IO::Socket;
use IO::Socket::Socks::Wrapper;

our $VERSION = '0.17';
our $AUTOLOAD;

sub new {
	my ($class, $obj, $cfg) = @_;
	bless {orig => $obj, cfg => $cfg}, $class;
}

sub AUTOLOAD {
	my $self = shift;
	
	IO::Socket::Socks::Wrapper::_io_socket_connect_ref();
	
	local *IO::Socket::IP::connect = local *IO::Socket::connect = sub {
		return IO::Socket::Socks::Wrapper::_connect(@_, $self->{cfg}, 1);
	};
	
	$AUTOLOAD =~ s/^.+:://;
	$self->{orig}->$AUTOLOAD(@_);
}

sub isa {
	my $self = shift;
	$self->{orig}->isa(@_);
}

sub can {
	my $self = shift;
	$self->{orig}->can(@_);
}

sub DOES {
	my $self = shift;
	$self->{orig}->DOES(@_);
}

sub DESTROY {}

1;

__END__

=head1 NAME

IO::Socket::Socks::Wrapped - object wrapped by IO::Socket::Socks::Wrapper

=head1 SYNOPSIS

	use WWW::Mechanize;
	use IO::Socket::Socks::Wrapped;
	
	my $ua = WWW::Mechanize->new;
	my $s_ua = IO::Socket::Socks::Wrapped->new($ua, {
		ProxyAddr => 'localhost',
		ProxyPort => 1080
	});
	
	$s_ua->get("http://google.com"); # via proxy
	$ua->get("http://google.com"); # direct
	
	$s_ua->isa('WWW::Mechanize'); # true
	$s_ua->can('is_html'); # true
	print ref($s_ua); # IO::Socket::Socks::Wrapped

=head1 DESCRIPTION

C<IO::Socket::Socks::Wrapped> is representation of object wrapped by C<IO::Socket::Socks::Wrapper>. You may create it directly
by new() method or through IO::Socket::Socks::Wrapper::wrap_connection() subroutine. First parameter is original object, that
internally uses IO::Socket for creation of tcp connections. Second is proxy configuration (see L<IO::Socket::Socks::Wrapper>
documentation). New IO::Socket::Socks::Wrapped object will use proxy specified in configuration for tcp connections. Original
object also may be used, but it will make direct tcp connections. In fact new object uses original internally and has all it
methods. So if you'll change some behaviour of original object, behaviour of wrapped object also will be changed.

You can access original object this way:

	my $orig = $wrapped_object->{orig};

Wrapped object behaviour for UNIVERSAL methods (isa, can, DOES) is same as original object behaviour. So, the following is true

	$wrapped_object->isa('Original::Package');

=head1 SEE ALSO

L<IO::Socket::Socks::Wrapper>

=head1 COPYRIGHT

Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
