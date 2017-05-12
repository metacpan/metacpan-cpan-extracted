#!perl

use strict;
use warnings;
use Test::More ;

my $min_carp = 0.2;  # Ensure a recent version of Test::Carp

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author tests not required for installation');
}

eval "use Test::Carp $min_carp";
plan skip_all => 'Test::Carp $min_carp required' if $@; 

# Tests starts here (confess() test if line is 'undef')

use Filter::Heredoc qw( hd_getstate );
use Filter::Heredoc qw( @CARP_UNDEF );

my $reg = qr/$CARP_UNDEF[0]/;

my $line = undef;

does_confess( sub { hd_getstate(); } );

does_confess_that_matches( sub { hd_getstate(); }, undef ,$reg ) ;

done_testing (2);
