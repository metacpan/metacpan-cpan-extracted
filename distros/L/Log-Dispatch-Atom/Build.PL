#!perl
# @(#) $Id: Build.PL 1032 2005-11-03 23:00:55Z dom $

use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name        => 'Log::Dispatch::Atom',
    license            => 'bsd',
    dist_author        => 'Dominic Mitchell <cpan (at) happygiraffe.net>',
    dist_version_from  => 'lib/Log/Dispatch/Atom.pm',
    add_to_cleanup     => ['Log-Dispatch-Atom-*'],
    create_makefile_pl => 'passthrough',
    requires           => {
        'Log::Dispatch::Output' => 0,
        'Test::More'            => 0,
        'XML::Atom'             => '0.15', # needed for insert mode.
    },
)->create_build_script();

# vim: set ai et sw=4 :
