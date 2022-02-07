use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Differences;
use HealthCheck::Diagnostic::SFTP;

# Mock the SFTP module so that we can pretend to have good and bad hosts.
my $last_sftp;
my $mock = Test::MockModule->new( 'Net::SFTP' );
$mock->mock( new => sub {
    my ( $class, $host, %params ) = @_;

    # In-accessible hosts should not be reached.
    die "Net::SSH: Bad host name: $host"
        if $host eq 'inaccessible-host';

    $last_sftp = bless( \%params, 'Net::SFTP' );
    return $last_sftp;
} );

# Check that we can use HealthCheck as a class.
{
    my $result = HealthCheck::Diagnostic::SFTP->check(
        host => 'good-host',
    );
    is $result->{status}, 'OK',
        'Can use HealthCheck as a class.';
    is $result->{info}, 'Successful connection for good-host SFTP',
        'Info message is correct for instance check.';
}

# Check that we can use HealthCheck with initialized values too.
{
    my $diagnostic = HealthCheck::Diagnostic::SFTP->new(
        host => 'good-host',
    );
    my $result = $diagnostic->check;
    is $result->{status}, 'OK',
        'Can use HealthCheck with instance values too.';
    is $result->{info}, 'Successful connection for good-host SFTP',
        'Info message is correct for initialized diagnostic.';
}

# Check that `check` parameters override the initialized parameters.
{
    my $diagnostic = HealthCheck::Diagnostic::SFTP->new(
        host => 'good-host1',
    );
    my $result = $diagnostic->check( host => 'good-host2' );
    is $result->{status}, 'OK',
        'HealthCheck result status is still OK.';
    is $result->{info}, 'Successful connection for good-host2 SFTP',
        'Info message shows that the `check` host overrides all.';
}

# Create a method that returns the info and status after running the
# check. If it failed, then this just returns the error.
my $run_check_or_error = sub {
    my $result;
    local $@;
    # We passed in a diagnostic, just run the check.
    if ( ref $_[0] ) {
        $result = eval { $_[0]->check } if ref $_[0] ne 'HASH';
    }
    # We passed in some check parameters, send them in.
    else {
        $result = eval {
            HealthCheck::Diagnostic::SFTP->check( @_ );
        };
    }
    return [ $result->{status}, $result->{info} ] unless $@;
    return $@;
};

# Check that we require the host, but the other Net::SFTP parameters
# can be passed in as optional parameters.
{
    my %default = ( host => 'good-host' );
    like $run_check_or_error->(), qr/No host/,
        'Cannot run check without host.';
    eq_or_diff( $run_check_or_error->( %default ),
        [ 'OK', 'Successful connection for good-host SFTP' ],
        'Can run check with only host.' );

    eq_or_diff( $run_check_or_error->( %default, user => 'us' ),
        [ 'OK', 'Successful connection for us@good-host SFTP' ],
        'Can run check with only host and user.' );
    eq_or_diff( $run_check_or_error->( %default, password => 'my_pwd' ),
        [ 'OK', 'Successful connection for good-host SFTP' ],
        'Can run check with only host and password.' );
    eq_or_diff( $run_check_or_error->( %default, debug => 1 ),
        [ 'OK', 'Successful connection for good-host SFTP' ],
        'Can run check with only host and debug.' );
    eq_or_diff( $run_check_or_error->( %default, warn => sub { 1 } ),
        [ 'OK', 'Successful connection for good-host SFTP' ],
        'Can run check with only host and warn.' );
    eq_or_diff( $run_check_or_error->( %default, ssh_args => { a => 1 } ),
        [ 'OK', 'Successful connection for good-host SFTP' ],
        'Can run check with only host and ssh_args.' );
}

# Check that the description is correctly displayed with the supplied
# parameters.
{
    is $run_check_or_error->(
        host => 'good-host',
    )->[1], 'Successful connection for good-host SFTP',
        'Host is in description when specified.';
    is $run_check_or_error->(
        host => 'good-host',
        user => 'user',
    )->[1], 'Successful connection for user@good-host SFTP',
        'Host and user is in the description when specified.';
    is $run_check_or_error->(
        host => 'good-host',
        user => 'user',
        name => 'Type1',
    )->[1], 'Successful connection for Type1 (user@good-host) SFTP',
        'Host, user, and name are in the description when specified.';
    is $run_check_or_error->(
        host => 'good-host',
        name => 'Type2',
    )->[1], 'Successful connection for Type2 (good-host) SFTP',
        'Host and name are in the description when specified.';
}

# Test that connection errors are properly caught.
{
    my $result = $run_check_or_error->( host => 'inaccessible-host' );
    is $result->[0], 'CRITICAL',
        'Connection error brings up CRITICAL status.';
    like $result->[1], qr/Net::SSH: Bad host name: inaccessible-host/,
        'Connection error is displayed in info message.';
}

# Test that we properly support callbacks.
{
    my @data;
    eq_or_diff(
        $run_check_or_error->(
            host     => 'good-host',
            callback => sub { push @data, \@_ },
        ),
        [ 'OK', 'Successful connection and callback for good-host SFTP' ],
        'Generic result hashref for successful callback without return.',
    );
    is scalar( @data ), 1,
        'The callback is only called once.';
    is scalar( @{ $data[0] } ), 1,
        'Only one argument is passed to the callback.';
    is ref $data[0][0], 'Net::SFTP',
        'The SFTP instance is passed to the callback.';

    eq_or_diff(
        $run_check_or_error->(
            host     => 'good-host',
            callback => sub {
                return { info => 'custom_info', status => 'WARNING' };
            },
        ),
        [ 'WARNING', 'custom_info' ],
        'Custom result hashref for successful callback with return hash.',
    );

    my $result = $run_check_or_error->(
        host     => 'good-host',
        callback => sub { die 'Nice try!' },
    );
    is $result->[0], 'CRITICAL',
        'CRITICAL result status for an error produced in callback.';
    like $result->[1],
        qr/Error in running callback for good-host SFTP: Nice try!/,
        'Return error in info message for an error produced in callback.';
}

# Test the timeout attribute gets passed to Net::SFTP properly.
{
    my $diagnostic = HealthCheck::Diagnostic::SFTP->new(
        host => 'host-with-default-timeout-and-no-ssh-args',
    );
    $diagnostic->check;
    eq_or_diff $last_sftp->{ssh_args}, { options => [ 'ConnectTimeout 3' ] },
        'Set default ConnectTimeout value with no other options.';

    $diagnostic = HealthCheck::Diagnostic::SFTP->new(
        host     => 'host-with-default-timeout-and-ssh-args',
        ssh_args => {
            some_net_ssh_perl_option => 'foo',
            options                  => ['UserKnownHostsFile /tmp'],
        },
    );
    $diagnostic->check;
    eq_or_diff $last_sftp->{ssh_args}, {
        some_net_ssh_perl_option => 'foo',
        options                  => [
            'UserKnownHostsFile /tmp',
            'ConnectTimeout 3',
        ],
    }, 'Set custom ConnectTimeout value with existing options.';

    $diagnostic = HealthCheck::Diagnostic::SFTP->new(
        host     => 'host-with-existing-timeout',
        timeout  => 55,
        ssh_args => {
            some_net_ssh_perl_option => 'foo',
            options                  => [
                'UserKnownHostsFile /tmp',
                'ConnectTimeout 42',
            ]
        },
    );
    $diagnostic->check;
    eq_or_diff $last_sftp->{ssh_args}, {
        some_net_ssh_perl_option => 'foo',
        options                  => [
            'UserKnownHostsFile /tmp',
            'ConnectTimeout 42',
        ],
    }, 'Ignored custom ConnectTimeout value with existing value set.';

    $diagnostic = HealthCheck::Diagnostic::SFTP->new(
        host    => 'host-with-custom-timeout-and-no-ssh-args',
        timeout => 42,
    );
    $diagnostic->check;
    eq_or_diff $last_sftp->{ssh_args}, { options => [ 'ConnectTimeout 42' ] },
        'Set custom ConnectTimeout value with no other options.';
}

done_testing;
