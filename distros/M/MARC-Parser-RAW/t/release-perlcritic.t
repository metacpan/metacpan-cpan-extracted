
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}

use strict;
use warnings;

use Test::More;

## no critic
eval 'use Test::Perl::Critic 1.02';
plan skip_all => 'Test::Perl::Critic 1.02 required' if $@;

my @files = ( Perl::Critic::Utils::all_perl_files(qw( bin lib )) );

foreach my $file (@files) {
    critic_ok( $file, $file );
}

done_testing();
