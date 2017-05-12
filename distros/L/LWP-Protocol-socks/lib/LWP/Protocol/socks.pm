##############################
package LWP::Protocol::http::socks;
require LWP::Protocol::http;
our @ISA = qw(LWP::Protocol::http);
our $VERSION = "1.7";
LWP::Protocol::implementor('http::socks' => 'LWP::Protocol::http::socks');

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{scheme} =~ s/::socks$//;
    $self;
}

sub _extra_sock_opts {
    my $self = shift;
    my($host, $port) = @_;
    my @extra_sock_opts = $self->SUPER::_extra_sock_opts(@_);
    #(@extra_sock_opts, SocksDebug =>1, @{$self->{proxy_sock_opts}});
    (@extra_sock_opts, @{$self->{proxy_sock_opts}});
}

##############################
package LWP::Protocol::http::socks::Socket;
require LWP::Protocol::http;
require IO::Socket::Socks;
require Net::HTTP;
our @ISA = qw(LWP::Protocol::http::SocketMethods IO::Socket::Socks Net::HTTP);

sub configure {
    my $self = shift;
    my $args = shift;

    my $connectAddr = $args->{ConnectAddr} = delete $args->{PeerAddr};
    my $connectPort = $args->{ConnectPort} = delete $args->{PeerPort};

    $self->SUPER::configure($args) or return;
    $self->http_configure($args);
}

# hack out the connect so it doesn't reconnect
sub http_connect {
    1;
}

##############################
package LWP::Protocol::https::socks;
require LWP::Protocol::https;
our @ISA = qw(LWP::Protocol::https);
LWP::Protocol::implementor('https::socks' => 'LWP::Protocol::https::socks');

sub new {
    my $self = shift->SUPER::new(@_);
    $self->{scheme} =~ s/::socks$//;
    $self;
}

sub _extra_sock_opts {
    my $self = shift;
    my($host, $port) = @_;
    my @extra_sock_opts = $self->SUPER::_extra_sock_opts(@_);
    (@extra_sock_opts, @{$self->{proxy_sock_opts}});
    #(@extra_sock_opts, @{$self->{proxy_sock_opts}});
}

##############################
package LWP::Protocol::https::socks::Socket;
require LWP::Protocol::https;
require IO::Socket::Socks;
use IO::Socket::SSL;
require Net::HTTPS;
our @ISA = qw(IO::Socket::SSL LWP::Protocol::https::Socket);

sub new {
    my $class = shift;
    my %args = @_;
    my $connectAddr = $args{ConnectAddr} = delete $args{PeerAddr};
    my $connectPort = $args{ConnectPort} = delete $args{PeerPort};
    my $socks = new IO::Socket::Socks(%args);
    $args{PeerAddr} = $connectAddr;
    $args{PeerPort} = $connectPort;
    delete $args{ProxyAddr};
    delete $args{ProxyPort};
    delete $args{ConnectAddr};
    delete $args{ConnectPort};
    
    unless ($socks && $class->start_SSL($socks, %args)) {
        my $status = 'error while setting up ssl connection';
        if ($@) {
            $status .= " ($@)";
        }
        die($status);
    }
    
    $socks->http_configure(\%args);
    $socks;
}

# hack out the connect so it doesn't reconnect
sub http_connect {
    1;
}

##############################
package LWP::Protocol::socks;
require LWP::Protocol;
our @ISA = qw(LWP::Protocol);

sub request {
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    my $url = $request->uri;
    my $scheme = $url->scheme;

    my $protocol = LWP::Protocol::create("$scheme\::socks", $self->{ua});
    $protocol->{proxy_sock_opts} = [ProxyAddr => $proxy->host,
				    ProxyPort => $proxy->port,
				    ];

    # [RT 48172] Adding user/pass functionality
    if ( $proxy->userinfo() ) {
	push(@{$protocol->{proxy_sock_opts}},
	     AuthType => 'userpass',
	     Username => $proxy->user(),
	     Password => $proxy->pass(),
	    );
    }

    $protocol->request($request, undef, $arg, $size, $timeout);
}

1;

__END__

=head1 NAME

LWP::Protocol::socks - adds support for the socks protocol and proxy facility

=head1 SYNOPSIS

use LWP::Protocol::socks;

=head1 DESCRIPTION

Use this package when you wish to use a socks proxy for your
connections.

It provides some essential hooks into the LWP system to implement a
socks "scheme" similar to http for describing your socks connection,
and can be used to proxy either http or https connections.

The use case is to use LWP::UserAgent's proxy method to register your
socks proxy like so:

 $ua->proxy([qw(http https)] => 'socks://socks.yahoo.com:1080');

Then just use your $ua object as usual!

=head1 EXAMPLES

 #!/usr/local/bin/perl
 use strict;
 use LWP::UserAgent;

 my $ua = new LWP::UserAgent(agent => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.5) Gecko/20060719 Firefox/1.5.0.5');
 # for socks5, use socks like so:
 $ua->proxy([qw(http https)] => 'socks://socks.yahoo.com:1080');
 # for socks4, use socks4 like so:
 $ua->proxy([qw(http https)] => 'socks4://socks.yahoo.com:1080');
 my $response = $ua->get("http://www.freebsd.org");
 print $response->code,' ', $response->message,"\n";
 my $response = $ua->get("https://www.microsoft.com");
 print $response->code,' ', $response->message,"\n";

=head1 NOTES

I don't have much time to contribute to this.  If you'd like to
contribute, please fork https://github.com/scr/cpan and send me a pull
request.

=head1 AUTHORS

Sheridan C Rawlins E<lt>F<sheridan.rawlins@yahoo.com>E<gt>

Oleg G E<lt>F<oleg@cpan.org>E<gt>
