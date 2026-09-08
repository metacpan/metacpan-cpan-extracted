#!/usr/bin/env perl
# ex:ts=8 sw=4:

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;

# Skip if Net::SSH2 is not available
BEGIN {
    eval { require Net::SSH2 };
    if ($@) {
	plan skip_all => 'Net::SSH2 not available';
    }
}

use_ok('Fugu::SSH');

# A stand-in reader for _read_all. It gives at most chunk bytes per
# read, and it fails when fail is set. The read method writes into the
# variable of the caller, so it reads @_ and takes no signature: a
# signature copies its arguments.
package Test::Reader {

    sub new
    {
	my ($class, %args) = @_;
	return bless {
	    content => $args{content} // '',
	    chunk   => $args{chunk},
	    fail    => $args{fail},
	    pos     => 0,
	}, $class;
    }

    sub read
    {
	my $self = shift;
	my $length = $_[1];

	return undef if $self->{fail};

	my $want = $self->{chunk} // $length;
	$want = $length if $length < $want;

	my $data = substr($self->{content}, $self->{pos}, $want);
	$self->{pos} += length $data;
	$_[0] = $data;

	return length $data;
    }
}

# Test constants
is(Fugu::SSH::EXIT_SUCCESS(), 0, 'EXIT_SUCCESS is 0');
is(Fugu::SSH::EXIT_ERROR(), 1, 'EXIT_ERROR is 1');
is(Fugu::SSH::DEFAULT_TIMEOUT(), 10, 'DEFAULT_TIMEOUT is 10');
is(Fugu::SSH::BUFFER_SIZE(), 32768, 'BUFFER_SIZE is 32768');
is(Fugu::SSH::MAX_READ_SIZE(), 64 * 1024 * 1024, 'MAX_READ_SIZE is 64 MiB');

# Test object creation
{
    my $ssh = Fugu::SSH->new(host => 'localhost', port => 22);
    ok(defined $ssh, 'SSH object created');
    is($ssh->{host}, 'localhost', 'host stored');
    is($ssh->{port}, 22, 'port stored');
}

# Test object creation with default port
{
    my $ssh = Fugu::SSH->new(host => 'example.com');
    is($ssh->{port}, 22, 'default port is 22');
}

# Test wait_available to non-existent host returns false
{
    my $ssh = Fugu::SSH->new(host => 'localhost', port => 59999);
    my $result = $ssh->wait_available(1);
    ok(!$result, 'wait_available to closed port returns false');
}

# Test is_available
{
    my $ssh = Fugu::SSH->new(host => 'localhost', port => 59999);
    ok(!$ssh->is_available, 'is_available false for closed port');
}

# run_command always returns a result hash, the documented contract:
# a connect that fails reports exit code 1 and a message in stderr.
# Callers such as FuguVM read $result->{exit_code} without a guard.
{
    my $ssh = Fugu::SSH->new(host => 'localhost', port => 59999);
    my $result = $ssh->run_command('true');
    is($result->{exit_code}, 1,
	'run_command reports exit code 1 when the connect fails');
    like($result->{stderr}, qr/Failed to connect/,
	'run_command reports the failure in stderr');
}

# _read_all reads $size bytes through the read method of its file
# argument, so a stand-in class drives every path without a server.
{
    my $ssh = Fugu::SSH->new;

    my $reader = Test::Reader->new(content => 'abcdefgh', chunk => 3);
    is($ssh->_read_all($reader, 8), 'abcdefgh',
	'_read_all returns the whole content when it arrives in pieces');

    $reader = Test::Reader->new(content => 'abcdefgh');
    is($ssh->_read_all($reader, 0), '',
	'_read_all returns the empty string for a size of 0');

    $reader = Test::Reader->new(content => 'abc');
    ok(!defined $ssh->_read_all($reader, 8),
	'_read_all returns undef for a short read');

    $reader = Test::Reader->new(content => 'abcdefgh', fail => 1);
    ok(!defined $ssh->_read_all($reader, 8),
	'_read_all returns undef when a read fails');

    $reader = Test::Reader->new(content => 'abcdefgh');
    is($ssh->_read_all($reader, 5), 'abcde',
	'_read_all stops at the size when the reader offers more bytes');
}

# A stand-in writer for _write_all. It accepts at most chunk bytes
# per write, like libssh2_sftp_write(3) with a large buffer, and it
# fails when fail is set.
package Test::Writer {

    sub new
    {
	my ($class, %args) = @_;
	return bless {
	    chunk   => $args{chunk},
	    fail    => $args{fail},
	    stall   => $args{stall},
	    content => '',
	}, $class;
    }

    sub write
    {
	my ($self, $data) = @_;

	return undef if $self->{fail};
	return 0 if $self->{stall};

	my $want = $self->{chunk} // length $data;
	$want = length $data if length($data) < $want;

	$self->{content} .= substr $data, 0, $want;

	return $want;
    }
}

# _write_all sends every byte through the write method of its file
# argument, and one write can accept less than the full buffer.
{
    my $ssh = Fugu::SSH->new;

    my $writer = Test::Writer->new(chunk => 3);
    is($ssh->_write_all($writer, 'abcdefgh'), 1,
	'_write_all reports success when the bytes go out in pieces');
    is($writer->{content}, 'abcdefgh', 'and every byte arrives in order');

    $writer = Test::Writer->new;
    is($ssh->_write_all($writer, ''), 1,
	'_write_all reports success for an empty content');

    $writer = Test::Writer->new(fail => 1);
    ok(!defined $ssh->_write_all($writer, 'abcdefgh'),
	'_write_all returns undef when a write fails');

    $writer = Test::Writer->new(stall => 1);
    ok(!defined $ssh->_write_all($writer, 'abcdefgh'),
	'_write_all returns undef when a write makes no progress');
}

# read_file returns undef for every failure, and it does not die. A
# closed port proves the connect failure without a server. A success
# needs a live host, so FuguVM proves that path against a guest.
{
    my $ssh = Fugu::SSH->new(host => 'localhost', port => 59999);
    my $result = eval { $ssh->read_file('/etc/hostname') };
    is($@, '', 'read_file does not die for a closed port');
    ok(!defined $result, 'read_file returns undef for a closed port');
}

# The host-key policy of new: the strict argument and the known_hosts
# argument.
{
    my $ssh = Fugu::SSH->new(host => 'example.com');
    is($ssh->{strict}, 0, 'strict defaults to 0');
    ok(!defined $ssh->{known_hosts}, 'known_hosts defaults to absent');

    $ssh = Fugu::SSH->new(
	host        => 'example.com',
	strict      => 1,
	known_hosts => '/tmp/hosts',
    );
    is($ssh->{strict}, 1, 'new stores strict');
    is($ssh->{known_hosts}, '/tmp/hosts', 'new stores known_hosts');
}

# _ssh_argv builds the ssh(1) argument list of interactive, and it
# carries the host-key policy of the object.
{
    my $ssh = Fugu::SSH->new(host => 'guest', port => 2222, user => 'op');
    my @argv = $ssh->_ssh_argv;

    cmp_ok(scalar @argv, '>', 1,
	'_ssh_argv holds more than one element, so perl runs no shell');
    is($argv[0], 'ssh', '_ssh_argv starts with ssh');

    my $joined = join ' ', @argv;
    like($joined, qr/StrictHostKeyChecking=no/,
	'the default mode does not check the key');
    like($joined, qr{UserKnownHostsFile=/dev/null},
	'the default mode records no key');
    like($joined, qr/LogLevel=ERROR/,
	'the default mode hides the new-key report');
    like($joined, qr/-p 2222/, 'the list holds the port');
    is($argv[-1], 'op@guest', 'the list ends with user@host');
}

{
    my $ssh = Fugu::SSH->new(
	host   => 'guest',
	port   => 2222,
	user   => 'op',
	strict => 1,
    );
    my $joined = join ' ', $ssh->_ssh_argv;

    like($joined, qr/StrictHostKeyChecking=yes/,
	'the strict mode checks the key');
    unlike($joined, qr{UserKnownHostsFile},
	'the strict mode without a path names no file');
    unlike($joined, qr/LogLevel/,
	'the strict mode shows the host-key diagnosis');
    like($joined, qr/-p 2222/, 'the strict list holds the port');
    like($joined, qr/op\@guest$/, 'and ends with user@host');
}

{
    my $ssh = Fugu::SSH->new(
	host        => 'guest',
	strict      => 1,
	known_hosts => '/etc/fugu/hosts',
    );
    my $joined = join ' ', $ssh->_ssh_argv;

    like($joined, qr{UserKnownHostsFile=/etc/fugu/hosts},
	'the strict mode names the known_hosts file');
    unlike($joined, qr{GlobalKnownHostsFile},
	'the list never sets GlobalKnownHostsFile');
}

# A stand-in Net::SSH2 connection. _connect creates the object through
# Net::SSH2->new, so the test rebinds that constructor and records
# every call in order. The stand-in proves the policy without a
# server: the order of the steps, the check arguments, and both
# outcomes of the check.
package Test::SSH2 {

    sub new
    {
	my ($class, %args) = @_;
	return bless { %args, calls => [] }, $class;
    }

    sub timeout
    {
	my $self = shift;
	push @{ $self->{calls} }, 'timeout';
	return 1;
    }

    sub connect
    {
	my $self = shift;
	push @{ $self->{calls} }, 'connect';
	return 1;
    }

    sub check_hostkey
    {
	my ($self, @args) = @_;
	push @{ $self->{calls} }, 'check_hostkey';
	$self->{check_args} = [@args];
	return $self->{check_ok};
    }

    sub auth_password
    {
	my $self = shift;
	push @{ $self->{calls} }, 'auth_password';
	return 1;
    }

    sub disconnect
    {
	my $self = shift;
	push @{ $self->{calls} }, 'disconnect';
	return 1;
    }

    sub error
    {
	my $self = shift;
	return (-1, 'KNOWN_HOSTS',
	    $self->{error_string} // 'the file holds no key for the host');
    }
}

SKIP: {
    skip 'Net::SSH2 is older than 0.60', 11
	unless Net::SSH2->can('check_hostkey');

    # The agent branch reads SSH_AUTH_SOCK, so the stand-in runs
    # without one and authenticates with the password.
    local $ENV{SSH_AUTH_SOCK};
    delete $ENV{SSH_AUTH_SOCK};

    my $standin;
    no warnings 'redefine';
    local *Net::SSH2::new = sub { return $standin };

    # The strict mode verifies between the connect and the
    # authentication.
    {
	$standin = Test::SSH2->new(check_ok => 1);
	my $ssh = Fugu::SSH->new(
	    host        => 'guest',
	    port        => 2222,
	    password    => 'secret',
	    strict      => 1,
	    known_hosts => '/tmp/hosts',
	);

	is($ssh->_connect, $standin, 'a verified connection authenticates');
	is_deeply(
	    $standin->{calls},
	    [ 'timeout', 'connect', 'check_hostkey', 'auth_password' ],
	    'the order is connect, verify, authenticate');
	is($standin->{check_args}[0],
	    Net::SSH2::LIBSSH2_HOSTKEY_POLICY_STRICT(),
	    'the check uses the strict policy');
	is($standin->{check_args}[1], '/tmp/hosts',
	    'and the named known_hosts file');
    }

    # Without a path the check omits the second argument, so the
    # back end reads its own default file.
    {
	$standin = Test::SSH2->new(check_ok => 1);
	my $ssh = Fugu::SSH->new(
	    host     => 'guest',
	    password => 'secret',
	    strict   => 1,
	);
	$ssh->_connect;
	is(scalar @{ $standin->{check_args} }, 1,
	    'no path reaches the check when the caller gave none');
    }

    # A key that does not verify dies before any authentication.
    {
	$standin = Test::SSH2->new(check_ok => 0);
	my $ssh = Fugu::SSH->new(
	    host        => 'guest',
	    port        => 2222,
	    password    => 'secret',
	    strict      => 1,
	    known_hosts => '/tmp/hosts',
	);

	ok(!eval { $ssh->_connect; 1 }, 'a wrong key dies');
	like($@,
	    qr{^Cannot verify the host key of guest port 2222 against /tmp/hosts: .+\n\z},
	    'the one-line message names the host, the port, the file'
		. ' and the reason');
	is_deeply(
	    $standin->{calls},
	    [ 'timeout', 'connect', 'check_hostkey', 'disconnect' ],
	    'no credential went out, and the connection closed');
    }

    # The permissive mode never calls the check, so every caller of
    # today keeps its behavior exactly.
    {
	$standin = Test::SSH2->new(check_ok => 0);
	my $ssh = Fugu::SSH->new(
	    host     => 'guest',
	    password => 'secret',
	);

	is($ssh->_connect, $standin, 'the permissive mode connects');
	is_deeply(
	    $standin->{calls},
	    [ 'timeout', 'connect', 'auth_password' ],
	    'and it never calls check_hostkey');
	ok(!defined $standin->{check_args}, 'no check arguments exist');
    }
}

# The strict mode needs Net::SSH2 0.60, and the static test runs
# before any connect, so an old library dies without a network step.
{
    no warnings 'redefine';
    local *Net::SSH2::can = sub { return 0 };

    my $ssh = Fugu::SSH->new(host => 'guest', strict => 1);
    ok(!eval { $ssh->_connect; 1 },
	'an old Net::SSH2 dies in the strict mode');
    like($@, qr/needs Net::SSH2 0\.60 or later/,
	'and the message names the version');
}

# interactive maps a raw wait status to a 0-255 exit code through
# Fugu::Process->exit_code. This lets `fuguvm ssh`, when it runs a
# script over stdin, propagate a failing remote command (for example a
# failing `prove` run). Without it, a raw status like 256 truncates
# down to exit(256) -> 0. The mapping itself is proven in
# t/fugu/process.t; here only the one copy has to be gone.
{
    ok(!Fugu::SSH->can('_exit_code'),
        'the private copy of the mapping is gone');
    ok(Fugu::Process->can('exit_code'),
        'Fugu::Process owns the mapping');
}

done_testing();
