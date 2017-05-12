#!perl

use strict;
use warnings;

use Test::DZil;
use Path::Tiny;
use File::pushd 1.00 qw/tempd pushd/;
use Test::More 0.92;

my $corpus_dir = path(qw(corpus foo))->absolute;
my $tempd      = tempd;                         # isolate effects

my $lib_src = << 'HERE';
package Bar;
# ABSTRACT: Bar
1;
# CO
__END__
HERE

my $bin_src = << 'HERE';
#!/usr/bin/perl
print "foo\n";

# CO
HERE

# have to hide the magic phrase from ourself
s{# CO}{# COPYRIGHT}g for ( $lib_src, $bin_src );

# build fake dist
my $tzil = Builder->from_config(
    { dist_root => $corpus_dir, },
    {
        add_files => {
            'source/lib/Bar.pm' => $lib_src,
            'source/bin/foobar' => $bin_src,
        }
    }
);
$tzil->build;

# check module & script
my $dir = path( $tzil->tempdir )->child('build');
check_copyright( path( $dir, 'lib',     'Bar.pm' ) );
check_copyright( path( $dir, 'bin',     'foobar' ) );
check_copyright( path( $dir, 'example', 'latin1' ) );

done_testing;
exit;

sub check_copyright {
    my ($path) = @_;

    # slurp file
    my @lines = $path->lines( { chomp => 1 } );

    my ( $hash_count, $offset ) = ( 0, 0 );
    for ( ; $offset < $#lines; $offset++ ) {
        $hash_count++ if $lines[$offset] =~ /\A#/;
        last if $hash_count == 2;
    }

    is( $lines[ 0+ $offset ], '#', $path->relative($dir) ) or diag join( "\n", @lines );
    is( $lines[ 1 + $offset ], '# This file is part of Foo' );
    is( $lines[ 2 + $offset ], '#' );
    is( $lines[ 3 + $offset ], '# This software is copyright (c) 2009 by foobar.' );
    is( $lines[ 4 + $offset ], '#' );
    is( $lines[ 5 + $offset ],
        '# This is free software; you can redistribute it and/or modify it under' );
    is( $lines[ 6 + $offset ],
        '# the same terms as the Perl 5 programming language system itself.' );
    is( $lines[ 7 + $offset ], '#' );
}

