use strict;
use warnings;
use Config;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan skip_all => 'needs ithreads' unless $Config{useithreads} && eval { require threads; 1 };
plan tests => 2;

# A spawned thread must not DESTROY-clone the object (which would PQfinish
# the parent's connection).  CLONE_SKIP leaves an unblessed copy behind.
# Runs alone: EV watchers alive at spawn time are cloned and double-freed
# inside EV itself.
my ($child_ref, $qv);
my $pg;
$pg = EV::Pg->new(
    conninfo => $conninfo,
    on_connect => sub { EV::break },
    on_error => sub { EV::break },
);
my $t = EV::timer(10, 0, sub { EV::break });
EV::run;
undef $t;
$child_ref = threads->create(sub { return ref $pg })->join;
$pg->query("select 'QT'::text", sub {
    my ($r, $e) = @_;
    $qv = $e ? "ERR:$e" : $r->[0][0];
    EV::break;
});
$t = EV::timer(10, 0, sub { EV::break });
EV::run;
$pg->finish if $pg->is_connected;
isnt($child_ref, 'EV::Pg', 'threads: child sees unblessed copy');
is($qv, 'QT', 'threads: parent connection survives thread exit');
