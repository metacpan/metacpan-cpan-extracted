# $Id: Build.PL,v 1.5 2007/07/13 00:00:11 ask Exp $
# $Source: /opt/CVS/Getopt-LL/Build.PL,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.5 $
# $Date: 2007/07/13 00:00:11 $
use strict;
use warnings;

sub BEGIN {
    use File::Spec;
    use FindBin qw($Bin);
    my $inc = File::Spec->catdir($Bin, 'inc');
    unshift @INC, $inc;
}

use Module::Build::Getopt::LL;

# ##########################################################

# Configuration for this script is done in the config.ph file.
our $BUILD_CONFIGFILE = 'config.ph';

# ##########################################################



sub YES { 1 };
sub NO  { 0 };

my $builder = Module::Build::Getopt::LL->new(
    module_name          => 'Getopt::LL',
    license              => 'perl',
    dist_author          => 'Ask Solem <ASKSH@cpan.org>',
    all_from             => 'lib/Getopt/LL.pm',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    create_makefile_pl   => 'traditional',
    create_readme        => YES,
    recursive_test_files => YES,
    requires             => {
        'version'                               => 0,
        'Class::Dot'                            => 1.0,
    },
    recommends           => {
    },
    build_requires       => {
     'Test::Simple'          => 0.42,    # 
     'Test::Exception'       => 0.25,
     'IO::Capture::Stderr'   => 0,
    },
    add_to_cleanup       => [ qw(
        a.out
        test.pl
        test.c
        test.cpp
        test.m
        *.swp
        .gdb_history
        install.cache
        t/cache
        cache/
    ) ],
    meta_merge => {
        distribution_type   => 'Module',
    },
);

$builder->create_build_script( );

package Module::Build::ModuleInfo::_version;
use version qw(qv);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
