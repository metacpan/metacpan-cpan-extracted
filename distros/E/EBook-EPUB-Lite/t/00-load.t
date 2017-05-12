#!perl -T

use Test::More tests => 14;

BEGIN {
    use_ok( 'EBook::EPUB::Lite' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Container' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Container::Zip' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Manifest' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Manifest::Item' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Guide' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Guide::Reference' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Spine' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Spine::Itemref' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Metadata' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Metadata::Item' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::Metadata::DCItem' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::NCX' ) || print "Bail out!\n";
    use_ok( 'EBook::EPUB::Lite::NCX::NavPoint' ) || print "Bail out!\n";
}
