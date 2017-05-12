#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 6;

BEGIN {
    use_ok 'IO::AIO';
    use_ok 'Filesys::Virtual::Async';
    use_ok 'Filesys::Virtual::Async::Plain';
}

my $fs = Filesys::Virtual::Async::Plain->new( root => $ENV{PWD} );
my $file = '/Makefile.PL';
my $path = $fs->_path_from_root( $file );
pass("started, stating file:".$path);
if ( -e $path ) {
    pass("CORE::stat says file exists: $path");
} else {
    fail("CORE::stat said that $path doesn't exist");
}
$fs->stat( $file, sub {
    my $status = $_[0];
    # IO::AIO docs are wrong, use 'or' not 'and' here, because
    # $_[0] is an array of the stat() return on success
    $status or die "AIO: stat failed $!";
    if ( -e _ ) {
        pass("AIO: file exists, size:".( -s _ ));
    } else {
        fail("AIO: file doesn't exist");
    }
});

1;
