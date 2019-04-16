#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

my $tzil = Builder->from_config({ dist_root => 'corpus/oDZT' });

$tzil->build;

version_ok( path($tzil->tempdir)->child('build/lib/oDZT.pm'));

my $lib_0 = $tzil->slurp_file('build/lib/oDZT.pm');

# e short for expected files
# -------------------------------------------------------------------

my $elib_0 = <<'END LIB8';
use strict;
use warnings;
package oDZT;
# ABSTRACT: lots of false leads here
<<END
# VERSION
END

=pod

# VERSION

=cut

our $VERSION = 'v0.1.0'; # VERSION

BEGIN { our $VERSION= 'v0.1.0'; } # VERSION

our $FOO = 1; our $VERSION='v0.1.0'; our $BAR = 2; # VERSION

1;
__END__

# VERSION
END LIB8

# -------------------------------------------------------------------

is ( $lib_0, $elib_0, 'check oDZT.pm' );

done_testing;
