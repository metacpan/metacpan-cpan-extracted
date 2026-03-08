package TestHelper;
use strict;
use warnings;
use EV;
use EV::Pg;
use Test::More;
use Exporter 'import';

our @EXPORT = qw(with_pg require_pg $conninfo);
our $conninfo = $ENV{TEST_PG_CONNINFO};

sub require_pg {
    plan skip_all => "set TEST_PG_CONNINFO to run" unless $conninfo;
    my $ok = 0;
    my $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub { $ok = 1; EV::break },
        on_error   => sub { EV::break },
    );
    my $t = EV::timer(3, 0, sub { EV::break });
    EV::run;
    $pg->finish if $pg->is_connected;
    plan skip_all => "PostgreSQL not reachable at '$conninfo'"
        unless $ok;
}

sub with_pg {
    my (%opts) = @_;
    my $cb      = delete $opts{cb};
    my $timeout = delete $opts{timeout} || 5;
    my $pg;
    $pg = EV::Pg->new(
        conninfo   => $conninfo,
        on_connect => sub { $cb->($pg) },
        on_error   => sub { diag("Error: $_[0]"); EV::break },
        %opts,
    );
    my $t = EV::timer($timeout, 0, sub { diag("TIMEOUT after ${timeout}s"); EV::break });
    EV::run;
    $pg->finish if $pg && $pg->is_connected;
}

1;
