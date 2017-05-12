#!/usr/bin/perl
# $Id:$

use Module::Build;

my $build = Module::Build->new(
    module_name => 'Devel::RemoteTrace',
    license     => 'mit',
    requires    => {
        'Socket'       => 0,
    }
);
$build->create_build_script;
