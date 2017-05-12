package Log::Any::Adapter::Mojo;

BEGIN {
    $Log::Any::Adapter::Mojo::VERSION = '0.06';
}

use strict;
use warnings;
use Log::Any::Adapter::Util qw(make_method);
use base qw(Log::Any::Adapter::Base);

use Mojo::Log;

sub init {
    my ($self) = @_;
    $self->{logger} ||= Mojo::Log->new;
}

# Create logging methods
#
foreach my $method ( Log::Any->logging_methods ) {
    my $mojo_method = $method;

    # Map log levels down to Mojo::Log levels where necessary
    #
    for ($mojo_method) {
        s/trace/debug/;
        s/notice/info/;
        s/warning/warn/;
        s/critical|alert|emergency/fatal/;
    }

    make_method(
        $method,
        sub {
            my $self = shift;
            my ( $pkg, $line ) = ( caller() )[ 0, 2 ];

            # Quick and dirty hack to get correct package and line number
            # into log line.
            no warnings;

            my $old_syswrite = *{*IO::Handle::syswrite}{CODE};
            local *IO::Handle::syswrite = sub {
                my $self = shift;
                my $l    = shift;

                $l =~ s/Log::Any::Adapter::Mojo:\d+/\Q$pkg\E:\Q$line\E/;
                $l =~ s/Mojo::EventEmitter:\d+/\Q$pkg\E:\Q$line\E/;
                $l =~ s/Mojo::Log:\d+/\Q$pkg\E:\Q$line\E/;

                return $self->$old_syswrite( $l, @_ );
            };

            return $self->{logger}->$mojo_method(@_);
        }
    );
}

# Create detection methods: is_debug, is_info, etc.
#
foreach my $method ( Log::Any->detection_methods ) {
    my $mojo_method = $method;

    # Map log levels down to Mojo::Log levels where necessary
    #
    for ($mojo_method) {
        s/trace/debug/;
        s/notice/info/;
        s/warning/warn/;
        s/critical|alert|emergency/fatal/;
    }

    make_method(
        $method,
        sub {
            my $self = shift;
            return $self->{logger}->$mojo_method(@_);
        }
    );
}

1;

__END__

=pod

=head1 NAME

Log::Any::Adapter::Mojo

=head1 SYNOPSIS

    use Mojo::Log;
    use Log::Any::Adapter;

    Log::Any::Adapter->set('Mojo', logger => Mojo::Log->new);

Mojolicious app:

    use Mojo::Base 'Mojolicious';

    use Log::Any::Adapter;

    sub startup {
        my $self = shift;

        Log::Any::Adapter->set('Mojo', logger => $self->app->log);
    }

Mojolicious::Lite app:

    use Mojolicious::Lite;

    use Log::Any::Adapter;

    Log::Any::Adapter->set('Mojo', logger => app->log);

=head1 DESCRIPTION

This Log::Any adapter uses L<Mojo::Log|Mojo::Log> for logging. Mojo::Log must
be initialized before calling I<set>. The parameter logger must
be used to pass in the logging object.

=head1 LOG LEVEL TRANSLATION

Log levels are translated from Log::Any to Mojo::Log as follows:

    trace -> debug
    notice -> info
    warning -> warn
    critical -> fatal
    alert -> fatal
    emergency -> fatal

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>,
L<Mojo::Log|Mojo::Log>

=head1 AUTHOR

Henry Tang

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011 Henry Tang

Log::Any::Adapter::Mojo is provided "as is" and without any express or
implied warranties, including, without limitation, the implied warranties
of merchantibility and fitness for a particular purpose.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=cut
