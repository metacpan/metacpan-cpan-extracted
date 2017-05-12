use Test::More tests => 1;

BEGIN {
    use_ok( 'FilmAffinity::UserRating' ) || print "Bail out!\n";
}

diag( "Testing FilmAffinity::UserRating $FilmAffinity::UserRating::VERSION, Perl $], $^X" );
