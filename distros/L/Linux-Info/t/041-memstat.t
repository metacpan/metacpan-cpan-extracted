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

open( my $fh, '<', '/proc/sys/kernel/osrelease' )
  or
  diag("This system does not have a readable /proc/sys/kernel/osrelease: $!");

if ( openhandle($fh) ) {
    note('Testing get_more() on kernel ' . kernel_version($fh) );
    my $stats        = Linux::Info::MemStats->new();
    my $mem_info_ref = $stats->get_more();
    isa_ok( $mem_info_ref, 'HASH', 'what reference get_more() returned' );
    note('Testing mostly basic expected information availability');

    foreach my $stat ( keys( %{$mem_info_ref} ) ) {
        ok( looks_like_number( $mem_info_ref->{$stat} ),
            "$stat has numeric value" )
          or diag("$stat has something wrong: $mem_info_ref->{$stat}");
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
