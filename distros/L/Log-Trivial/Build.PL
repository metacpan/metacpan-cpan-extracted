#    $Id: Build.PL 65 2014-05-23 12:45:59Z adam $;

use Module::Build;

if ($^O !~ /linux/i) {
    print <<"WARNING";

################################################
# The module has not been fully tested on old  #
# versions of Perl, it may or may not work.    #
# User beware!                                 #
#                                              #
# This module uses the POSIX open O_SYNC flag. #
# This flag is not supported on all systems.   #
################################################

WARNING
}

my $build = Module::Build->new(
    module_name => 'Log::Trivial',
    license     => 'lgpl3',
    requires    => {
		'perl'  => '5.010',
    },
    configure_requires => {
        'Module::Build'    => '0.4',
    },
    build-requires => {
        'Module::Build'       => '0.40',
        'Test'                => '0',
        'Test::Pod::Coverage' => '0',
        'Test::Pod'           => '0',
        'Test::More'          => '0',
        'Pod::Coverage'       => '0',
    },
);

$build->create_build_script;
