package HealthCheck::Diagnostic::Redis;

use strict;
use warnings;

use parent 'HealthCheck::Diagnostic';

use Carp;
use Redis::Fast;

# ABSTRACT: Check for Redis connectivity and operations in HealthCheck
use version;
our $VERSION = 'v0.0.4'; # VERSION

sub new {
    my ($class, @params) = @_;

    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        id    => 'redis',
        label => 'redis',
        %params,
    );
}

sub check {
    my ($self, %params) = @_;
 
    # Allow the diagnostic to be called as a class as well.
    if ( ref $self ) {
        $params{$_} = $self->{$_}
            foreach grep { ! defined $params{$_} } keys %$self;
    }
 
    # The host is the only required parameter.
    croak "No host" unless $params{host};
 
    return $self->SUPER::check(%params);
}

sub run {
    my ($self, %params) = @_;

    my $host     = $params{host};

    my $name        = $params{name};
    my $description = $name ? "$name ($host) Redis" : "$host Redis";

    # Add on the port if need be.
    $host .= ':6379' unless $host =~ /:\d+$/;

    # Connect to the host...
    my $redis;
    local $@;
    eval {
        local $SIG{__DIE__};
        $redis = Redis::Fast->new(
            server => $host,

            # HealthCheck should not reconnect
            reconnect => 0,

            # Make this quick...
            cnx_timeout => 0.5,
            read_timeout => 0.5,
            write_timeout => 0.5,
        );
    };
    return {
        status => 'CRITICAL',
        info   => "Error for $description: $@",
    } if $@;

    unless ($redis->ping) {
        return {
            status  => 'CRITICAL',
            info    => "Error for $description: Redis ping failed",
        };
    }

    my ($key, $error) = $redis->randomkey();
    return {
        status  => 'CRITICAL',
        info    => "Error for $description: Getting Random entry failed - $error",
    } if ($error);

    # At this point, the only way this fails is if there are no entries in the
    # Redis DB.
    if ($key) {
        my $val = $redis->get($key);
        return {
            status  => 'CRITICAL',
            info    => "Error for $description: Failed fetching value of key $key",
        } unless defined $val;
    }

    return {
        status => 'OK',
        info   => "Successful connection for $description",
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::Redis - Check for Redis connectivity and operations in HealthCheck

=head1 VERSION

version v0.0.4

=head1 SYNOPSIS

    use HealthCheck::Diagnostic::Redis;

    # Just check that we can connect to a host, and get a random value back.
    HealthCheck::Diagnostic::Redis->check(
        host => 'redis.example.com',
    );

=head1 DESCRIPTION

This Diagnostic will simply allow for an application to test for connectivity
to a Redis server, and additionally validate that it can successfully read keys
from that server.

=head1 ATTRIBUTES

=head2 name

A descriptive name for the connection test.
This gets populated in the resulting C<info> tag.

=head2 host

The server name to connect to for the test.
This is required.

=head1 DEPENDENCIES

L<Redis::Fast>
L<HealthCheck::Diagnostic>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 - 2020 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
