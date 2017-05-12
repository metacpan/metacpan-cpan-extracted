
use strict;
use warnings;
use Test::More tests => 36;
use Test::NoWarnings;

use lib './lib';
use File::Util qw( SL OS );

my $f = File::Util->new();

my @fls = ( qq[t${\SL}txt], qq[t${\SL}bin], 't', '.', '..' );

# types
is_deeply
   [ $f->file_type( $fls[0] ) ],
   [ qw( PLAIN TEXT ) ],
   'text file detected as PLAIN TEXT OK';

is_deeply
   [ $f->file_type( $fls[1] ) ],
   [ qw( PLAIN BINARY ) ],
   'bin file detected as PLAIN BINARY OK';

# file is/isn't binary
ok $f->is_bin( $fls[1], 1 ), 'detects binary file is binary';
ok !$f->is_bin( __FILE__ ), 'detects source file is NOT binary';

for my $file ( @fls ) {

   # get file size
   ok $f->size( $file ) == -s $file,
      'File::Util correctly calculates a file\'s size';

   # get file creation time
   ok $f->created( $file ) == $^T - ((-M $file) * 60 * 60 * 24),
      'and gets correct file creation time OK';

   # get file last access time
   ok $f->last_access( $file ) == $^T - ((-A $file) * 60 * 60 * 24),
      'and gets last access time OK';

   # get file last modified time
   ok $f->last_modified( $file ) == $^T - ((-M $file) * 60 * 60 * 24),
      'and gets lastmod time OK';

   # get file's bitmask
   ok $f->bitmask( $file ) eq sprintf('%04o',(stat($file))[2] & 0777),
      'and gets bitmask OK';
}

SKIP: {
   skip 'these tests not performed on window$', 3 if OS eq 'WINDOWS';

   is_deeply
      [ $f->file_type( $fls[2] ) ],
      [ qw( BINARY DIRECTORY ) ],
      'detects directory filetype OK';

   is_deeply
      [ $f->file_type( $fls[3] ) ],
      [ qw( BINARY DIRECTORY ) ],
      'detects directory filetype OK';

   is_deeply
      [ $f->file_type( $fls[4] ) ],
      [ qw( BINARY DIRECTORY ) ],
      'detects directory filetype OK';
}

is +( $f->file_type( $fls[2] ) )[-1],
   'DIRECTORY',
   'detects file is a directory OK';

is +( $f->file_type( $fls[3] ) )[-1],
   'DIRECTORY',
   'detects file is a directory OK';

is +( $f->file_type( $fls[4] ) )[-1],
   'DIRECTORY',
   'detects file is a directory OK';

exit;
