use strict;
use warnings;
use Test::More;

use EV::Redis;

my $redis = EV::Redis->new;

ok !$redis->can('foo');

eval {
    $redis->foo(sub {});
};

ok $@;
ok $redis->can('foo');

{
    package My::Redis;
    our @ISA = ('EV::Redis');
    sub hello { 'from subclass' }
}
{
    my $s = My::Redis->new;
    isa_ok $s, 'My::Redis';
    is $s->hello, 'from subclass', 'subclass methods are found, not sent to Redis';
}

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    EV::Redis->new->on_error('not code');
    like $warn[0] // '', qr/not a code reference/, 'a non-code handler warns';
}

{
    my $got;
    my $h = sub { $got = 'passed' };
    my $r = EV::Redis->new;
    $r->on_error($h);
    $h = sub { $got = 'reassigned' };
    $r->connect_unix('/nonexistent/ev-redis-test.sock');
    is $got, 'passed', 'a handler is the code reference passed, not the caller variable';
}

{
    my $fake = bless {}, 'EV::Redis';
    eval { $fake->is_connected };
    like $@, qr/not made by new/, 'a hash-based object croaks instead of crashing';
    undef $fake;
    pass 'and is destroyed quietly';

    my $r = EV::Redis->new;
    $r->DESTROY;
    eval { $r->is_connected };
    like $@, qr/destroyed/, 'a method after an explicit DESTROY croaks';
    undef $r;
    pass 'and the implicit DESTROY after it is a no-op';
}

# croaks name the caller's line, not one of this module's
{
    my $r = EV::Redis->new;
    my $line;
    eval { $line = __LINE__; $r->get('k') };
    like $@, qr/connection required .* at \Q$0\E line $line\.$/, 'a method made by AUTOLOAD';
    eval { $line = __LINE__; $r->command('get', 'k') };
    like $@, qr/connection required .* at \Q$0\E line $line\.$/, 'command() itself';
    # a pending reconnect lets command() reach its arguments
    my $q = EV::Redis->new(path => '/nonexistent/redis.sock', reconnect => 1, on_error => sub {});
    eval { $line = __LINE__; $q->set('k', "\x{263a}") };
    like $@, qr/Wide character .* at \Q$0\E line $line\.$/, 'a wide character';
    my $latin1 = "caf\x{e9}";
    utf8::upgrade($latin1);
    eval { $q->set('k', $latin1) };
    is $@, '', 'an upgraded Latin-1 string is not wide';
    $q->disconnect;
    eval { $line = __LINE__; EV::Redis->new(path => '/tmp/' . ('x' x 300)) };
    like $@, qr/too long .* at \Q$0\E line $line\.$/, 'a croak inside new()';
    my $wrapper = sub { $r->get('k') };
    eval { $line = __LINE__; $wrapper->() };
    like $@, qr/ at \Q$0\E line @{[ $line - 1 ]}\.$/, 'a caller of our own still names its line';

    my $after;
    local $SIG{__WARN__} = sub { $after = $_[0] };
    eval { $r->get('k') };
    $line = __LINE__; warn "here";
    like $after, qr/ at \Q$0\E line $line\.$/, 'the caught croak leaves the current line intact';

    eval { $line = __LINE__; $r->connect("127.0.0.1\0x", 6379) };
    like $@, qr/host name contains a NUL byte at \Q$0\E line $line\.$/, 'a NUL in the host croaks';
    eval { $line = __LINE__; $r->connect_unix("/tmp/x\0y") };
    like $@, qr/path contains a NUL byte at \Q$0\E line $line\.$/, 'a NUL in the path croaks';
    eval { $line = __LINE__; $r->source_addr("127.0.0.1\0x") };
    like $@, qr/source_addr contains a NUL byte at \Q$0\E line $line\.$/, 'a NUL in source_addr croaks';
  SKIP: {
        skip 'no TLS support', 1 unless EV::Redis->has_ssl;
        eval { $line = __LINE__; EV::Redis->new(tls => 1, tls_ca => "/dev/null\0x") };
        like $@, qr/tls_ca contains a NUL byte at \Q$0\E line $line\.$/, 'a NUL in a TLS file name croaks';
    }
}

# perl's own warnings from the arguments name the caller and follow its warnings
{
    my $q = EV::Redis->new(path => '/nonexistent/redis.sock', reconnect => 1, on_error => sub {});
    my @w;
    local $SIG{__WARN__} = sub { push @w, $_[0] };
    my $line = __LINE__; $q->set('k', undef);
    like $w[0] // '', qr/uninitialized .* at \Q$0\E line $line\.$/, 'an undef argument warns at the caller';
    @w = ();
    { no warnings; $q->set('k', undef) }
    is_deeply \@w, [], '... and not where the caller turned warnings off';
    $q->disconnect;
}

# a copy would share the C object and free it with the original
{
    require Storable;
    my $r = EV::Redis->new;
    ok !eval { Storable::dclone($r); 1 }, 'dclone croaks';
    like $@, qr/cannot be serialized/, '... saying why';
}

done_testing;
