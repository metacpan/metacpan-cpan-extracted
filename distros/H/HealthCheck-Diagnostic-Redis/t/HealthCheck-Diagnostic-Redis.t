use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Differences;

BEGIN { use_ok('HealthCheck::Diagnostic::Redis') };

diag(qq(HealthCheck::Diagnostic::Redis Perl $], $^X));

my %fake_redis_store = (
    recent_key    => 1234,
    read_this_key => 'once upon a time',
);

# Mock the Redis module so that we can pretend to have good and bad hosts.
my $mock = Test::MockModule->new( 'Redis::Fast' );
$mock->mock( new => sub {
    my ( $class, %params ) = @_;

    my $host = $params{server};
    $host =~ s/:6379$//;

    # In-accessible hosts should not be reached.
    die "Redis::Fast: Bad host name: $host"
        if $host eq 'inaccessible-host';

    return bless( \%params, 'Redis::Fast' );
} );
$mock->mock( get => sub {
    my ($self, $key) = @_;
    return $fake_redis_store{$key};
} );
$mock->mock( set => sub {
    my ($self, $key, $val) = @_;
    $fake_redis_store{ $key } = $val;
} );
$mock->mock( del => sub {
    my ($self, $key) = @_;
    delete $fake_redis_store{ $key };
} );
$mock->mock( ping => sub {
    my $self = shift;
    return $self->{server} =~ /badping/ ? 0 : 1;
} );
$mock->mock( randomkey => sub {
    my $self = shift;
    return 'recent_key';
} );
# We have to mock out destroy, or things break terribly because of Redis::Fast
# AUTOLOAD...
$mock->mock( DESTROY => sub {} );

# Check that we can use HealthCheck as a class.
{
    my $result = HealthCheck::Diagnostic::Redis->check(
        host => 'good-host',
    );
    is $result->{status}, 'OK',
        'Can use HealthCheck as a class.';
    is $result->{info}, 'Successful connection for good-host Redis',
        'Info message is correct for instance check.';
}

# Check that we can use HealthCheck with initialized values too.
{
    my $diagnostic = HealthCheck::Diagnostic::Redis->new(
        host => 'good-host',
    );
    my $result = $diagnostic->check;
    is $result->{status}, 'OK',
        'Can use HealthCheck with instance values too.';
    is $result->{info}, 'Successful connection for good-host Redis',
        'Info message is correct for initialized diagnostic.';
}

# Check that `check` parameters override the initialized parameters.
{
    my $diagnostic = HealthCheck::Diagnostic::Redis->new(
        host => 'good-host1',
    );
    my $result = $diagnostic->check( host => 'good-host2' );
    is $result->{status}, 'OK',
        'HealthCheck result status is still OK.';
    is $result->{info}, 'Successful connection for good-host2 Redis',
        'Info message shows that the `check` host overrides all.';
}

# Test that connection errors are properly caught.
{
    my $result = HealthCheck::Diagnostic::Redis->check(
        host => 'inaccessible-host',
    );
    is $result->{status}, 'CRITICAL',
        'Connection error brings up CRITICAL status.';
    like $result->{info}, qr/Redis::Fast: Bad host name: inaccessible-host/,
        'Connection error is displayed in info message.';
}

# Test that host is required.
{
    local $@;
    eval { HealthCheck::Diagnostic::Redis->check() };
    ok $@, "Check with no host dies.";
    like $@, qr/^No host/, "Error is No Host.";
}

# Test that we can specify the key to read.
{
    my $result = HealthCheck::Diagnostic::Redis->check(
        host      => 'good-host1',
        key_name  => 'reed_this_key',
        read_only => 1,
    );
    is $result->{status}, 'CRITICAL',
        'Look for static key that does not exist.';
    like $result->{info}, qr/Failed reading value of key reed_this_key/,
        'Mention key in failure';

    $result = HealthCheck::Diagnostic::Redis->check(
        host      => 'good-host1',
        key_name  => 'read_this_key',
        read_only => 1,
    );
    is $result->{status}, 'OK', 'Look for static key that exists.';

    $result = HealthCheck::Diagnostic::Redis->check(
        host      => 'good-host1',
        key_name  => 'read_this_key',
    );
    is $result->{status}, 'CRITICAL',
        'Fail when writing to key that already exists.';
    like $result->{info}, qr/Cannot overwrite key read_this_key/,
        'Mention key in failure.';
}


# Make sure that the redis keys were deleted.
eq_or_diff( \%fake_redis_store, {
    recent_key    => 1234,
    read_this_key => 'once upon a time',
}, 'Fake redis store is emptied back to default.' );

done_testing;
