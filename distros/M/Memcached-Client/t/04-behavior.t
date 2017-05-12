#!/usr/bin/perl

use Memcached::Client qw{};
use Memcached::Client::Log qw{DEBUG LOG};
use Storable qw{dclone freeze thaw};
use t::Memcached::Manager qw{};
use t::Memcached::Mock qw{};
use t::Memcached::Servers qw{};
use Test::More;

my $tests = [['connect', 1,
              '->connect'],

             ['version',
              'Checking for version on all servers'],

             ['set',
              '->set without a key'],
             ['set', 'foo',
              '->set without a value'],
             ['set', 'foo', 'bar',
              '->set with a value'],
             ['set', ['37', 'llama'], 'bar',
              '->set with a pre-hashed key'],
             ['set_multi', ['teatime', 3], ['bagman', 'ludo'],
              '->set_multi with various keys'],

             ['add',
              '->add without a key'],
             ['add', 'foo',
              '->add without a value'],
             ['add', 'bar', 'baz',
              '->add with a value'],
             ['add', 'bar', 'foo',
              '->add with an existing value'],
             ['add_multi', ['teatime', 3], ['bagman', 'ludo'],
              '->set_multi with various pre-existing keys'],
             ['add_multi', ['porridge', 'salty'], ['complex', 'simple'], ['bagman', 'horace'],
              '->set_multi with various keys'],

             ['set', ['19', 'ding-dong'], 'bar',
              '->add with a pre-hashed key'],

             ['get',
              '->get without a key'],
             ['get', 'bang',
              '->get a non-existant value'],
             ['get', 'bar',
              '->get an existing value'],

             ['get', ['19', 'ding-dong'],
              '->get a value with a pre-hashed key'],

             ['get_multi',
              '->get_multi without a list'],
             ['get_multi', 'bar', 'foo', 'porridge',
              '->get with all keys set so far'],

             ['get_multi', ['37', 'llama'], 'bar', 'foo',
              '->get with all keys set so far'],

             ['replace',
              '->replace without a key'],
             ['replace', 'foo',
              '->replace without a value'],
             ['replace', 'baz', 'gorp',
              '->replace with a non-existent value'],
             ['replace', 'bar', 'gondola',
              '->replace with an existing value'],
             ['replace_multi', ['porridge', 'sweet'], ['complex', 'NP'], ['ludo', 'panopticon'],
              '->replace_multi with various keys'],

             ['get', 'bar',
              '->get to verify replacement'],

             ['get', 'a' x 256,
              '->get a key that is too large and does not exist'],

             ['set', 'b' x 256, 'lurch',
              '->set a key that is too large and does not exist'],

             ['replace', ['18', 'ding-dong'], 'bar',
              '->replace with a pre-hashed key and non-existent value'],
             ['replace', ['19', 'ding-dong'], 'baz',
              '->replace with a pre-hashed key and an existing value'],
             ['get', ['19', 'ding-dong'],
              '->get a value with a pre-hashed key'],

             ['append',
              '->append without a key'],
             ['append', 'foo',
              '->append without a value'],
             ['append', 'baz', 'gorp',
              '->append with a non-existent value'],
             ['append', 'bar', 'gorp',
              '->append with an existing value'],
             ['append_multi', ['porridge', ' and salty'], ['complex', ' != P'],
              '->append_multi with various keys'],

             ['get', 'bar',
              '->get to verify ->append'],

             ['append', ['18', 'ding-dong'], 'flagon',
              '->append with a pre-hashed key and non-existent value'],
             ['append', ['19', 'ding-dong'], 'flagged',
              '->append with a pre-hashed key and an existing value'],
             ['get', ['19', 'ding-dong'],
              '->get a value with a pre-hashed key'],

             ['prepend',
              '->prepend without a key'],
             ['prepend', 'foo',
              '->prepend without a value'],
             ['prepend', 'baz', 'gorp',
              '->prepend with a non-existent value'],
             ['prepend', 'foo', 'gorp',
              '->prepend with an existing value'],
             ['prepend_multi', ['porridge', 'We love '],
              '->prepend_multi with various keys'],


             ['get', 'foo',
              '->get to verify ->prepend'],

             ['delete',
              '->delete without a key'],
             ['delete', 'bang',
              '->delete with a non-existent key'],
             ['delete', 'foo',
              '->delete with an existing key'],
             ['delete_multi', 'complex', 'panopticon',
              '->delete_multi with various keys'],

             ['get', 'foo',
              '->get to verify ->delete'],

             ['add', 'foo', '1',
              '->add with a value'],
             ['get', 'foo',
              '->get to verify ->add'],

             ['incr',
              '->incr without a key'],
             ['incr', 'bang',
              '->incr with a non-existent key'],
             ['incr', 'foo',
              '->incr with an existing key'],
             ['incr', 'foo', '72',
              '->incr with an existing key and an amount'],
             ['get', 'foo',
              '->get to verify ->incr'],

             ['decr',
              '->decr without a key'],
             ['decr', 'bang',
              '->decr with a non-existent key'],
             ['decr', 'foo',
              '->decr with an existing key'],
             ['decr', 'foo', 18,
              '->decr with an existing key'],
             ['get', 'foo',
              '->get to verify ->decr'],

             ['get_multi', 'bar', 'foo',
              '->get with all keys set so far'],

             ['incr_multi', 'foo',
              '->incr_multi with various keys'],

             ['incr_multi', ['braga', 1, 17], ['foo', 7],
              '->incr_multi with various keys'],

             ['decr_multi', ['braga', 3], ['bartinate', 7, 33],
              '->decr_multi with various keys'],

             ['flush_all',
              '->flush_all to clear servers'],

             ['get_multi', 'bar', 'foo',
              '->get with all keys set so far']];

my $memcached = find_memcached ();
my $servers = t::Memcached::Servers->new;
my $manager = t::Memcached::Manager->new (memcached => $memcached, servers => $servers->servers);

# Everything can handle text
my @protocols = qw{Text};

# Only > 1.4 can handle Binary
push @protocols, 'Binary' if ($manager->vstring ge "001004000");

# Now that we have the version, we need to filter our tests
my $filtered = filter ($tests, $manager->vstring);

if ($memcached) {
    plan tests => (2 * (scalar @protocols) * (scalar @{$filtered} + 2));
    note "Using memcached $memcached";
} else {
    plan skip_all => 'No memcached found';
}

for my $runner (qw{sync async}) {
    for my $protocol (@protocols) {
        for my $selector (qw(Traditional)) {
            note sprintf "running %s/%s %s", $selector, $protocol, $runner;
            trace ("running %s/%s %s", $selector, $protocol, $runner) if DEBUG;
            my $namespace = join ('.', time, $$, '');
            # my $namespace = "llamas.";
            isa_ok (my $client = Memcached::Client->new (namespace => $namespace, protocol => $protocol, selector => $selector, servers => $servers->servers), 'Memcached::Client', "Get memcached client");
            isa_ok (my $mock = t::Memcached::Mock->new (namespace => $namespace, selector => $selector, servers => $servers->servers, version => $manager->version), 't::Memcached::Mock', "Get mock memcached client");
            my $candidate = $servers->error;
            &$runner ($selector, $protocol, $candidate, $client, $mock, freeze $filtered);
            trace ("Done with %s/%s %s", $selector, $protocol, $runner) if DEBUG;
            $manager->start ($candidate);
            $mock->start ($candidate);
        }
    }
}

sub async {
    my ($selector, $protocol, $candidate, $client, $mock, $tests) = @_;
    trace ("running %s/%s async", $selector, $protocol) if DEBUG;
    my @tests = @{thaw $tests};
    my $failure = int rand (scalar @tests - 20) + 10;
    note "Failing test $failure";
    my $cv = AE::cv;
    my $test; $test = sub {
        my ($method, @args) = @{shift @tests};
        my $msg = pop @args;
        trace ("%s is %s (%s)", $msg, $method, \@args) if DEBUG;
                $client->$method (@{dclone \@args}, sub {
                              my ($received) = @_;
                              my $expected = $mock->$method (@args);
                              my $succeed = is_deeply ($received, $expected, $msg);
                              unless ($succeed) {
                                  trace ("%s - %s, received %s, expected %s, mock %s", $msg, join ("/", $method, @args), $received, $expected, $mock);
                                  BAIL_OUT;
                              }
                              if (scalar @tests) {
                                  if (0 == --$failure) {
                                      note "Failing $candidate";
                                      trace ("Failing $candidate") if DEBUG;
                                      $manager->stop ($candidate);
                                      $mock->stop ($candidate);
                                  }
                                  goto &$test;
                              } else {
                                  $cv->send;
                              }
                          });
    };
    $test->();
    $cv->recv;
}

sub sync {
    my ($selector, $protocol, $candidate, $client, $mock, $tests) = @_;
    trace ("running %s/%s synchronous", $selector, $protocol) if DEBUG;
    my @tests = @{thaw $tests};
    my $failure = int rand (scalar @tests - 20) + 10;
    note "Failing test $failure";
    while (1) {
        my ($method, @args) = @{shift @tests};
        my $msg = pop @args;
        trace ("%s is %s (%s)", $msg, $method, \@args) if DEBUG;
        my $expected = $mock->$method (@args);
        my $received = $client->$method (@args);
        my $succeeded = is_deeply ($received, $expected, $msg);
        unless ($succeeded) {
            trace ("%s - %s, received %s, expected %s, mock %s", $msg, join ("/", $method, @args), $received, $expected, $mock);
            BAIL_OUT;
        }
        if (@tests) {
            if (0 == --$failure) {
                note "Failing $candidate";
                trace ("Failing $candidate") if DEBUG;
                $mock->stop ($candidate);
                $manager->stop ($candidate);
            }
        } else {
            last;
        }
    }
}

sub find_memcached {
    #diag "Looking for environment";
    # If we're told where to look, use it if it looks executable
    return $ENV{MEMCACHED} if ($ENV{MEMCACHED} and -x $ENV{MEMCACHED});
    #diag "Looking using which";
    # Try using which
    chomp (my $memcached = qx{which memcached});
    # If we got output, use it if it looks executable
    return $memcached if ($memcached and -x $memcached);
    #diag "Trying using path";
    # If we're able to execute it without error
    return "memcached" unless system qq{memcached -h 2>/dev/null};
    #diag "Failing";
    # We failed, we're going to skip
    return;
}

=method trace

=cut

sub trace {
    my ($format, @args) = @_;
    LOG ("Test> " . $format, @args);
}

sub filter {
    my ($tests, $version) = @_;

    my @filters;

    if ($version lt "001002004") {
        push @filters, "cas";
    }
    if ($version le "001002002") {
        push @filters, "append";
        push @filters, "append_multi";
        push @filters, "prepend";
        push @filters, "prepend_multi";
    }
    if ($version lt "001001010") {
        push @filters, "flush_all";
    }

    my $restring = '^(?:' . join ('|', @filters) . ')$';
    my $re = qr/$restring/;
    [grep {
        $_->[0] =~ m/$re/ ? () : $_;
    } @{$tests}];
}

1;
