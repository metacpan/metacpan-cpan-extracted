use strict;
use warnings;
my $VERSION = 1;

use lib qw(../lib . t/);
use ExtUtils::testlib;
use ExtUtils::Manifest;
use Data::Dumper;
use Test::More tests => 3;

# mkmanifest();

my ($missing, $extra) = ExtUtils::Manifest::fullcheck();

@_ = grep {/t\W.*\.t$/} @$missing;
is( 0, scalar(@_), 'No tests missing from manifest') or diag join", ",@_;

@_ = grep {/\.pm$/} @$missing;
is( 0, scalar(@_), 'No PMs missing from manifest') or diag join", ",@_;

is( 0, scalar(@$extra), 'No un-MANIFESTed files found') or diag join"\n",@$extra;

=head1 TEST F<001_MANIFEST.t>

This script tests the manifest if reasonable.

=head1 COPYRIGT

Copyright (C) Lee Godadrd 2007-2008. all rights reserved.
Available under the same terms as Perl itself.

