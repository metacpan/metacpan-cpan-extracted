#!perl
use warnings;
use strict;

use Test::More tests => 3;
use File::Copy qw(copy);

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}
copy('t/sample.data', 't/write_sample.data');

eval { 
    open my $copy_fh, '<', 't/write_sample.data'
      or die "Can't open the write test copied file: $!";
};

unlike ( $@, qr/open the write/, "Test sample.data file copied successfully" );

unlink 't/write_sample.data';

eval { 
    open my $copy_fh, '<', 't/write_sample.data'
      or die "Can't open the write test copied file: $!";
};

like ( $@, qr/open the write/, "Test sample.data unlinked/deleted successfully" );
