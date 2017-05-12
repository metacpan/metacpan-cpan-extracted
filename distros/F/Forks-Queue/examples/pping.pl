# pping.pl - ping an entire subnet of 256 IP addresses in parallel
#   usage:  perl -Ilib examples/pping.pl A.B.C
#           perl -Ilib examples/pping.pl

use strict;
use warnings;
use Forks::Queue;
$| = 1;

my $NetPing_avail = eval "use Net::Ping;1";
print "Net::Ping avail: $NetPing_avail $@\n";
my %opts = ( impl => 'Shmem', style => 'lifo' );

my $subnet = $ARGV[0] // "127.0.0";
my $q1 = Forks::Queue->new( %opts );
my $q2 = Forks::Queue->new( %opts );

for (0 .. 255) {
    $q1->put("$subnet.$_");
}
$q1->end;
for (0 .. 9) {
    if (fork() == 0) {
        work();
        exit;
    }
}
my %working;

local $SIG{CHLD} = 'IGNORE';
my ($num_alive, $num_pinged) = 0;
while (my $result = $q2->get) {
    if ($result->{start}) {
        $working{$result->{start}}++;
        next;
    }
    if ($result->{finished}) {
        delete $working{$result->{finished}};
        if (!%working) {
            $q2->end;
        }
        next;
    }
    my $addr = $result->{addr};
    my $status = $result->{status};

    print "$addr => $status\n";
    $num_alive += $status;
    $num_pinged++;
}
print "Got response from $num_alive out of $num_pinged queried addresses\n";
exit;

sub work {
    my $p;
    $q2->put( { start => $$ } );
    if ($NetPing_avail) {
        $p = Net::Ping->new;
    }
    while (my @nodes = $q1->get(4)) {
        foreach my $ip (@nodes) {
            my $z;
            if ($p) {
                $z = $p->ping($ip,2);
            } else {
                $z = 0 + !system("ping -c 2 -t 2 $ip");
            }
            $q2->put( { addr => $ip, status => $z } );
        }
    }
    $p && $p->close;
    $q2->put( { finished => $$ } );
    exit;
}
