use strict;
use warnings;
use Test::More;

# inspired by http://perlmaven.com/enable-test-perl-critic

unless ( $ENV{AUTHOR_TESTING} ) {
    plan skip_all => 'Author test, set $ENV{AUTHOR_TESTING} to run';
}

## no critic
eval 'use Test::Perl::Critic 1.02';
plan skip_all => 'Test::Perl::Critic 1.02 required' if $@;

# NOTE: New files will be tested automatically.

my @files = ( Perl::Critic::Utils::all_perl_files(qw( Makefile.PL bin lib t )) );

foreach my $file (@files) {
    critic_ok( $file, $file );
}

done_testing();
