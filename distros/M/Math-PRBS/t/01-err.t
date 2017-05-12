########################################################################
# Tests for error conditions which should cause the module to die()
########################################################################
use 5.006;
use strict;
use warnings;
use Test::More tests => 12;

use Math::PRBS;

sub DEBUG { 0 };

my $seq;

eval { no warnings qw(misc uninitialized); $seq = Math::PRBS->new( 15 ); }; chomp($@);
ok( $@ ,                                                        "new(15) should fail due to unknown arguments" );
diag( $@ ) if DEBUG;
    # would need { no warnings qw(misc uninitialized); } in ->new() to prevent the warnings from printing
    #   misc: 'odd number of elements in hash assignment'
    #   uninitialized: 'use of uninitialized value $pairs{"15"} in join or string'

eval { $seq = Math::PRBS->new( unknown => 1 ); }; chomp($@);
ok( $@ ,                                                        "new(unknown=>1) should fail due to unknown arguments" );
diag( $@ ) if DEBUG;

eval { $seq = Math::PRBS->new( prbs => 3 ); }; chomp($@);
ok( $@ ,                                                        "new(prbs=>3) should fail due to non-standard prbs" );
diag( $@ ) if DEBUG;

eval { $seq = Math::PRBS->new( taps => 3 ); }; chomp($@);
ok( $@ ,                                                        "new(taps=>3) should fail due to 'taps' needing array ref" );
diag( $@ ) if DEBUG;

eval { $seq = Math::PRBS->new( taps => [] ); }; chomp($@);
ok( $@ ,                                                        "new(taps=>[]) should fail due to 'taps' needing at least one tap" );
diag( $@ ) if DEBUG;

eval { $seq = Math::PRBS->new( poly => [1] ); }; chomp($@);
ok( $@ ,                                                        "new(poly=>[1]) should fail due to 'poly' needing binary string" );
diag( $@ ) if DEBUG;

eval { $seq = Math::PRBS->new( poly => 'xyz' ); }; chomp($@);
ok( $@ ,                                                        "new(poly=>'xyz') should fail due to 'poly' needing binary string" );
diag( $@ ) if DEBUG;

eval { $seq = Math::PRBS->new( poly => '000' ); }; chomp($@);
ok( $@ ,                                                        "new(taps=>'000') should fail due to 'poly' needing at least one tap" );
diag( $@ ) if DEBUG;

eval { Math::PRBS->new( poly => '110' )->period(5); }; chomp($@);
ok( $@ ,                                                        "period(5) should fail due to requiring a hash argument" );
diag( $@ ) if DEBUG;

eval { Math::PRBS->new( poly => '110' )->generate_all(5); }; chomp($@);
ok( $@ ,                                                        "generate_all(5) should fail due to requiring a hash argument" );
diag( $@ ) if DEBUG;

eval { Math::PRBS->new( poly => '110' )->generate_to_end(5); }; chomp($@);
ok( $@ ,                                                        "generate_to_end(5) should fail due to requiring a hash argument" );
diag( $@ ) if DEBUG;

eval { Math::PRBS->new( poly => '110' )->seek_to_end(5); }; chomp($@);
ok( $@ ,                                                        "seek_to_end(5) should fail due to requiring a hash argument" );
diag( $@ ) if DEBUG;
