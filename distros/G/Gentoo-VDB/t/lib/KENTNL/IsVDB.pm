use 5.006;    # our
use strict;
use warnings;

package KENTNL::IsVDB;

our $VERSION = '0.001000';

# ABSTRACT: Basic checks if a directory looks-like a testable VDB

# AUTHORITY

# Children of these categories proliferate the system
# set, so any real vdb's should have one of them
our (@category_list) = qw(
  virtual sys-devel sys-apps app-arch
);

sub _skip_all {
    print "1..0 # SKIP $_[0]\n";
    exit;
}

my $gpd = "Gentoo Portage database";

sub check_isvdb {
    my ($path) = @_;
    my $rprefix = "$path is not a Gentoo Portage database:";
    -e $path or return _skip_all("$rprefix does not exist: $!");
    -r $path or return _skip_all("$rprefix is not readable: $!");
    -d $path or return _skip_all("$rprefix is not a dir: $!");

    for my $category (@category_list) {
        my $subpath = $path . q[/] . $category;
        return if -e $subpath and -r $subpath and -d $subpath;
    }

    return _skip_all( "$rprefix has none of categories: " . join q{, },
        @category_list );
}
1;

