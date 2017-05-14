# $Id: Globs.pm,v 1.3 2002/05/11 06:33:55 itz Exp $

# this is the catch-all plugin.  just reads globs from
# /etc/debarnacle/globs and returns a list of all matching files.

package Debian::Debarnacle::Globs;

use FileHandle 2.00;
use File::Glob 0.991 qw(bsd_glob GLOB_QUOTE GLOB_BRACE);

sub get_list {
    my @globs_files = ();
    my $fh_globs = FileHandle->new("<$main::pkgconfdir/globs");
    defined $fh_globs or die "can't open $main::pkgconfdir/globs: $!";
  GLOB_LINE:
    while (my $glob_line = $fh_globs->getline()) {
        next GLOB_LINE if $glob_line =~ /^\s*\#/ ;
        next GLOB_LINE if $glob_line =~ /^\s*$/ ;
        chomp $glob_line;
        push @globs_files, bsd_glob($glob_line, GLOB_BRACE|GLOB_QUOTE);
    }
    $fh_globs->close();
    return \@globs_files;
}

1;
