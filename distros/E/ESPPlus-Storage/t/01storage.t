use strict;
use warnings;
use Test::More tests => 14;
use File::Basename;
use File::Spec::Functions;
use ESPPlus::Storage;

my $test_dir = dirname( $0 );

is( ref(ESPPlus::Storage->new({ filename => $0 })),
    'ESPPlus::Storage',
    '::Storage->new()' );

my $invalid = eval { ESPPlus::Storage->new({ 'invalid', '' }) };
ok( $@,
    '::Storage->new( invalid ... ) throws errors' );

my $o = ESPPlus::Storage->new({ compress_function => 1,
			       	uncompress_function => 2,
			        filename => 3,
			        handle   => 4 });
is( $o->compress_function,   1, '::Storage->compress_function()' );
is( $o->uncompress_function, 2, '::Storage->uncompress_function()' );
is( $o->filename,            3, '::Storage->filename()' );
is( $o->handle,              4, '::Storage->handle()' );

$o->compress_function( 0 );
is( $o->compress_function, 0, '::Storage->compress_function( ... )' );

$o->uncompress_function( 0 );
is( $o->uncompress_function, 0, '::Storage->uncompress_function( ... )' );

$o->filename( 0 );
is( $o->filename, 0, '::Storage->filename( ... )' );

$o->handle( 0 );
is( $o->handle, 0, '::Storage->handle( ... )' );

delete $o->{'handle'};
delete $o->{'filename'};
$o->filename( $0 );
ok( ref $o->handle, '->handle returns a reference' );
ok( UNIVERSAL::isa($o->handle, 'IO::File'), '->handle returns an IO::File object' );

is( ref($o->reader), "${\ref $o}::Reader",
    "->reader returns ${\ref $o}::Reader object" );

is( ref($o->writer), "${\ref $o}::Writer",
    "->writer returns ${\ref $o}::Writer object" );
