package Hypersonic::UA::Pool;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant {
    MAX_PER_HOST  => 6,
    MAX_TOTAL     => 100,
    MAX_HOSTS     => 256,
    IDLE_TIMEOUT  => 60,
};

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max_per_host = $opts->{max_per_host} // MAX_PER_HOST;
    my $max_hosts = $opts->{max_hosts} // MAX_HOSTS;

    $class->gen_pool_structures($builder, $max_per_host, $max_hosts);
    $class->gen_pool_helpers($builder);
    $class->gen_xs_init($builder);
    $class->gen_xs_get($builder);
    $class->gen_xs_put($builder);
    $class->gen_xs_remove($builder);
    $class->gen_xs_clear($builder);
    $class->gen_xs_prune($builder);
    $class->gen_xs_stats($builder);
    $class->gen_xs_is_alive($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::Pool::init'     => { source => 'xs_pool_init', is_xs_native => 1 },
        'Hypersonic::UA::Pool::get'      => { source => 'xs_pool_get', is_xs_native => 1 },
        'Hypersonic::UA::Pool::put'      => { source => 'xs_pool_put', is_xs_native => 1 },
        'Hypersonic::UA::Pool::remove'   => { source => 'xs_pool_remove', is_xs_native => 1 },
        'Hypersonic::UA::Pool::clear'    => { source => 'xs_pool_clear', is_xs_native => 1 },
        'Hypersonic::UA::Pool::prune'    => { source => 'xs_pool_prune', is_xs_native => 1 },
        'Hypersonic::UA::Pool::stats'    => { source => 'xs_pool_stats', is_xs_native => 1 },
        'Hypersonic::UA::Pool::is_alive' => { source => 'xs_pool_is_alive', is_xs_native => 1 },
    };
}

sub gen_pool_structures {
    my ($class, $builder, $max_per_host, $max_hosts) = @_;

    $builder->line('#include <string.h>')
      ->line('#include <time.h>')
      ->line('#include <unistd.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <sys/select.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <errno.h>')
      ->blank;

    $builder->line("#define POOL_MAX_PER_HOST $max_per_host")
      ->line("#define POOL_MAX_HOSTS $max_hosts")
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int      fd;')
      ->line('    int      tls;')
      ->line('    time_t   last_used;')
      ->line('    int      in_use;')
      ->line('} PoolConn;')
      ->blank;

    $builder->line('typedef struct {')
      ->line('    char     host[256];')
      ->line('    uint16_t port;')
      ->line('    int      tls;')
      ->line('    int      count;')
      ->line("    PoolConn conns[POOL_MAX_PER_HOST];")
      ->line('} PoolBucket;')
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int         max_per_host;')
      ->line('    int         max_total;')
      ->line('    int         idle_timeout;')
      ->line('    int         total_count;')
      ->line('    int         hits;')
      ->line('    int         misses;')
      ->line("    PoolBucket  buckets[POOL_MAX_HOSTS];")
      ->line('    int         bucket_count;')
      ->line('} ConnectionPool;')
      ->blank;

    $builder->line('static ConnectionPool g_pool;')
      ->blank;
}

sub gen_pool_helpers {
    my ($class, $builder) = @_;

    # Find bucket by host:port:tls
    $builder->line('static PoolBucket* pool_find_bucket(const char* host, uint16_t port, int tls) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < g_pool.bucket_count; i++) {')
      ->line('        PoolBucket* b = &g_pool.buckets[i];')
      ->line('        if (b->port == port && b->tls == tls && strcasecmp(b->host, host) == 0) {')
      ->line('            return b;')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    # Create or find bucket
    $builder->line('static PoolBucket* pool_get_bucket(const char* host, uint16_t port, int tls) {')
      ->line('    PoolBucket* b = pool_find_bucket(host, port, tls);')
      ->line('    if (b) return b;')
      ->blank
      ->line('    if (g_pool.bucket_count >= POOL_MAX_HOSTS) return NULL;')
      ->blank
      ->line('    b = &g_pool.buckets[g_pool.bucket_count++];')
      ->line('    memset(b, 0, sizeof(PoolBucket));')
      ->line('    strncpy(b->host, host, 255);')
      ->line('    b->host[255] = \'\\0\';')
      ->line('    b->port = port;')
      ->line('    b->tls = tls;')
      ->line('    return b;')
      ->line('}')
      ->blank;

    # Check if socket is alive
    $builder->line('static int pool_check_alive(int fd) {')
      ->line('    fd_set rfds;')
      ->line('    FD_ZERO(&rfds);')
      ->line('    FD_SET(fd, &rfds);')
      ->blank
      ->line('    struct timeval tv = {0, 0};')
      ->line('    int ready = select(fd + 1, &rfds, NULL, NULL, &tv);')
      ->blank
      ->line('    if (ready > 0) {')
      ->line('        char peek;')
      ->line('        int n = recv(fd, &peek, 1, MSG_PEEK | MSG_DONTWAIT);')
      ->line('        if (n == 0) return 0;')
      ->line('        if (n < 0 && errno != EAGAIN && errno != EWOULDBLOCK) return 0;')
      ->line('    }')
      ->blank
      ->line('    return 1;')
      ->line('}')
      ->blank;

    # Close a connection
    $builder->line('static void pool_close_conn(PoolConn* c) {')
      ->line('    if (c->fd > 0) {')
      ->line('        close(c->fd);')
      ->line('    }')
      ->line('    c->fd = 0;')
      ->line('    c->in_use = 0;')
      ->line('}')
      ->blank;
}

sub gen_xs_init {
    my ($class, $builder) = @_;

    $builder->comment('Initialize connection pool')
      ->xs_function('xs_pool_init')
      ->xs_preamble
      ->line('int max_per_host;')
      ->line('int max_total;')
      ->line('int idle_timeout;')
      ->blank
      ->line('if (items > 3) croak("Usage: init([max_per_host], [max_total], [idle_timeout])");')
      ->blank
      ->line('max_per_host = (items > 0) ? SvIV(ST(0)) : 6;')
      ->line('max_total = (items > 1) ? SvIV(ST(1)) : 100;')
      ->line('idle_timeout = (items > 2) ? SvIV(ST(2)) : 60;')
      ->blank
      ->line('memset(&g_pool, 0, sizeof(g_pool));')
      ->line('g_pool.max_per_host = max_per_host;')
      ->line('g_pool.max_total = max_total;')
      ->line('g_pool.idle_timeout = idle_timeout;')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get {
    my ($class, $builder) = @_;

    $builder->comment('Get connection from pool')
      ->xs_function('xs_pool_get')
      ->xs_preamble
      ->line('const char* host;')
      ->line('uint16_t port;')
      ->line('int tls;')
      ->line('PoolBucket* b;')
      ->line('int i;')
      ->line('time_t now;')
      ->blank
      ->line('if (items != 3) croak("Usage: get(host, port, tls)");')
      ->blank
      ->line('host = SvPV_nolen(ST(0));')
      ->line('port = (uint16_t)SvIV(ST(1));')
      ->line('tls = SvIV(ST(2));')
      ->blank
      ->line('b = pool_find_bucket(host, port, tls);')
      ->line('if (!b || b->count == 0) {')
      ->line('    g_pool.misses++;')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('now = time(NULL);')
      ->blank
      ->line('for (i = 0; i < POOL_MAX_PER_HOST; i++) {')
      ->line('    PoolConn* c = &b->conns[i];')
      ->line('    if (c->fd <= 0 || c->in_use) continue;')
      ->blank
      ->line('    int age = now - c->last_used;')
      ->line('    if (age >= g_pool.idle_timeout) {')
      ->line('        pool_close_conn(c);')
      ->line('        b->count--;')
      ->line('        g_pool.total_count--;')
      ->line('        continue;')
      ->line('    }')
      ->blank
      ->line('    if (pool_check_alive(c->fd)) {')
      ->line('        c->in_use = 1;')
      ->line('        g_pool.hits++;')
      ->line('        ST(0) = sv_2mortal(newSViv(c->fd));')
      ->line('        XSRETURN(1);')
      ->line('    } else {')
      ->line('        pool_close_conn(c);')
      ->line('        b->count--;')
      ->line('        g_pool.total_count--;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('g_pool.misses++;')
      ->line('ST(0) = &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_put {
    my ($class, $builder) = @_;

    $builder->comment('Return connection to pool')
      ->xs_function('xs_pool_put')
      ->xs_preamble
      ->line('const char* host;')
      ->line('uint16_t port;')
      ->line('int tls;')
      ->line('int fd;')
      ->line('PoolBucket* b;')
      ->line('int i;')
      ->blank
      ->line('if (items != 4) croak("Usage: put(host, port, tls, fd)");')
      ->blank
      ->line('host = SvPV_nolen(ST(0));')
      ->line('port = (uint16_t)SvIV(ST(1));')
      ->line('tls = SvIV(ST(2));')
      ->line('fd = SvIV(ST(3));')
      ->blank
      ->line('if (g_pool.total_count >= g_pool.max_total) {')
      ->line('    close(fd);')
      ->line('    ST(0) = sv_2mortal(newSViv(0));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('b = pool_get_bucket(host, port, tls);')
      ->line('if (!b) {')
      ->line('    close(fd);')
      ->line('    ST(0) = sv_2mortal(newSViv(0));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->line('if (b->count >= g_pool.max_per_host) {')
      ->line('    time_t oldest_time = time(NULL);')
      ->line('    int oldest_idx = -1;')
      ->line('    for (i = 0; i < POOL_MAX_PER_HOST; i++) {')
      ->line('        if (b->conns[i].fd > 0 && !b->conns[i].in_use) {')
      ->line('            if (b->conns[i].last_used < oldest_time) {')
      ->line('                oldest_time = b->conns[i].last_used;')
      ->line('                oldest_idx = i;')
      ->line('            }')
      ->line('        }')
      ->line('    }')
      ->line('    if (oldest_idx >= 0) {')
      ->line('        pool_close_conn(&b->conns[oldest_idx]);')
      ->line('        b->count--;')
      ->line('        g_pool.total_count--;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('for (i = 0; i < POOL_MAX_PER_HOST; i++) {')
      ->line('    if (b->conns[i].fd <= 0) {')
      ->line('        b->conns[i].fd = fd;')
      ->line('        b->conns[i].tls = tls;')
      ->line('        b->conns[i].last_used = time(NULL);')
      ->line('        b->conns[i].in_use = 0;')
      ->line('        b->count++;')
      ->line('        g_pool.total_count++;')
      ->line('        ST(0) = sv_2mortal(newSViv(1));')
      ->line('        XSRETURN(1);')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('close(fd);')
      ->line('ST(0) = sv_2mortal(newSViv(0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_remove {
    my ($class, $builder) = @_;

    $builder->comment('Remove connection from pool')
      ->xs_function('xs_pool_remove')
      ->xs_preamble
      ->line('const char* host;')
      ->line('uint16_t port;')
      ->line('int tls;')
      ->line('int fd;')
      ->line('int i;')
      ->line('PoolBucket* b;')
      ->blank
      ->line('if (items != 4) croak("Usage: remove(host, port, tls, fd)");')
      ->blank
      ->line('host = SvPV_nolen(ST(0));')
      ->line('port = (uint16_t)SvIV(ST(1));')
      ->line('tls = SvIV(ST(2));')
      ->line('fd = SvIV(ST(3));')
      ->blank
      ->line('b = pool_find_bucket(host, port, tls);')
      ->line('if (!b) {')
      ->line('    ST(0) = sv_2mortal(newSViv(0));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('for (i = 0; i < POOL_MAX_PER_HOST; i++) {')
      ->line('    if (b->conns[i].fd == fd) {')
      ->line('        pool_close_conn(&b->conns[i]);')
      ->line('        b->count--;')
      ->line('        g_pool.total_count--;')
      ->line('        ST(0) = sv_2mortal(newSViv(1));')
      ->line('        XSRETURN(1);')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(0));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_clear {
    my ($class, $builder) = @_;

    $builder->comment('Clear all connections')
      ->xs_function('xs_pool_clear')
      ->xs_preamble
      ->blank
      ->line('int i, j;')
      ->line('for (i = 0; i < g_pool.bucket_count; i++) {')
      ->line('    PoolBucket* b = &g_pool.buckets[i];')
      ->line('    for (j = 0; j < POOL_MAX_PER_HOST; j++) {')
      ->line('        if (b->conns[j].fd > 0) {')
      ->line('            pool_close_conn(&b->conns[j]);')
      ->line('        }')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('g_pool.bucket_count = 0;')
      ->line('g_pool.total_count = 0;')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_prune {
    my ($class, $builder) = @_;

    $builder->comment('Prune expired connections')
      ->xs_function('xs_pool_prune')
      ->xs_preamble
      ->blank
      ->line('int i, j;')
      ->line('time_t now = time(NULL);')
      ->line('int pruned = 0;')
      ->blank
      ->line('for (i = 0; i < g_pool.bucket_count; i++) {')
      ->line('    PoolBucket* b = &g_pool.buckets[i];')
      ->line('    for (j = 0; j < POOL_MAX_PER_HOST; j++) {')
      ->line('        PoolConn* c = &b->conns[j];')
      ->line('        if (c->fd > 0 && !c->in_use) {')
      ->line('            int age = now - c->last_used;')
      ->line('            if (age >= g_pool.idle_timeout) {')
      ->line('                pool_close_conn(c);')
      ->line('                b->count--;')
      ->line('                g_pool.total_count--;')
      ->line('                pruned++;')
      ->line('            }')
      ->line('        }')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(pruned));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_stats {
    my ($class, $builder) = @_;

    $builder->comment('Get pool statistics')
      ->xs_function('xs_pool_stats')
      ->xs_preamble
      ->blank
      ->line('HV* stats = newHV();')
      ->blank
      ->line('hv_stores(stats, "total_connections", newSViv(g_pool.total_count));')
      ->line('hv_stores(stats, "hosts_tracked", newSViv(g_pool.bucket_count));')
      ->line('hv_stores(stats, "max_per_host", newSViv(g_pool.max_per_host));')
      ->line('hv_stores(stats, "max_total", newSViv(g_pool.max_total));')
      ->line('hv_stores(stats, "idle_timeout", newSViv(g_pool.idle_timeout));')
      ->line('hv_stores(stats, "hits", newSViv(g_pool.hits));')
      ->line('hv_stores(stats, "misses", newSViv(g_pool.misses));')
      ->blank
      ->line('double hit_rate = 0.0;')
      ->line('int total_requests = g_pool.hits + g_pool.misses;')
      ->line('if (total_requests > 0) {')
      ->line('    hit_rate = (double)g_pool.hits / total_requests;')
      ->line('}')
      ->line('hv_stores(stats, "hit_rate", newSVnv(hit_rate));')
      ->blank
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)stats));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_alive {
    my ($class, $builder) = @_;

    $builder->comment('Check if fd is alive')
      ->xs_function('xs_pool_is_alive')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: is_alive(fd)");')
      ->blank
      ->line('int fd = SvIV(ST(0));')
      ->line('int alive = pool_check_alive(fd);')
      ->blank
      ->line('ST(0) = alive ? &PL_sv_yes : &PL_sv_no;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;

__END__

=head1 NAME

Hypersonic::UA::Pool - Connection pool for Hypersonic::UA

=head1 SYNOPSIS

    # Connection pooling is automatic in Hypersonic::UA
    # This module provides the internal implementation

    # Initialize pool
    Hypersonic::UA::Pool::init($max_per_host, $max_total, $idle_timeout);

    # Get connection from pool
    my $fd = Hypersonic::UA::Pool::get($host, $port, $tls);

    # Return connection to pool
    Hypersonic::UA::Pool::put($host, $port, $tls, $fd);

    # Get pool statistics
    my $stats = Hypersonic::UA::Pool::stats();

=head1 DESCRIPTION

C<Hypersonic::UA::Pool> manages HTTP keep-alive connection pooling for
C<Hypersonic::UA>. It maintains a pool of open TCP connections organized by
host:port:tls, enabling connection reuse for improved performance.

=head1 FUNCTIONS

=head2 init

    Hypersonic::UA::Pool::init($max_per_host, $max_total, $idle_timeout);

Initialize the connection pool. Defaults:

    max_per_host  = 6     (connections per host:port:tls)
    max_total     = 100   (total connections)
    idle_timeout  = 60    (seconds before idle connection expires)

=head2 get

    my $fd = Hypersonic::UA::Pool::get($host, $port, $tls);

Get a pooled connection for the given host:port:tls. Returns undef if no
connection is available (pool miss).

=head2 put

    my $ok = Hypersonic::UA::Pool::put($host, $port, $tls, $fd);

Return a connection to the pool. The connection will be closed if:

=over 4

=item * Pool is at max capacity

=item * Host bucket is at max_per_host capacity (oldest evicted)

=back

=head2 remove

    Hypersonic::UA::Pool::remove($host, $port, $tls, $fd);

Remove a specific connection from the pool (e.g., after error).

=head2 clear

    Hypersonic::UA::Pool::clear();

Close all pooled connections.

=head2 prune

    my $count = Hypersonic::UA::Pool::prune();

Remove expired connections (past idle_timeout). Returns count pruned.

=head2 stats

    my $stats = Hypersonic::UA::Pool::stats();

Get pool statistics:

    {
        total_connections => 42,
        hosts_tracked     => 5,
        max_per_host      => 6,
        max_total         => 100,
        idle_timeout      => 60,
        hits              => 1234,
        misses            => 56,
        hit_rate          => 0.956,
    }

=head2 is_alive

    my $alive = Hypersonic::UA::Pool::is_alive($fd);

Check if a socket is still alive (not closed by peer).

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
