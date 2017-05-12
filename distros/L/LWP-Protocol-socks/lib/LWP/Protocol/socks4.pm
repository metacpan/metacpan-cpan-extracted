package LWP::Protocol::socks4;
require LWP::Protocol::socks;
our @ISA = qw(LWP::Protocol);

sub request {
    my($self, $request, $proxy, $arg, $size, $timeout) = @_;
    my $url = $request->uri;
    my $scheme = $url->scheme;
    my $protocol = LWP::Protocol::create("$scheme\::socks", $self->{ua});
    $protocol->{proxy_sock_opts} = [ProxyAddr => $proxy->host,
                    ProxyPort => $proxy->port,
                    SocksVersion => 4
                    ];
    
    if ( $proxy->userinfo() ) {
        push(@{$protocol->{proxy_sock_opts}},
         Username => $proxy->user()
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
 $ua->proxy([qw(http https)] => 'socks://socks.yahoo.com:1080');
 my $response = $ua->get("http://www.freebsd.org");
 print $response->code,' ', $response->message,"\n";
 my $response = $ua->get("https://www.microsoft.com");
 print $response->code,' ', $response->message,"\n";

=head1 SEE ALSO

L<URI::socks4>

L<LWP::Protocol::socks>

=head1 AUTHORS

Oleg G E<lt>F<oleg@cpan.org>E<gt>
