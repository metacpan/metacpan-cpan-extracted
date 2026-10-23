use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $available = TestMariaDB::server_available();
plan skip_all => 'no MariaDB server' unless $available;

sub run_guarded {
    my $guard = EV::timer(5, 0, sub { die "idle-close test timed out\n" });
    EV::run;
}
sub connect_idle {
    my $m = EV::MariaDB->new(
        TestMariaDB::connect_args(), on_connect => sub { EV::break },
        on_error => sub { die $_[0] },
    );
    run_guarded();
    return $m;
}
my $observer = connect_idle();
sub aborted_clients {
    my $count;
    $observer->query("show global status like 'Aborted_clients'", sub {
        die $_[1] if $_[1];
        $count = $_[0][0][1];
        EV::break;
    });
    run_guarded();
    return $count;
}
for my $method (qw(finish reset DESTROY)) {
    my $m = connect_idle();
    my $before = aborted_clients();
    if ($method eq 'DESTROY') { undef $m }
    else {
        $m->$method();
        run_guarded() if $method eq 'reset';
        $m->finish;
    }
    my $pause = EV::timer(.05, 0, sub { EV::break });
    EV::run;
    is aborted_clients(), $before, "$method sends COM_QUIT for an idle connection";
}
$observer->finish;
done_testing;
