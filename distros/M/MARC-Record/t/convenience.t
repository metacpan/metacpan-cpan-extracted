#!perl -Tw

use strict;
use integer;

use constant EMPTY_TESTS => 10;
use constant PERLCONF_SKIPS => 6;
use constant CAMEL_SKIPS => 2;
use constant XPLATFORM_SKIPS => 2;

use File::Spec;

# the 10 is for the EMPTY: block of tests
use Test::More tests=>( 2 + EMPTY_TESTS + (5*3) + CAMEL_SKIPS + PERLCONF_SKIPS + XPLATFORM_SKIPS );

BEGIN {
    use_ok( 'MARC::File::USMARC' );
}

EMPTY: { my $marc = MARC::Record->new();
    ok( defined $marc->title(), 'if data not present, title() is not undef' );
    is( $marc->title(), '', 'if data not present, title() is empty string' );
    ok( defined $marc->title_proper(), 'if data not present, title_proper() is not undef' );
    is( $marc->title_proper(), '', 'if data not present, title_proper() is empty string' );
    ok( defined $marc->author(), 'if data not present, author() is not undef' );
    is( $marc->author(), '', 'if data not present, author() is empty string' );
    ok( defined $marc->edition(), 'if data not present, edition() is not undef' );
    is( $marc->edition(), '', 'if data not present, edition() is empty string' );
    ok( defined $marc->publication_date(), 'if data not present, publication_date() is not undef' );
    is( $marc->publication_date(), '', 'if data not present, publication_date() is empty string' );
}

my $filename = File::Spec->catfile( 't', 'camel.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', 'USMARC file' );

my $marc;
for ( 1..PERLCONF_SKIPS ) { # Skip to the Perl conference
    $marc = $file->next();
    isa_ok( $marc, 'MARC::Record', 'Got a record' );
}

is( $marc->author,		'Perl Conference 4.0 (2000 : Monterey, Calif.)' );
is( $marc->title,		'Proceedings of the Perl Conference 4.0 : July 17-20, 2000, Monterey, California.' );
is( $marc->title_proper,	'Proceedings of the Perl Conference 4.0 :' );
is( $marc->edition,		'1st ed.' );
is( $marc->publication_date,	'2000.' );

for ( 1..CAMEL_SKIPS ) { # Skip to the camel
    $marc = $file->next();
    isa_ok( $marc, 'MARC::Record', 'Got a record' );
}

is( $marc->author,		'Wall, Larry.' );
is( $marc->title,		'Programming Perl / Larry Wall, Tom Christiansen & Jon Orwant.' );
is( $marc->title_proper,	'Programming Perl /' );
is( $marc->edition,		'3rd ed.' );
is( $marc->publication_date,	'2000.' );

for ( 1..XPLATFORM_SKIPS ) { # Skip to Cross-Platform Perl
    $marc = $file->next();
    isa_ok( $marc, 'MARC::Record', 'Got a record' );
}

is( $marc->author,		'Foster-Johnson, Eric.' );
is( $marc->title,		'Cross-platform Perl / Eric F. Johnson.' );
is( $marc->title_proper,	'Cross-platform Perl /' );
is( $marc->edition,		'' );
is( $marc->publication_date,	'2000.' );

$file->close;

