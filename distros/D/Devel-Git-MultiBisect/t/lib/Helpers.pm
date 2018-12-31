package Helpers;
use strict;
use warnings;
use Carp;
use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    test_report
);

sub test_report {
    my $r = shift;
    return 1 if not defined $r;
    for my $k ( qw| commit commit_short file md5_hex | ) {
        return 0 unless exists $r->{$k};
    }
    return 1;
}

1;

