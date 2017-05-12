# $Id: test.pl,v 1.1 2003/03/31 17:42:16 deschwen Exp $

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use HPUX::Pstat;
$loaded = 1;
print "ok 1\n";

print pstat_getstatic()        ? "" : "not ", "ok 2\n";
print pstat_getdynamic()       ? "" : "not ", "ok 3\n";
print pstat_getvminfo()        ? "" : "not ", "ok 4\n";
print pstat_getswap()          ? "" : "not ", "ok 5\n";
print pstat_getproc()          ? "" : "not ", "ok 6\n";
print pstat_getprocessor()     ? "" : "not ", "ok 7\n";


sub pstat_getstatic
{
    my $x = HPUX::Pstat::getstatic();
    return defined $x and exists $x->{'page_size'};
}

sub pstat_getdynamic
{
    my $x = HPUX::Pstat::getdynamic();
    return defined $x and exists $x->{'psd_proc_cnt'};
}

sub pstat_getvminfo
{
    my $x = HPUX::Pstat::getvminfo();
    return defined $x and exists $x->{'psv_sswtch'};
}

sub pstat_getswap
{
    my $x = HPUX::Pstat::getswap();
    return defined $x and exists $x->[0]->{'pss_idx'};
}

sub pstat_getproc
{
    my $x = HPUX::Pstat::getproc();
    return defined $x and exists $x->[0]->{'pst_idx'};
}

sub pstat_getprocessor
{
    my $x = HPUX::Pstat::getprocessor();
    return defined $x and exists $x->[0]->{'psp_idx'};
}


