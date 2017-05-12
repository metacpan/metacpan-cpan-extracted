#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Games::EternalLands::Loader' ) || print "Bail out!\n";
}

diag( "Testing Games::EternalLands::Loader $Games::EternalLands::Loader::VERSION, Perl $], $^X" );

my $l = Games::EternalLands::Loader->new;
ok(defined $l);
ok($l->isa('Games::EternalLands::Loader'));
