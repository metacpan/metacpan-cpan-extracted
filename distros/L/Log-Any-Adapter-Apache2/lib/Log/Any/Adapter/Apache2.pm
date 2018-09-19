package Log::Any::Adapter::Apache2;

use 5.008001;
use strict;
use warnings;

use Apache2::RequestRec     ();
use Apache2::RequestUtil    ();
use Log::Any::Adapter::Util ();
use base qw(Log::Any::Adapter::Base);

our $VERSION = "0.01";

sub init {
    my $self = shift;

    my $r = Apache2::RequestUtil->request;
    my $s = $r->server;

    $self->{logger}    //= $r->log;
    $self->{log_level} //= $s->loglevel;

    $self->{log_level} //= Log::Any::Adapter::Util::numeric_level('trace');

    return;
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    my $apache2_method = _map_level($method);

    Log::Any::Adapter::Util::make_method(
        $method,
        sub {
            my $self = shift;

            return $self->{logger}->$apache2_method(@_);
        }
    );
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    my $base = substr( $method, 3 );

    my $shift_base = _shift_level($base);

    my $method_level = Log::Any::Adapter::Util::numeric_level($shift_base);

    Log::Any::Adapter::Util::make_method(
        $method,
        sub {
            my $self = shift;

            return !!( $method_level <= $self->{log_level} );
        }
    );
}

# Levels
#                7     6    5      4       3     2        1     0
#     any: trace debug info notice warning error critical alert emergency
# apache2: -     debug info notice warn    error crit     alert emerg

sub _shift_level {
    my ($level) = @_;

    for ($level) {
        s/trace/debug/;
    }

    return $level;
}

sub _map_level {
    my ($level) = @_;

    for ($level) {
        s/trace/debug/;
        s/warning/warn/;
        s/critical/crit/;
        s/emergency/emerg/;
    }

    return $level;
}

1;

__END__

=encoding utf-8

=head1 NAME

Log::Any::Adapter::Apache2 - Log::Any adapter for Apache2::Log

=head1 SYNOPSIS

    use Log::Any::Adapter ('Apache2');

    or

    use Log::Any::Adapter;
    Log::Any::Adapter->set('Apache2');

=head1 DESCRIPTION

This Log::Any adapter uses Apache2::Log for logging. There are no parameters. The logging level is specified in the Apache configuration file.

=head1 LOG LEVEL TRANSLATION
 
Log levels are translated from Log::Any to Apache2::Log as follows:
 
    trace -> debug;
    warning -> warn;
    critical ->crit;
    emergency -> emerg;

=head1 SEE ALSO
 
=over 4
 
=item *
 
L<Log::Any>
 
=item *
 
L<Log::Any::Adapter>
 
=item *
 
L<Apache2::Log>
 
=back

=head1 LICENSE

Copyright (C) Mikhail Ivanov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Mikhail Ivanov E<lt>m.ivanych@gmail.comE<gt>

