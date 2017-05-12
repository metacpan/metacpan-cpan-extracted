#
# Module::Build build script for Mail::SPF::Test
#
# (C) 2006-2007 Julian Mehnle <julian@mehnle.net>
# $Id: Build.PL 105 2007-05-30 20:41:57Z Julian Mehnle $
#
##############################################################################

use Module::Build 0.2805;
use version;

my $build = Module::Build->new(
    module_name     => 'Mail::SPF::Test',
    dist_author     => 'Julian Mehnle <julian@mehnle.net>',
    license         => 'bsd',
    requires        => {
        # Core requirements:
        perl            => 'v5.6',
        version         => 0,
        NetAddr::IP     => '4',
        Net::DNS        => '0.58',
        YAML            => '0.50'
    },
    recommends      => {
    },
    build_requires  => {
        # Build requirements:
        Module::Build   => '0.2805',
        #Test::More      => 0
    },
    create_makefile_pl
                    => 'passthrough',
    sign            => 1
);

$build->create_build_script();
