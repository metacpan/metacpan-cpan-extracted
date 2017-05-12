package Utils;

use strict;
use warnings;

use parent 'Exporter';

use GitStore;
use Path::Tiny qw/ tempdir /;
use Test::More;

our @EXPORT = qw/ new_gitstore /;

my @stores;

sub new_gitstore {
    my $dir = tempdir( DIR => 't/stores', CLEANUP => $ENV{'PERL_TEST_HARNESS'} );
    diag "creating gitstore at '$dir'";
    push @stores, $dir; # so it doesn't go out of scope...
    GitStore->create($dir->stringify);
}

1;

