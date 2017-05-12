use Test::More tests => 8;

use Mac::Path::Util;

my $util = Mac::Path::Util->new('/Users/brian');
isa_ok( $util, 'Mac::Path::Util' );
is( $util->type, Mac::Path::Util::DARWIN, "Type is Darwin" );

$util = Mac::Path::Util->new('Otter:Users:brian');
isa_ok( $util, 'Mac::Path::Util' );
is( $util->type, Mac::Path::Util::MACOS, "Type is Mac OS" );

$util = Mac::Path::Util->new('Otter');
isa_ok( $util, 'Mac::Path::Util' );
is( $util->type, Mac::Path::Util::DONT_KNOW, "Type is unknown" );

$util = Mac::Path::Util->new('Otter: foo / bar');
isa_ok( $util, 'Mac::Path::Util' );
is( $util->type, Mac::Path::Util::DONT_KNOW, "Bad path is unknown" );
