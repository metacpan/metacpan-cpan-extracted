#!perl -Tw

# $Id: title_proper.t,v 1.6 2005/01/05 04:30:24 eijabb Exp $

use strict;
use integer;
use File::Spec;
use Test::More tests=>14;

BEGIN {
    use_ok( 'MARC::File::USMARC' );
}

my @titles = (
    'Current population reports. Series P-20, Population characteristics.',
    'Current population reports. Series P-60, Consumer income.',
    'Physical review. A, Atomic, molecular, and optical physics',
    'Physical review. B, Condensed matter',
    'America and the British Labour Party :',
);

my $filename = File::Spec->catfile( 't', 'title_proper.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', 'USMARC file' );

while ( my $marc = $file->next() ) {
    isa_ok( $marc, 'MARC::Record', 'Got a record' );

    my $title = shift @titles;
    is( $marc->title_proper, $title );
}
ok( !$MARC::File::ERROR, "Should have no error" );
is( scalar @titles, 0, "no titles left to check" );

$file->close;

