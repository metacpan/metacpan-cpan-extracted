#!/usr/bin/perl
################################################################################
# $Id: perl_header.clip 20 2009-06-17 14:16:09Z v89326 $
# $URL: file:///S:/svn/clipper/trunk/perl_header.clip $
################################################################################
#
# Title:   Build.PL
# Author:  Kurt Kincaid
# VERSION: 0.0.1
#
################################################################################

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'File::Butler',
    license           => 'perl',
    dist_author       => q{Kurt Kincaid <kurt.kincaid@gmail.com>},
    dist_version_from => 'lib/File/Butler.pm',
    build_requires    => {
        'Test::More' => 0,
        'Moose'      => 0,
        'feature'    => 0
    },
    add_to_cleanup     => [ 'File-Butler-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

################################################################################
# EOF
