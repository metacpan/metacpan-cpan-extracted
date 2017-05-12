package Linux::Smaps::Tiny::PP;
BEGIN {
  $Linux::Smaps::Tiny::PP::AUTHORITY = 'cpan:AVAR';
}
{
  $Linux::Smaps::Tiny::PP::VERSION = '0.10';
}
use strict;
use warnings FATAL => "all";

sub __get_smaps_summary {
    my $proc_id= shift || "self";
    my $smaps_file= "/proc/$proc_id/smaps";
    open my $fh, "<", $smaps_file
        or do {
            my $errnum= 0+$!; # numify
            my $errmsg= "$!"; # stringify
            my $msg= "In get_smaps_summary, failed to read '$smaps_file': [$errnum] $errmsg";

            die $msg;
        };
    my %sum;
    while (<$fh>) {
        next unless substr($_,-3) eq "kB\n";
        my ($field, $value)= split /:/,$_;
        no warnings 'numeric';
        $sum{$field}+=$value if $value;
    }
    close $fh;
    return \%sum;
}

1;
