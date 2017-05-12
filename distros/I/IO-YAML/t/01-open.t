use strict;
use warnings;

use Test::More 'tests' => 13;

use File::Copy qw(copy);
use YAML::XS;

use_ok( 'IO::YAML' );

my $test_r = 't/sandbox/read.yaml';
my $test_w = 't/sandbox/write.yaml';
my $test_a = 't/sandbox/append.yaml';

copy( 't/one.yaml', $test_r );

# --- Clean up after previous tests

unlink($test_w) if -e $test_w;
unlink($test_a) if -e $test_a;

my $io = IO::YAML->new;

isa_ok( $io, 'IO::YAML' );

# --- Open for reading
my $test_r_modtime = -M $test_r;
ok( $io->open($test_r),          'open (read)'     );
is( $io->mode, '<',              'default mode'    );
ok( -e $test_r,                  'deleted (read)'  );
is( -M $test_r, $test_r_modtime, 'modified (read)' );
ok( $io->close,                  'close (read)'    );

# --- Open for writing
ok( $io->open($test_w, '>'),  'open (write)'     );
ok( -e $test_w,               'created (write)'  );
ok( $io->close,               'close (write)'    );

# --- Open for append
ok( $io->open($test_a, '>>'), 'open (append)'    );
ok( -e $test_a,               'created (append)' );
ok( $io->close,               'close (append)'   );

# --- Clean up for future tests

unlink($test_r);
unlink($test_w);
unlink($test_a);

