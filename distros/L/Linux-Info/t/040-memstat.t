use strict;
use warnings;
use Test::More;
use Linux::Info;
use Scalar::Util qw(openhandle);

unless ( -r '/proc/meminfo' ) {
    plan skip_all =>
      "it seems that your system doesn't provide memory statistics";
    exit;
}

my @memstats = qw(
  memused
  memfree
  memusedper
  memtotal
  buffers
  cached
  realfree
  realfreeper
  swapused
  swapfree
  swapusedper
  swaptotal
  swapcached
  active
  inactive
);

my @memstats26  = qw(committed_as);
my @memstats269 = qw(commitlimit);

open( my $fh, '<', '/proc/sys/kernel/osrelease' ) or report_missing($!);

if ( openhandle($fh) ) {
    my @rls = split /\./, <$fh>;
    close $fh;
    my $sys = Linux::Info->new();
    $sys->set( memstats => 1 );
    my $stats = $sys->get;

    if ( $rls[0] < 6 ) {
        plan tests => 15;
    }
    else {
        push @memstats, $_ for @memstats26;
        if ( $rls[1] < 9 ) {
            plan tests => 16;
        }
        else {
            plan tests => 17;
            push @memstats, $_ for @memstats269;
        }
    }

    foreach my $stat (@memstats) {
        ok( defined $stats->memstats->{$stat}, "checking memstats $stat" )
          or diag( "This system doesn't include $stat: "
              . explain( $stats->memstats ) );
    }
}
else {
    plan skip_all => 'This system does not provide memstat features';
    exit;
}

sub report_missing {
    my $error = shift;
    diag(
"This system does not have a readable /proc/sys/kernel/osrelease: $error"
    );
}
