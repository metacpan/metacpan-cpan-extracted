package Log::Dispatch::Kafka;
BEGIN {
  $Log::Dispatch::Kafka::VERSION = '0.01';
}
BEGIN {
    $Log::Dispatch::Kafka::VERSION = '0.01';
}

use warnings;
use strict;

use Kafka::Client;
use Log::Dispatch::Output;
use base qw(Log::Dispatch::Output);

=head1 NAME

Log::Dispatch::Kafka - a simple dispatcher to send logging data to LinkedIn's Kafka

=head1 DESCRIPTION

Log::Dispatch::Kafka uses Kafka::Client to send log messages as events to an
instance of LinkedIn's <Kafka|http://sna-projects.com/kafka/>.

=head1 SYNOPSIS

In your log4perl.conf (or its moral equivalent), configure it as such:

log4perl.appender.KAFKA=Log::Dispatch::Kafka
log4perl.appender.KAFKA.host=192.168.1.100
log4perl.appender.KAFKA.port=9092
log4perl.appender.KAFKA.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.KAFKA.layout.ConversionPattern = %m

=head1 WARNING

Something to consider when using this; if your Kafka server isn't on the same
node as the application doing the logging, you're going to be opening a socket
and talking across the wire for every log message. This is probably not what
you want.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my %opts = @_;

    my $self = bless {}, $class;

    $self->_basic_init(%opts);
    $self->{'kafka'} = $self->_build_kafka(%opts);
    return $self;
}

sub _build_kafka {
    my $self = shift;
    my %opts = @_;

    $self->{'params'} = \%opts;

    my $host = $opts{'host'} || die 'You must configure a kafka host to connect to!';
    my $port = $opts{'port'} || 9092; # default port

    return Kafka::Client->new(host => $host, port => $port);
}


sub log_message {
    my $self = shift;
    my %p = @_;
    $self->{'kafka'}->send($p{'message'}, $p{'log4p_category'});
}

=head1 AUTHOR

Andrew Nelson, C<< <anelson at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Magazines.com, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
