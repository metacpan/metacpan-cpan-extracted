# Admin/text protocol thoroughly: status while running, workers
# listing, multi-line termination, and intermixing admin with
# binary commands on the same connection.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $g = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port, client_id => "xt-admin-$$");
my $func = "xt_admin_$$";
$wkr->register_function($func => sub { 'r' });
$wkr->work;

# 1) version
my ($v, $e);
$g->server_version(sub { ($v, $e) = @_; EV::break });
my $guard = EV::timer 3, 0, sub { fail "version timeout"; EV::break };
EV::run;
ok defined $v && length $v, "version: $v";

# 2) status — should list our function with at least one worker
my ($s);
$g->server_status(sub { $s = $_[0]; EV::break });
$guard = EV::timer 3, 0, sub { fail "status timeout"; EV::break };
EV::run;
my $found = grep { /^\Q$func\E\t/ } split /\n/, ($s // '');
ok $found, "status lists $func";

# 3) workers — should include our client_id
my ($wlist);
$g->server_workers(sub { $wlist = $_[0]; EV::break });
$guard = EV::timer 3, 0, sub { fail "workers timeout"; EV::break };
EV::run;
like $wlist, qr/xt-admin-$$/, 'workers lists our client_id';

# 4) intermix: admin then binary on same conn — head-of-queue tagging
{
    my @results;
    $g->server_version(sub { push @results, ['version', @_]; EV::break if @results == 2 });
    $g->echo("ping", sub { push @results, ['echo', @_]; EV::break if @results == 2 });
    $guard = EV::timer 3, 0, sub { fail "intermix timeout"; EV::break };
    EV::run;
    is scalar(@results), 2, 'intermix: both replies received';
    is $results[0][0], 'version', 'version arrived first';
    is $results[1][0], 'echo',    'echo arrived second';
}

done_testing;
