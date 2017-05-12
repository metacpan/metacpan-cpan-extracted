use 5.008;
use strict;
use warnings;
use Test::More 0.96;

use Test::DZil;

my $root = 'corpus/DZ';

{
    my $tzil = Builder->from_config( { dist_root => 'corpus/DZT' },
        { add_files => { 'source/dist.ini' => simple_ini(qw/GatherDir Pod2Readme/) } } );

    ok( $tzil, "created test dist" );

    $tzil->build;

    my $contents = $tzil->slurp_file('build/README');

    like( $contents, qr{DZT::Sample}, "dist name appears in README", );

    like( $contents, qr{Foo the foo}, "description appears in README" );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir', [ Pod2Readme => { source_filename => 'lib/DZT/Sample2.pm' } ]
                )
            }
        }
    );

    ok( $tzil, "created test dist" );

    $tzil->build;

    my $contents = $tzil->slurp_file('build/README');

    like( $contents, qr{DZT::Sample2}, "module name appears in README", );

    like( $contents, qr{Bar the bar}, "description appears in README" );
}

done_testing;
#
# This file is part of Dist-Zilla-Plugin-Pod2Readme
#
# This software is Copyright (c) 2014 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
