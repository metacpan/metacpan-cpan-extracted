use strict;
use warnings;
use Test::More;
use Linux::Info::MemStats;
use Scalar::Util qw(openhandle looks_like_number);

unless ( -r '/proc/meminfo' ) {
    plan skip_all =>
      "it seems that your system doesn't provide memory statistics";
    exit;
}

my $stats = Linux::Info::MemStats->new();
isa_ok( $stats, 'Linux::Info::MemStats' );
can_ok( $stats, qw(new get get_more) );

open( my $fh, '<', '/proc/sys/kernel/osrelease' )
  or
  diag("This system does not have a readable /proc/sys/kernel/osrelease: $!");

if ( openhandle($fh) ) {
    note( 'Testing get() on kernel ' . kernel_version($fh) );
    my @memstats = (
        'memused',    'memfree',  'memusedper',  'memtotal',
        'buffers',    'cached',   'realfree',    'realfreeper',
        'swapused',   'swapfree', 'swapusedper', 'swaptotal',
        'swapcached', 'active',   'inactive',    'committed_as',
        'commitlimit'
    );
    my $mem_info_ref = $stats->get();
    isa_ok( $mem_info_ref, 'HASH', 'what reference get() returned' );
    my @data = explain($mem_info_ref);
    note('Testing mostly basic expected information availability');

    foreach my $stat (@memstats) {

      SKIP: {

            skip "this system lacks $stat", 2
              unless ( exists( $mem_info_ref->{$stat} ) );

            ok( exists( $mem_info_ref->{$stat} ), "$stat is available" );

            ok( looks_like_number( $mem_info_ref->{$stat} ),
                "$stat has numeric value" )
              or diag("$stat is missing: @data");
        }
    }
}
else {
    plan skip_all => 'This system does not provide memstat features';
}

done_testing;

sub kernel_version {
    my $fh = shift;
    my $rls;

    {
        local $/ = undef;
        $rls = <$fh>;
    }

    close $fh;
    return $rls;
}
