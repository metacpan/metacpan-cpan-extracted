package Log::Log4perl::Appender::Graylog;

# ABSTRACT: Log dispatcher writing to udp Graylog server
our $VERSION = '1.3'; # VERSION 1.3
my $VERSION=1.3;
our @ISA = qw(Log::Log4perl::Appender);

use strict;
use warnings;

use JSON -convert_blessed_universally;
use Sys::Hostname;
use Data::UUID;
use POSIX qw(strftime);
use IO::Socket;
use Data::DTO::GELF;

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
        %params,
    };

    bless $self, $class;
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
    # TODO: Use the gzip way, however the specs say it can send plain if there is no new line
    my $json = JSON->new->utf8->space_after->allow_nonref->convert_blessed;
    my $j_packet = $json->encode($packet);

    my $socket = IO::Socket::INET->new(
        PeerAddr => "$self->{'PeerAddr'}",
        PeerPort => $self->{'PeerPort'},
        Type     => SOCK_DGRAM,
        Proto    => 'udp'
    ) or die "Socket error";
    $socket->send( $j_packet . "\n" );

    $socket->close();

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Log4perl::Appender::Graylog - Log dispatcher writing to udp Graylog server

=head1 VERSION

version 1.3

=head1 SYNOPSIS

    use Log::Log4perl::Appender::Graylog;
 
    my $appender = Log::Log4perl::Appender::Graylog->new(
      PeerAddr => "glog.foo.com",
      PeerPort => 12209,
    );
 
    $appender->log(message => "Log me\n");

=head1 DESCRIPTION

This is a simple appender for writing to a graylog server.
It relies on L<IO::Socket::INET>. This sends in the 1.1
format. Hoever it does not gzip the message. There are plans
to use the gzip method later.

=head1 NAME

Log::Log4perl::Appender::Graylog; - Log to a Graylog server

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

=cut

=head1 AUTHOR

Brandon "Dimentox Travanti" Husbands <xotmid@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Brandon "Dimentox Travanti" Husbands.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
