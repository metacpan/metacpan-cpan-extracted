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
package Baz;
# ABSTRACT: Baz
# 안녕하세요.
# こんにちは。
# 你好。
1;
# CO
__END__
HERE

# have to hide the magic phrase from ourself
s{# CO}{# COPYRIGHT}g for ($lib_src);

# build fake dist
my $tzil = Builder->from_config( { dist_root => $corpus_dir, },
    { add_files => { 'source/lib/Baz.pm' => $lib_src, } } );
$tzil->build;

# check module & script
my $dir = path( $tzil->tempdir )->child('build');
my $path = path( $dir, 'lib', 'Baz.pm' );

my @lines = $path->lines_utf8( { chomp => 1 } );
chomp( my @expected_lines = <DATA> );

for ( my $i = 0; $i < @lines; ++$i ) {
    is( $lines[$i], $expected_lines[$i] );
}

done_testing;
exit;

__DATA__
package Baz;
# ABSTRACT: Baz
# 안녕하세요.
# こんにちは。
# 你好。
1;
#
# This file is part of Foo
#
# This software is copyright (c) 2009 by foobar.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
__END__
