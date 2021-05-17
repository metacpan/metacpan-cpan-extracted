package JSON::Server;
use warnings;
use strict;
use Carp;
use utf8;
our $VERSION = '0.02';

use IO::Socket;
use IO::Select;
use JSON::Create '0.34', ':all';
use JSON::Parse '0.61', ':all';

$SIG{PIPE} = sub {
    croak "Aborting on SIGPIPE";
};

sub set_opt
{
    my ($gs, $o, $nm) = @_;
    # Use exists here so that, e.g. verbose => $verbose, $verbose =
    # undef works OK.
    if (exists $o->{$nm}) {
	$gs->{$nm} = $o->{$nm};
	delete $o->{$nm};
    }
}

sub new
{
    my ($class, %o) = @_;
    my $gs = {};
    set_opt ($gs, \%o, 'verbose');
    set_opt ($gs, \%o, 'port');
    set_opt ($gs, \%o, 'handler');
    set_opt ($gs, \%o, 'data');
    for my $k (keys %o) {
	carp "Unknown option '$k'";
	delete $o{$k};
    }
    if (! $gs->{port}) {
	carp "No port specified";
    }
    $gs->{jc} = JSON::Create->new (
	indent => 1,
	sort => 1,
	downgrade_utf8 => 1,
    );
    $gs->{jc}->bool ('boolean');
    $gs->{jp} = JSON::Parse->new ();
    $gs->{jp}->upgrade_utf8 (1);
    return bless $gs;
}

sub so
{
    my %so = (
	Domain => IO::Socket::AF_INET,
	Proto => 'tcp',
	Type => IO::Socket::SOCK_STREAM,
    );
    # https://stackoverflow.com/a/2229946
    if (defined eval { SO_REUSEPORT }) {
	$so{ReusePort} = 1;
    }
    return %so;
}

sub serve
{
    my ($gs) = @_;
    my %so = so ();
    %so = (
	%so,
	Listen => 5,
	LocalPort => $gs->{port},
    );
    if ($gs->{verbose}) {
	vmsg ("Serving on $gs->{port}");
    }
    my $server = IO::Socket->new (%so);
    if (! $server) {
	carp "Error from IO::Socket->new: $@";
	return;
    }
    my $s = IO::Select->new ();
    $s->add ($server);
    while (my @ready = $s->can_read ()) {
	if ($gs->{verbose}) {
	    vmsg ("Reading from @ready");
	}
	for my $fh (@ready) {
	    if ($fh == $server) {
		my $new = $server->accept ();
		$s->add ($new);
		next;
	    }
	    my $got = '';
	    my ($ok) = eval {
		if ($gs->{verbose}) {
		    vmsg ("Got a message");
		}
		my $data;
		my $max = 1000;
		while (! defined $data || length ($data) == $max) {
		    $data = '';
		    my $recv_ret = $fh->recv ($data, $max);
		    if (! defined $recv_ret) {
			if ($gs->{verbose}) {
			    vmsg ("recv had an error $@");
			}
			last;
		    }
		    $got .= $data;
		    if ($got =~ s/\x{00}$//) {
			last;
		    }
		}
		1;
	    };
	    if (! $ok) {
		carp "accept failed: $@";
		next;
	    }
	    if ($gs->{verbose}) {
		vmsg ("Received " . length ($got) . " bytes of data");
	    }
	    if (length ($got) == 0) {
		if ($gs->{verbose}) {
		    vmsg ("Connection was closed");
		}
		return;
	    }
	    if (! valid_json ($got)) {
		if ($gs->{verbose}) {
		    vmsg ("Not valid json");
		}
		$gs->reply ($fh, {error => 'invalid JSON'});
		next;
	    }
	    if ($gs->{verbose}) {
		vmsg ("Validated as JSON");
	    }
	    my $input = $gs->{jp}->parse ($got);
	    if (ref $input eq 'HASH') {
		my $control = $input->{'JSON::Server::control'};
		if (defined $control) {
		    if ($control eq 'stop') {
			if ($gs->{verbose}) {
			    vmsg ("Received control message to stop");
			}
			$gs->reply ($fh, {'JSON::Server::response' => 'stopping'});
			if ($gs->{verbose}) {
			    vmsg ("Responded to control message to stop");
			}
			$gs->close ($fh);
			return;
		    }
		    if ($control eq 'close') {
			$gs->reply ($fh, {'JSON::Server::response' => 'closing'});
			if ($gs->{verbose}) {
			    vmsg ("Responded to control message to close connection");
			}
			$gs->close ($fh);
			next;
		    }
		    warn "Unknown control command '$control'";
		}
	    }
	    $gs->respond ($fh, $input);
	}
    }
}

sub respond
{
    my ($gs, $fh, $input) = @_;
    my $reply;
    if (! $gs->{handler}) {
	carp "Handler is not set, will echo input back";
	$gs->{handler} = \&echo;
    }
    my $ok = eval {
	$reply = &{$gs->{handler}} ($gs->{data}, $input);
	1;
    };
    if (! $ok) {
	carp "Handler crashed: $@";
	$gs->reply ($fh, {error => "Handler crashed: $@"});
	return;
    }
    if ($gs->{verbose}) {
	vmsg ("Replying");
    }
    $gs->reply ($fh, $reply);
}

sub reply
{
    my ($gs, $fh, $msg) = @_;
    my $json_msg = $gs->{jc}->create ($msg);
    if ($gs->{verbose}) {
	vmsg ("Sending $json_msg");
    }
    $json_msg .= chr (0);
    my $sent = $fh->send ($json_msg);
    if (! defined $sent) {
	warn "Error sending: $@\n";
    }
    if ($gs->{verbose}) {
	vmsg ("Sent");
    }
}

sub JSON::Server::close
{
    my ($gs, $fh) = @_;
    if ($gs->{verbose}) {
	vmsg ("Closing connection");
    }
    $fh->close ();
}

# This is the default callback of the server.

sub echo
{
    my ($data, $input) = @_;
    return $input;
}

sub vmsg
{
    my ($msg) = @_;
    print __PACKAGE__ . ": $msg.\n";
}


1;
