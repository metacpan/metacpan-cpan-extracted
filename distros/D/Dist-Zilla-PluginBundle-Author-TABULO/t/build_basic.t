use 5.008001;
use strict;
use warnings;

use Test::More 0.96;
use File::pushd qw/tempd/;
use Path::Tiny;

use Test::DZil;

my $corpus = path('corpus/DZ1')->absolute;

my $wd = tempd;

my $tzil = Builder->from_config( { dist_root => "$corpus" }, );

ok( $tzil->build, "build dist with \@Author::TABULO" );

done_testing;

#
# This file is part of Dist-Zilla-PluginBundle-Author-TABULO
#
# This software is copyright (c) 2022 by Tabulo[n].
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# CREDITS: [TAU]: Adopted from @DAGOLDEN/t/dagolden.t
