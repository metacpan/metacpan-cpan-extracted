# $Id: Alternatives.pm,v 1.4 2002/05/11 06:33:44 itz Exp $

package Debian::Debarnacle::Alternatives;

use FileHandle 2.00;
use File::Glob 0.991 qw(bsd_glob GLOB_QUOTE GLOB_BRACE);

sub get_list {
    chdir("/var/lib/dpkg/alternatives") or die "can't chdir to /var/lib/dpkg/alternatives: $!";
    my @altnames = bsd_glob("*");
    my @altfiles = ("/var/lib/dpkg/alternatives");
    foreach my $altname (@altnames) {
        push @altfiles, "/var/lib/dpkg/alternatives/$altname";
        my $fh_alt = FileHandle->new("<$altname");
        defined $fh_alt or die "can't open /var/lib/dpkg/alternatives/$altname: $!";
        my $line = $fh_alt->getline(); # auto/manual
        my $altbasename = $altname;
      ALTLINE:
        while (1) {
            my $altlink = $fh_alt->getline();
            chomp $altlink;
            push @altfiles, "/etc/alternatives/$altbasename";
            push @altfiles, $altlink;
            $altbasename = $fh_alt->getline();
            chomp $altbasename;
            last ALTLINE unless $altbasename;
        }
        $fh_alt->close();
    }
    return \@altfiles;
}

1;
