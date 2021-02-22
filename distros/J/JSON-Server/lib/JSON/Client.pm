package JSON::Client;
use warnings;
use strict;
use utf8;
use Carp;
use JSON::Parse '0.60_01', 'valid_json';
use JSON::Create '0.30_04';
use JSON::Server;
use IO::Socket;
our $VERSION = '0.01';

sub new
{
    my ($class, %options) = @_;
    my $port = $options{port};
    if (! $port) {
	carp "No port specified";
	return undef;
    }
    delete $options{port};
    my $verbose = $options{verbose};
    if ($verbose) {
	print __PACKAGE__ . "->new - messages on.\n";
    }
    delete $options{verbose};
    for my $k (keys %options) {
	carp "Unknown option '$k'";
	delete $options{$k};
    }
    my $client = bless {
	port => $port,
	verbose => $verbose,
	jc => JSON::Create->new (downgrade_utf8 => 1,),
	jp => JSON::Parse->new (),
    };
    $client->{jp}->upgrade_utf8 (1);
    return $client;
}

sub JSON::Client::send
{
    my ($jcl, $input) = @_;
    if (! $input) {
	carp "Nothing to send";
	return {error => 'empty input'};
    }
    my $json_msg = $jcl->{jc}->run ($input);
    my $sock = make_sock ($jcl->{port});
    if (! $sock) {
	return {error => 'make_sock failed'};
    }
    if ($jcl->{verbose}) {
	print __PACKAGE__ . "::send - sending $json_msg\n";
    }
    my ($got, $ok) = get ($sock, $json_msg);
    if (! $ok) {
	carp "Error reading from server: $@";
	return {error => "Error reading from server: $@"};
    }
    if ($jcl->{verbose}) {
	print __PACKAGE__ . "::send - got reply '$got'\n";
    }
    if (! valid_json ($got)) {
	if ($jcl->{verbose}) {
	    print __PACKAGE__ . "::send - not valid JSON\n";
	}
	return {error => 'invalid JSON'};
    }
    return $jcl->{jp}->parse ($got);
}

sub make_sock
{
    my ($port) = @_;
    my %so = JSON::Server::so ();
    %so = (
	%so,
	PeerPort => $port,
	PeerHost => 'localhost',
    );
    my $sock = IO::Socket->new (%so);
    if (! $sock) {
	warn "IO::Socket->new failed: $!";
    }
    return $sock;
}

sub get
{
    my ($sock, $json_msg) = @_;
    $sock->send ($json_msg . chr (0));
    my $got = '';
    my ($ok) = eval {
	my $data;
	my $max = 1000;
	while (! defined $data || length ($data) == $max) {
	    $data = '';
	    $sock->recv ($data, $max);
	    $got .= $data;
	    if ($got =~ s/\x00//) {
		last;
	    }
	}
	1;
    };
    return ($got, $ok);
}

1;
