use strict;
use warnings;

use Test::DZil;
use Path::Tiny;
use Test::More 0.88;
use Test::Deep;

# build fake dist
my $tzil = Builder->from_config({
    dist_root => path(qw(t foo)),
});
$tzil->build;

# check module & script
my $build_dir = path($tzil->tempdir)->child('build');
check_top_of_file( $build_dir->child('lib', 'Foo.pm'), 0 );
check_top_of_file( $build_dir->child('bin', 'foobar'), 1 );
check_top_of_file( $build_dir->child('bin', 'foobarbaz'), 1 );

is $tzil->slurp_file(path(qw(build t support.pl))),
   "# only used during tests\nuse strict;\n1;\n",
   'file ignored according to configuration';

done_testing;
exit;

sub check_top_of_file {
    my ($path, $offset) = @_;

    my @lines = path($path)->lines({ count => 10 + $offset, chomp => 1 });
    splice(@lines, 0, $offset) if $offset;

    cmp_deeply(
        \@lines,
        [
            '#',
            '# This file is part of Foo',
            '#',
            '# This software is copyright (c) 2009 by foobar.',
            '#',
            '# This is free software; you can redistribute it and/or modify it under',
            '# the same terms as the Perl 5 programming language system itself.',
            '#',
            'use strict;',
            'use warnings;',
        ],
        "lines in $path are correct (after $offset offset lines)",
    );
}
