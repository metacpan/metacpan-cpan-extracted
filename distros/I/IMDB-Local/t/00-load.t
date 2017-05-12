#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 13;

BEGIN {
    use_ok( 'IMDB::Local' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::DB' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::DB::RecordIterator' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Title' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Genre' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Actor' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Rating' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Keyword' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Director' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Plot' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::Movie' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::TVShow' ) || print "Bail out!\n";
    use_ok( 'IMDB::Local::VideoGame' ) || print "Bail out!\n";
}

diag( "Testing IMDB::Local $IMDB::Local::VERSION, Perl $], $^X" );
