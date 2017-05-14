# $Id: DocBase.pm,v 1.2 2002/05/11 06:33:50 itz Exp $

package Debian::Debarnacle::DocBase;

use FileHandle 2.00;
use File::Glob 0.991 qw(bsd_glob GLOB_QUOTE GLOB_BRACE);

sub get_list {
    chdir("/var/lib/doc-base/info") or die "can't chdir to /var/lib/doc-base/info: $!";
    my @doclists = bsd_glob("*.list");
    my @docfiles = ();
    foreach my $doclist (@doclists) {
        push @docfiles, "/var/lib/doc-base/info/$doclist";
        my $fh_doclist = FileHandle->new("<$doclist");
        defined $fh_doclist or die "can't open /var/lib/doc-base/info/$doclist: $!";
        while (my $docfile = $fh_doclist->getline()) {
            chomp $docfile;
            push @docfiles, $docfile;
        }
        $fh_doclist->close();
        $doclist =~ /^(.*)\.list$/ ;
        my $base = $1 ;
        push @docfiles, "/var/lib/doc-base/info/$base.status" if -f "$base.status";
    }
    return \@docfiles;
}

1;
