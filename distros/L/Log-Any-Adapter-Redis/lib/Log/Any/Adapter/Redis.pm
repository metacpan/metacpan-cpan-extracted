use 5.008001;
use strict;
use warnings;

package Log::Any::Adapter::Redis;
$Log::Any::Adapter::Redis::VERSION = '1.000';
# ABSTRACT: Simple adapter for logging to redis

use Log::Any::Adapter::Util ();
use RedisDB;
use Sys::Hostname;

use base qw/Log::Any::Adapter::Base/;

my $trace_level = Log::Any::Adapter::Util::numeric_level('trace');

sub new {
    my ( $class, @args ) = @_;
    return $class->SUPER::new(
        host         => 'localhost',
        port         => 6379,
        database     => 0,
        ignore_reply => 0,
        log_level    => $trace_level,
        log_hostname => 0,
        log_pid      => 0,
        @args
    );
}

sub init {
    my $self = shift;
    $self->{log_level} = Log::Any::Adapter::Util::numeric_level( $self->{log_level} )
      unless $self->{log_level} =~ /^\d+$/;
    if ( !exists $self->{redis_db} || ref( $self->{redis_db} ) ne 'RedisDB' ) {
        $self->{redis_db} = RedisDB->new(
            host     => $self->{host},
            port     => $self->{port},
            database => $self->{database}
        );
        $self->{key} = 'LOG' if !exists $self->{key};
    }
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';
    my $method_level = Log::Any::Adapter::Util::numeric_level($method);
    *{$method} = sub {
        my ( $self, $text ) = @_;
        return if $method_level > $self->{log_level};
        my $msg = sprintf( "[%s]", scalar(localtime) );
        $msg .= sprintf( "[%s]", hostname() ) if $self->{log_hostname};
        $msg .= sprintf( "[%s]", $$ )         if $self->{log_pid};
        $msg .= sprintf( " %s",  $text );
        if ( $self->{ignore_reply} ) {
            $self->{redis_db}->send_command( 'rpush', $self->{key}, $msg, RedisDB::IGNORE_REPLY );
        } else {
            $self->{redis_db}->rpush( $self->{key}, $msg );
        }
    };
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';
    my $base = substr( $method, 3 );
    my $method_level = Log::Any::Adapter::Util::numeric_level($base);
    *{$method} = sub {
        return !!( $method_level <= $_[0]->{log_level} );
    };
}

!0;    # 3a59124cfcc7ce26274174c962094a20

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Redis - Simple adapter for logging to redis

=head1 SYNOPSIS

    use Log::Any::Adapter ('Redis',
        host         => 'localhost',
        port         => '6379',
        key          => 'LOG',       # list name
        log_hostname => 0,
        log_pid      => 0,
        database     => 0
    );

    # or, using the defaults

    use Log::Any::Adapter ('Redis');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('Redis',
        host         => 'localhost',
        port         => '6379',
        key          => 'LOG',
        log_hostname => 0,
        log_pid      => 0,
        database     => 0
    );

    # with minimum level 'warn'

    use Log::Any::Adapter (
        'Redis', log_level => 'warn'
    );

    # re-use existing RedisDB object

    use Log::Any::Adapter (
        'Redis', redis_db => $my_redis_db
    );

=head1 DESCRIPTION

This simple L<Log::Any|Log::Any> adapter logs (RPUSH) each message to the
specified list in redis, with a datestamp prefix. This Approach is useful
when you have several processes, maybe even running on different machines,
and need a fast, central logging solution. An example logwriter is included
in the examples.

The C<log_level> attribute may be set to define a minimum level to log.

Category is ignored.

=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>

=head1 AUTHOR

Michael Langner, mila at cpan dot org

The module is heavily based on Log::Any::Adapter::File by Jonathan Swartz and David Golden.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Michael Langner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
