#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Path::ScanINC;
use Path::Tiny;
use Dist::Zilla::Util;

my (@alldirs) = Path::ScanINC->new()->all_dirs( 'Dist', 'Zilla', 'Role' );
my (@roles);

for my $dir (@alldirs) {
  my $it = path($dir)->iterator( { recurse => 1, follow_symlinks => 0 } );
  while ( my $item = $it->() ) {
    next unless $item =~ /.pm\z/msx;
    next unless -f $item;
    my $e = Dist::Zilla::Util::PEA->_new();
    $e->read_string( $item->slurp_utf8 );
    my $r = $item->relative($dir);
    $r =~ s/[.]pm\z//msx;
    $r =~ s{/}{::}mxgs;
    printf qq[_entry( name => q[-%s] =>, description => q[%s] );\n], $r, $e->{abstract};
  }

}

