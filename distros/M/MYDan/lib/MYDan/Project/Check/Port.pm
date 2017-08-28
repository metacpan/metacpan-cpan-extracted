package MYDan::Project::Check::Port;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;

#  port: 8080
#  type: tcp # type: udp  default 
#  host: abc.foo.org # host: 127.0.0.1 default

sub new
{
    my ( $class, %self ) = @_;
    confess "port undef.\n" unless defined $self{port};
 
    $self{host} ||= '127.0.0.1';
    $self{type} ||= 'tcp';

    bless \%self, ref $class || $class;
}

sub check
{
    my $this = shift;
    my ( $port, $type, $host ) = @$this{qw( port type host )};

    IO::Socket::INET->new(
         PeerAddr => "$host:$port", Blocking => 0,
         Timeout => 10, Type => SOCK_STREAM,
         Proto => $type
    )
    ? print "$type => $host:$port :OK\n" 
    : die "$type => $host:$port :FAIL\n";

}

1;
__END__
