package Langertha::Holmgang::Sim::Linux::RedisService;
# ABSTRACT: Redis from the service alone (services.redis-server.running) — redis-cli connection, auth, PING, CONFIG GET and redis-server -v

use strict;
use warnings;
use utf8;

our $VERSION = '0.001';


sub _svc { my ($dev) = @_; return ( $dev->{services} || {} )->{'redis-server'} }


sub installed { return _svc( $_[0] ) ? 1 : 0 }

sub _conf {
    my ($dev) = @_;
    my $t = ( _svc($dev) || {} )->{running} // '';
    my %c;
    for my $l ( split /\n/, $t ) {
        $l =~ s/\A\s+//;
        next if $l eq '' || $l =~ /\A#/;
        my ( $k, $v ) = $l =~ /\A(\S+)\s*(.*?)\s*\z/ or next;
        $c{ lc $k } = $v;    # die letzte Zeile gewinnt (wie Redis)
    }
    return \%c;
}

sub _addrs {
    my ($dev) = @_;
    my @a = ( '127.0.0.1', '::1' );
    for my $i ( values %{ $dev->{interfaces} || {} } ) { push @a, map { s{/\d+\z}{}r } @{ $i->{addr} || [] } }
    return @a;
}

# Lauscht Redis auf $host?
sub _listens {
    my ( $dev, $host ) = @_;
    my $c = _conf($dev);
    my $v6 = $host =~ /:/;
    return 1 unless defined $c->{bind};
    for my $b ( split ' ', $c->{bind} ) {
        $b =~ s/\A-//;
        return 1 if $b eq '*' && !$v6 || $b eq '0.0.0.0' && !$v6 || ( $b eq '::*' || $b eq '::' ) && $v6;
        return 1 if $b eq $host;
    }
    return 0;
}


sub cli {
    my ( $dev, $av, $host_name ) = @_;
    my @a = @$av;
    my ( $h, $port, $pw, $nowarn, @cmd ) = ( '127.0.0.1', 6379 );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-h' ) { $h = shift(@a) // '' }
        elsif ( $x eq '-p' ) { $port = shift(@a) // '' }
        elsif ( $x eq '-a' || $x eq '--pass' ) { $pw = shift(@a) // '' }
        elsif ( $x eq '--user' || $x eq '-n' || $x eq '-u' ) { shift @a }
        elsif ( $x eq '--no-auth-warning' ) { $nowarn = 1 }
        elsif ( $x eq '--raw' || $x eq '--no-raw' || $x eq '-c' ) { }
        elsif ( $x eq '-v' || $x eq '--version' ) { return ( 'redis-cli 7.0.15', 1 ) }
        elsif ( $x =~ /\A-/ && !@cmd ) { return ( '', 0, join( ' ', 'redis-cli', @$av ) ) }
        else { push @cmd, $x, @a; last }
    }
    my @out;
    push @out, "Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe." if defined $pw && !$nowarn;
    $h = '127.0.0.1' if $h eq 'localhost';
    $h = '::1' if $h eq 'ip6-localhost';
    my $svc = _svc($dev) || {};
    my $mine = grep { $_ eq $h } _addrs($dev);
    if ( !$svc->{active} || "$port" ne ( _conf($dev)->{port} // '6379' ) || !$mine || !_listens( $dev, $h ) ) {
        my $hp = $h =~ /:/ ? "$h:$port" : "$h:$port";
        return ( join( "\n", @out, "Could not connect to Redis at $hp: Connection refused" ), 0 );
    }
    return ( join( "\n", @out ), 0, join( ' ', 'redis-cli', @$av ) ) unless @cmd;    # interaktiv
    my $c = _conf($dev);
    my $need = defined $c->{requirepass} && length $c->{requirepass};
    ( my $want = $c->{requirepass} // '' ) =~ s/\A"(.*)"\z/$1/;
    my $authed = !$need;
    if ( $need && defined $pw ) {
        if   ( $pw eq $want ) { $authed = 1 }
        else                  { push @out, 'AUTH failed: WRONGPASS invalid username-password pair or user is disabled.' }
    }
    my $loop = $h eq '127.0.0.1' || $h eq '::1';
    if ( !$need && !$loop && ( $c->{'protected-mode'} // 'yes' ) eq 'yes' ) {
        return ( join( "\n", @out, 'DENIED Redis is running in protected mode because protected mode is enabled and no password is set for the default user.' ), 0 );
    }
    my $verb = uc $cmd[0];
    if ( $verb eq 'AUTH' ) {
        my $p = $cmd[-1] // '';
        return ( join( "\n", @out, $need && $p eq $want ? 'OK' : $need ? 'WRONGPASS invalid username-password pair or user is disabled.'
            : 'ERR AUTH <password> called without any password configured for the default user. Are you sure your configuration is correct?' ), $p eq $want ? 1 : 0 );
    }
    return ( join( "\n", @out, 'NOAUTH Authentication required.' ), 0 ) unless $authed;
    return ( join( "\n", @out, @cmd > 1 ? $cmd[1] : 'PONG' ), 1 ) if $verb eq 'PING';
    if ( $verb eq 'CONFIG' && uc( $cmd[1] // '' ) eq 'GET' && defined $cmd[2] ) {
        ( my $re = quotemeta lc $cmd[2] ) =~ s/\\\*/.*/g;
        my %all = ( bind => '* -::*', port => '6379', 'protected-mode' => 'yes', requirepass => '', %$c );
        for my $k ( sort grep {/\A$re\z/} keys %all ) {
            ( my $v = $all{$k} ) =~ s/\A"(.*)"\z/$1/;
            push @out, $k, $v;
        }
        return ( join( "\n", @out ), 1 );
    }
    return ( join( "\n", @out ), 0, join( ' ', 'redis-cli', @$av ) );
}


sub server {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    return ( 'Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=c4d1f6a1d3b5a9e2', 1 )
        if @a && ( $a[0] eq '-v' || $a[0] eq '--version' );
    my @opt = grep {/\A--/} @a;
    my %directive = map { $_ => 1 } qw( bind port protected-mode requirepass daemonize supervised loglevel logfile dir save
        dbfilename maxmemory maxmemory-policy maxclients databases timeout tcp-keepalive tcp-backlog pidfile appendonly );
    for my $o (@opt) {
        ( my $d = $o ) =~ s/\A--//;
        next if $directive{$d} || $d eq 'test-memory';
        return ( join( "\n", '', '*** FATAL CONFIG FILE ERROR (Redis 7.0.15) ***', 'Reading the configuration file, at line 2', ">>> '$d'",
            'Bad directive or wrong number of arguments' ), 0 );
    }
    return ( '', 0, join( ' ', 'redis-server', @$av ) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::RedisService - Redis from the service alone (services.redis-server.running) — redis-cli connection, auth, PING, CONFIG GET and redis-server -v

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  # from the Linux simulator
  my ( $out, $ok, $gap ) = Langertha::Holmgang::Sim::Linux::RedisService::cli( $dev, \@argv, $host );
  my ( $out, $ok, $gap ) = Langertha::Holmgang::Sim::Linux::RedisService::server( $dev, \@argv );

=head1 DESCRIPTION

For devices without the Redis state C<redis> (that one is modelled by
L<Langertha::Holmgang::Sim::Linux::Redis>); then everything Redis currently
uses is in the service itself.

Redis of a Debian 12 device of type C<linux> (cai-platform F<docs/entwurf-evals.md> §3.3.1):
the service C<redis-server> with C<config> (F</etc/redis/redis.conf>); what it
currently uses is in its C<running> (read at start/restart).

  services:
    redis-server: { active: true, config: /etc/redis/redis.conf, running: "bind 127.0.0.1 -::1\nrequirepass …\n" }

B<redis-cli> C<[-h host] [-p port] [-a password|--pass password] [--user u]
[--no-auth-warning] [--raw] command …>: the connection succeeds only when Redis
is running and listening on the address (last C<bind> line of the running state;
without C<bind> all addresses; C<-> before an address means "if present"; the
device's own addresses and 127.0.0.1/::1). With C<requirepass> every command
needs the right password (else C<NOAUTH>, a wrong one gives C<WRONGPASS>);
without a password C<protected-mode yes> rejects connections from outside. Output as
without a terminal (over SSH): raw, errors without "(error)". Modelled are
C<PING>, C<CONFIG GET pattern> and C<AUTH>; other commands are a gap in the
simulation. B<redis-server> C<-v|--version>; options that are not a directive
(e.g. C<--test-config>) end like in Redis with C<FATAL CONFIG FILE ERROR>.

=head2 installed

True when the device has a service C<redis-server>.

=head2 cli

C<redis-cli …>; returns C<( $output, $ok, $gap )>.

=head2 server

C<redis-server -v|--version>; other options without a directive: error like Redis.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
