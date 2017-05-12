#!perl -w

use Test::More tests => 3;

BEGIN {
    use_ok( 'File::Find::Wanted', qw( find_wanted ) );
}

STAR_DOT_T: {
    my @files = sort( find_wanted( sub { /\.t$/ }, "t/" ) );
    my @match = sort( <t/*.t> );

    is_deeply( \@files, \@match );
}

DIRECTORIES: {
    my @files = sort( find_wanted( sub { -d && !/CVS/ }, "t/" ) );
    my @match = sort( qw( t t/extra ) );

    is_deeply( \@files, \@match );
}

