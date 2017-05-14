# $Id: Dpkg.pm,v 1.3 2002/05/10 02:58:44 itz Exp $

package Debian::Debarnacle::Dpkg;

use File::Find;

our @dpkg_files;

sub add_dpkgfile {
    push @dpkg_files, $File::Find::name
        if -f $File::Find::name && $File::Find::name =~ /\.dpkg-(old|new|save|dist)$/ ;
}

sub get_list {
    @dpkg_files = ();
    find (\&add_dpkgfile, '/etc');


    push @dpkg_files, grep(-f, (map "/var/lib/dpkg/$_",
                               qw (available available-old cmethopt diversions
                                   diversions-old lock methlock status status-old
                                   statoverride statoverride-old)
                               )
                          );
    return \@dpkg_files;
}

1;
