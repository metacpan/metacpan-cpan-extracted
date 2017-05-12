#!perl -Tw

use strict;
use integer;

use File::Spec;

use Test::More 'no_plan';

BEGIN {
    use_ok( 'MARC::File::USMARC' );
}

my $filename = File::Spec->catfile( 't', 'filler.usmarc' );
my $file = MARC::File::USMARC->in( $filename );
isa_ok( $file, 'MARC::File::USMARC', 'opened the test file' );


my $marc;

# There are exactly three records in the file, and there are
# various problems with leading and trailing spaces, nulls,
# and newlines.  There should be no warnings or errors
# reading the file.

$marc = $file->next();
isa_ok( $marc, 'MARC::Record', 'got record 1' );
is( scalar $marc->fields(), 18, 'should be 18 fields' );
is( scalar $marc->warnings(), 0, 'should be 0 warnings' );
ok( !defined $MARC::Record::ERROR, 'should be no errors' );

$marc = $file->next();
isa_ok( $marc, 'MARC::Record', 'got record 2' );
is( scalar $marc->fields(), 18, 'should be 18 fields' );
is( scalar $marc->warnings(), 0, 'should be 0 warnings' );
ok( !defined $MARC::Record::ERROR, 'should be no errors' );

$marc = $file->next();
isa_ok( $marc, 'MARC::Record', 'got record 3' );
is( scalar $marc->fields(), 15, 'should be 15 fields' );
is( scalar $marc->warnings(), 0, 'should be 0 warnings' );
ok( !defined $MARC::Record::ERROR, 'should be no errors' );

# Last record has been read.  The only thing remaining
# before eof is a newline, which should be consumed
# by this next() and undef then returned because we're
# at the file eof.
$marc = $file->next();
ok( !defined $marc, 'no record, just eof' );
ok( !defined $MARC::Record::ERROR, 'should be no errors' );

$file->close;
