package HTTP::ProxyPAC::Result;
use strict;
use Carp;

sub parse {
    my($class, $string, $url) = @_;
    my @res = split /\s*;\s*/, $string;
    map $class->_parse($_, $url), @res;
}

sub _parse {
    my($class, $string, $url) = @_;

    $string =~ s/^(DIRECT|PROXY|SOCKS)\s*//
        or Carp::croak("Can't parse FindProxyForURL() return value: $string");

    my $self;
    $self->{type} = $1;

    if ($self->{type} ne 'DIRECT') {
        my $proxy = URI->new;
        $proxy->scheme('http');
        $proxy->host_port($string);

        $self->{lc($self->{type})} = $proxy;
    }
    bless $self, $class;
}
sub direct { $_[0]->{type} eq 'DIRECT' }
sub proxy  { $_[0]->{proxy} }
sub socks  { $_[0]->{socks} }
1;
__END__

=head1 NAME

HTTP::ProxyPAC::Result - Result object from HTTP::ProxyPAC find_proxy

=head1 SYNOPSIS

  my $pac = HTTP::ProxyPAC->new($url);
  my $res = $pac->find_proxy('http://www.google.com/');

  $res->direct;
  $res->proxy;
  $res->socks;

=head1 DESCRIPTION

HTTP::ProxyPAC::Result is the class of the result object from the 
find_proxy method of HTTP::ProxyPAC.

=head1 METHODS

=over 4

=item direct

Boolean to indicate whether the result is DIRECT or not.

=item proxy

URI object for the proxy server URL if the result is PROXY, otherwise undef.

=item socks

URI object for the socks server URL if the result is SOCKS, otherwise undef.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::ProxyPAC>

=cut
