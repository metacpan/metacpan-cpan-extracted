package Log::Log4perl::Appender::Stomp;
our $VERSION = '1.000';

# ABSTRACT: Log messages via STOMP

use warnings;
use strict;

use Net::Stomp;

our @ISA = qw(Log::Log4perl::Appender);

sub new {
    my ($class, %options) = @_;

    my $self = {
        'name'       => $options{'name'}       || 'unknown',
        'hostname'   => $options{'hostname'}   || 'localhost',
        'port'       => $options{'port'}       || 61613,
        'topic_name' => $options{'topic_name'} || 'log',
        'connection' => undef,
        %options
    };

    bless($self, $class);

    return $self;
}

sub log { ## no critic
    my ($self, %params) = @_;

    my $stomp = $self->{'connection'};

    unless ($stomp) {

        $stomp = Net::Stomp->new(
            {
                'hostname' => $self->{'hostname'},
                'port'     => $self->{'port'}
            }
        );

        unless ($stomp->connect({ 'login' => 'noauth', 'passcode' => 'supportyet' })) {
            die('Connection to ', $self->{'hostname'}, ':', $self->{'port'}, " failed: $!");
        }

        $self->{'connection'} = $stomp;
    }

    return $stomp->send(
        {
            'destination' => sprintf('/topic/%s', $self->{'topic_name'}),
            'body'        => $params{'message'}
        }
    );
}

sub DESTROY {
    my ($self) = @_;

    if ($self->{'connection'}) {
        $self->{'connection'}->disconnect();
    }

    return;
}

1;



=pod

=head1 NAME

Log::Log4perl::Appender::Stomp - Log messages via STOMP

=head1 VERSION

version 1.000

=head1 SYNOPSIS

    use Log::Log4perl;

    # Default options are in $conf
    my $conf = qq(
        log4perl.category = WARN, STOMP

        log4perl.appender.STOMP                          = Log::Log4perl::Appender::Stomp
        log4perl.appender.STOMP.hostname                 = localhost
        log4perl.appender.STOMP.port                     = 61613
        log4perl.appender.STOMP.topic_name               = log
        log4perl.appender.STOMP.layout                   = PatternLayout
        log4perl.appender.STOMP.layout.ConversionPattern = %d %-5p %m%n
    );

    Log::Log4perl::init(\$conf);

    Log::Log4perl->get_logger("blah")->debug("...");

=head1 DESCRIPTION

This allows you to send log messages via the Streaming Text Orientated Messaging
Protocol to a message broker that supports STOMP, such as Apache's ActiveMQ.

This makes use of topics in ActiveMQ so that multiple consumers can receive the
log messages from multiple producers. It takes a similar approach as syslog
does but uses ActiveMQ to do the message handling.

=head1 CONFIGURATION AND ENVIRONMENT

You can change:

=over

=item * hostname

=item * port

=item * topic_name

=back

In the Log::Log4perl configuration.

=over

=item L<Log::Log4perl>

=item L<Net::Stomp>

=item ActiveMQ L<http://activemq.apache.org>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Log4perl::Appender::Stomp

You can also look for information at:

=over

=item * RT: CPAN's request tracker: L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Appender-Stomp>

=item * AnnoCPAN: Annotated CPAN documentation: L<http://annocpan.org/dist/Log-Log4perl-Appender-Stomp>

=item * CPAN Ratings: L<http://cpanratings.perl.org/d/Log-Log4perl-Appender-Stomp>

=item * Search CPAN: L<http://search.cpan.org/dist/Log-Log4perl-Appender-Stomp>

=back

=head1 AUTHOR

  Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Adam Flott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

