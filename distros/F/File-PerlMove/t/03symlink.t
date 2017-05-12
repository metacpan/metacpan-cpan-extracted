#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    # Check if we can symlink.
    if ( eval { symlink("",""); 1 } ) {
	plan( tests => 9 );
    }
    else {
	plan( skip_all => "Platform has no symlink" );
    }
}

BEGIN {
    use_ok('File::PerlMove');
}

-d "t" && chdir("t");

require_ok("./00common.pl");

our $sz = create_testfile(our $tf = "03symlink.dat");

try_symlink('s/\.dat$/.tmp/', "03symlink.tmp", "symlink1");

{ my $warn;
  local $SIG{__WARN__} = sub { $warn = "@_"; };
  $tf = "03symlink.dat";
  is(File::PerlMove::move('s/\.dat$/.tmp/', [ $tf ], { symlink => 1 }), 0, "symlink2");
  like($warn, qr/: exists/, "symlink2 warning");
}

cleanup();

sub try_symlink {
    my ($code, $new, $tag) = @_;
    is(File::PerlMove::move($code, [ $tf ], { symlink => 1 }), 1, $tag);
    verify($new, $tag);
    my @st1 = lstat($tf);
    my @st2 = lstat($new);
    is(-s $new, $sz, "$tag check size");
    isnt($st1[1], $st2[1], "$tag check inode");
    $tf = $new;
}

