#!perl -T

use Test::More tests => 11;

BEGIN {
    use_ok( 'EBook::FB2' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Binary' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Body' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Body::Section' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description::Author' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description::DocumentInfo' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description::Genre' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description::PublishInfo' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description::Sequence' ) || print "Bail out!\n";
    use_ok( 'EBook::FB2::Description::TitleInfo' ) || print "Bail out!\n";
}

