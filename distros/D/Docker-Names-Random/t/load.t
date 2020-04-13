#!perl -T

use utf8;
use Test2::V0;
set_encoding('utf8');

require Docker::Names::Random;

diag(   'Testing Docker::Names::Random '
      . ( $Docker::Names::Random::VERSION ? "($Docker::Names::Random::VERSION)" : '(no version)' )
      . ", Perl $], $^X" );

can_ok( 'Docker::Names::Random', 'new' );
can_ok( 'Docker::Names::Random', 'docker_name' );

my $dnr = Docker::Names::Random->new();
isa_ok( $dnr, 'Docker::Names::Random' );

done_testing();

