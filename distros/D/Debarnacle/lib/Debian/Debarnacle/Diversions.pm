# $Id: Diversions.pm,v 1.1 2002/05/08 21:07:58 itz Exp $

package Debian::Debarnacle::Diversions;

use FileHandle 2.00;

sub get_list {
    my $fh_div = FileHandle->new("</var/lib/dpkg/diversions");
    defined $fh_div or die "can't list diversions: $!";
    my @divfiles = ();
    while ($_ = $fh_div->getline()) {
        my $diversion = $fh_div->getline();
        chomp $diversion;
        push @divfiles, $diversion if -f $diversion;
        $_ = $fh_div->getline();    # throw away diverted_by line
    }
    $fh_div->close();
    return \@divfiles;
}

1;
