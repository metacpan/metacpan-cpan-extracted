package Jenkins::NotificationListener;
use strict;
use warnings;
our $VERSION = '0.06';

use Net::Jenkins;
use Net::Jenkins::Job;
use Net::Jenkins::Job::Build;
use Jenkins::Notification;
use AnyEvent::Socket;
use Moose;
use methods;
use JSON::XS;

our @ISA = ( 'Moose::Object', 'Exporter' );
our @EXPORT = qw(parse_jenkins_notification);

has host => (is => 'rw');

has port => (is => 'rw', isa => 'Int');

has on_notify => (is => 'rw');

has on_error => (is => 'rw', default => sub { 
    return sub { warn @_; };
});

sub parse_jenkins_notification {
    my $json = shift;
    my $args = decode_json $json;
    return Jenkins::Notification->new( %$args , raw_json => $json );
}

method start ($prepare_cb) {
    return tcp_server $self->host, $self->port , sub {
        my ($fh, $host, $port) = @_;
        my $json = '';
        my $buf = '';
        while( my $bytes = sysread $fh, $buf, 1024 ) {
            $json .= $buf;
        }
        eval {
            if( $json ) {
                $self->on_notify->( 
                    parse_jenkins_notification($json)
                );
            } else {
                die 'Request body is empty.';
            }
        };
        if ( $@ ) {
            $self->on_error->( $@ );
        }
    }, $prepare_cb;
}

1;
__END__

=head1 NAME

Jenkins::NotificationListener - is a TCP server that listens to messages from Jenkins Notification plugin.

=head1 SYNOPSIS

    use Jenkins::NotificationListener;
    Jenkins::NotificationListener->new( host => $host , port => $port , on_notify => sub {
        my $payload = shift;   # Jenkins::Notification;
        print $payload->name , " #" , $payload->build->number, " : " , $payload->status 
                    , " : " , $payload->phase
                    , " : " , $payload->url
                    , "\n";

    })->start;

=head1 DESCRIPTION

Jenkins::NotificationListener is a simple TCP server listens to messages from Jenkins' Notification plugin,

L<Jenkins::NotificationListener> uses L<AnyEvent::Socket> to create tcp server object, so it's a non-blocking implementation.

This tcp server reads JSON format notification from Jenkins Notification plugin, and creates payload object L<Jenkins::Notification>.
the payload object is built with L<Net::Jenkins::Job>,
L<Net::Jenkins::Job::Build> objects from the information that is provided from
notification json.

By using L<Jenkins::NotificationListener>, you can simple use the payload object to interact with Jenkins server.

To test your Jenkins notification plugin, you can also use L<jenkins-notification-listener.pl> script.

    $ jenkins-notification-listener.pl

=head1 EXPORTED FUNCTION

    use Jenkins::NotificationListener;   # export parse_jenkins_notification function
    my $notification = parse_jenkins_notification($json);
    $notification;   # Jenkins::Notification object
    $notification->job;
    $notification->build;

=head1 INSTALLATION

    $ cpan Jenkins::Notification

    $ cpanm Jenkins::Notification

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<Net::Jenkins>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
