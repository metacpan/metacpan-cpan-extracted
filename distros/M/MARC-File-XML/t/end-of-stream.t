use strict;
use warnings;

use MARC::File::XML;
use MARC::Record;
use Test::Warn;
use Test::More tests => 6;


my $file = MARC::File::XML->in( 't/subfield0.xml' );
my $r = $file->next();
isa_ok( $r, 'MARC::Record', 'fetch record using ->in()' );

warning_is { $r = $file->next() } undef, 'no warnings at end of stream (RT#111473)';
is( $r, undef, 'get undefined at end of stream' );

$file = MARC::File::XML->in( 't/end-of-stream.xml' );
$r = $file->next();
isa_ok( $r, 'MARC::Record', 'fetch record using ->in()' );

warning_is { $r = $file->next() } undef, 'no warnings at end of stream (RT#111473)';
is( $r, undef, 'get undefined at end of stream' );
