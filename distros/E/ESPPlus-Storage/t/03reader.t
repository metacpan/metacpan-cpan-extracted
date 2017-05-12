use strict;
use warnings;
use Test::More tests => 9;
use File::Basename;
use File::Spec::Functions;
use ESPPlus::Storage;
use IO::File;

my $test_dir = dirname( $0 );
my $test_db = catfile( $test_dir, 'read.rep' );
my $handle = IO::File->new;
open $handle, "<", $test_db or die "Couldn't open $test_db for reading: $!";

is( $ESPPlus::Storage::Reader::COMPRESS_MAGIC_NUMBER,
    "\037\235",
    "Magic number matches .Z expectations" );

### ->new
my $o = ESPPlus::Storage::Reader->new
  ( { uncompress_function => sub { "Nothing here" },
      handle              => $handle });
is( ref $o,
    'ESPPlus::Storage::Reader',
    '::Reader->new( ... ) isa ::Reader' );

### ->uncompress_function
is( ref $o->uncompress_function,
    'CODE',
    '::Reader->uncompress_function() isa CODE' );

### ->handle
is( ref $o->handle,
    'IO::File',
    '::Reader->handle() isa IO::File' );

### ->record_number
is( $o->record_number,
    0,
    '::Reader->record_number' );

### ->buffer
is( ref $o->buffer,
    'SCALAR',
    '::Reader->buffer isa SCALAR' );

my $rec = $o->next_record;
ok( $rec, '::Reader->next_record()' );
is( ref $rec,
    'ESPPlus::Storage::Record',
    '::Reader->next_record() isa ::Record' );

is( $o->record_number,
    1,
    '::Reader->record_number increments' );


### ->next_record_body
#ok( length $o->next_record_body, '::Reader->next_record_body' );
#is( $o->record_number, 1, '::Reader->record_number still increments' );
#seek $o->handle, 0, 0;
#$o->{'record_number'} = 0;
