#!perl -Tw

use strict;
use Test::More tests => 4;
use MARC::File::USMARC;
use File::Spec;

my $filename = File::Spec->catfile( 't', 'baddir.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC' );

my $r = $file->next(); 
isa_ok( $r, 'MARC::Record' );

my @warnings = $r->warnings();

is( $warnings[0], 'No directory found in record 1', 
    'got bad directory warning' );
is( $r->title(), 'Green Eggs and Ham', 
    'found title despite bad directory' );

