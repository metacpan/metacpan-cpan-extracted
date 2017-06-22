package Log::Log4perl::Appender::Graylog;

# ABSTRACT: Log dispatcher writing to udp Graylog server
our $VERSION = '1.7'; # VERSION 1.7
my $VERSION = 1.7;
our @ISA = qw(Log::Log4perl::Appender);

use strict;
use warnings;

use Sys::Hostname;
use Data::UUID;
use POSIX qw(strftime);
use IO::Compress::Gzip qw( gzip $GzipError );
use IO::Socket;
use Data::DTO::GELF;
use Carp;
use Log::GELF::Util qw(
    :all
);

##################################################
# Log dispatcher writing to udp Graylog server
##################################################
# cmd line example echo -n '{ "version": "1.1", "host": "example.org", "short_message": "A short message", "level": 5, "_some_info": "foo" }' | nc -w0 -u graylog.xo.gy 12201
##################################################
sub new {
##################################################
    my $proto  = shift;
    my $class  = ref $proto || $proto;
    my %params = @_;

    my $self = {
        name     => "unknown name",
        PeerAddr => "",
        PeerPort => "",
        Proto    => "udp",
        Gzip     => 1,
        Chunked  => 0,
        %params,

    };
    bless $self, $class;

}

sub _create_socket {
    my ( $self, $socket_opts ) = @_;

    require IO::Socket::INET;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $socket_opts->{host},
        PeerPort => $socket_opts->{port},
        Proto    => $socket_opts->{protocol},
    ) or die "Cannot create socket: $!";

    return $socket;
}
##################################################
sub log {
##################################################
    my $self   = shift;
    my %params = @_;

    my $packet = Data::DTO::GELF->new(
        'full_message' => $params{'message'},
        'level'        => $params{level},
        'host'         => $params{server} || $params{host} || hostname(),
        '_uuid'        => Data::UUID->new()->create_str(),
        '_name'        => $params{name},
        '_category'    => $params{log4p_category},
        "_pid"         => $$,

    );

    my $msg     = validate_message( $packet->TO_HASH() );
    my $chunked = parse_size( $self->{Chunked} );
    $msg = encode($msg);
    $msg = compress($msg) if $self->{'Gzip'};
    my $socket = $self->_create_socket(
        {   'host'     => $self->{'PeerAddr'},
            'port'     => $self->{'PeerPort'},
            'protocol' => $self->{'Proto'}
        }
    );
    $socket->send($_) foreach enchunk( $msg, $chunked );
    $socket->close();

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Log4perl::Appender::Graylog - Log dispatcher writing to udp Graylog server

=head1 VERSION

version 1.7

=head1 SYNOPSIS

    use Log::Log4perl::Appender::Graylog;
 
    my $appender = Log::Log4perl::Appender::Graylog->new(
      PeerAddr => "glog.foo.com",
      PeerPort => 12209,
      Gzip => 1, # Glog2 usually requires gzip but can send plain text
    );
 
    $appender->log(message => "Log me\n");
 
    or
    log4perl.appender.SERVER          = Log::Log4perl::Appender::Graylog
    log4perl.appender.SERVER.layout = NoopLayout
    log4perl.appender.SERVER.PeerAddr = <ip>
    log4perl.appender.SERVER.PeerPort = 12201
    log4perl.appender.SERVER.Gzip    = 1

=head1 DESCRIPTION

This is a simple appender for writing to a graylog server.

    It relies on L<IO::Socket::INET>. L<Log::GELF::Util>. This sends in the 1.1
    format. 

=head1 NAME

Log::Log4perl::Appender::Graylog; - Log to a Graylog server

=head1 CONFIG

    log4perl.appender.SERVER          = Log::Log4perl::Appender::Graylog
    log4perl.appender.SERVER.layout = NoopLayout
    log4perl.appender.SERVER.PeerAddr = <ip>
    log4perl.appender.SERVER.PeerPort = 12201
    log4perl.appender.SERVER.Gzip    = 1
    log4perl.appender.SERVER.Chunked = <0|lan|wan> 
    
        layout This needs to be NoopLayout as we do not want any special formatting.
        Gzip Accepts an integer specifying if to compress the message. 
        Chunked Accepts an integer specifying the chunk size or the special string values lan or wan corresponding to 8154 or 1420 respectively.

=head1 EXAMPLE

Write a server quickly using the IO::Socket:
(based on orelly-perl-cookbook-ch17)

    use strict;
    use IO::Socket;
    my($sock, $oldmsg, $newmsg, $hisaddr, $hishost, $MAXLEN, $PORTNO);
    $MAXLEN = 8192;
    $PORTNO = 12201;
    $sock = IO::Socket::INET->new(LocalPort => $PORTNO, Proto => 'udp')
        or die "socket: $@";
    print "Awaiting UDP messages on port $PORTNO\n";
    $oldmsg = "This is the starting message.";
    while ($sock->recv($newmsg, $MAXLEN)) {
        my($port, $ipaddr) = sockaddr_in($sock->peername);
        $hishost = gethostbyaddr($ipaddr, AF_INET);
        print "Client $hishost said ``$newmsg''\n";
        $sock->send($oldmsg);
        $oldmsg = "[$hishost] $newmsg";
    } 
    die "recv: $!";

Start it and then run the following script as a client:

    use Log::Log4perl qw(:easy);
    my $conf = q{
            log4perl.category                  = WARN, Graylog
            log4perl.appender.Graylog           = Log::Log4perl::Appender::Graylog
            log4perl.appender.Graylog.PeerAddr  = localhost
            log4perl.appender.Graylog.PeerPort  = 12201
            log4perl.appender.Graylog.layout    = SimpleLayout
            
        };
    
    Log::Log4perl->init( \$conf );
    
    sleep(2);
    
    for ( 1 .. 10 ) {
        ERROR("Quack!");
        sleep(5);
    }

=head1 COPYRIGHT AND LICENSE

Copyright 2017 by Brandon "Dimentox Travanti" Husbands E<lt>xotmid@gmail.comE<gt> 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 AUTHOR

Brandon "Dimentox Travanti" Husbands <xotmid@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Brandon "Dimentox Travanti" Husbands.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
