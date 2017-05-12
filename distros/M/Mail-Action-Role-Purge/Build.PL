#
# $Id: Build.PL 155 2004-12-27 04:19:23Z james $
#

use Module::Build;

my $build = Module::Build->new(

	module_name        => 'Mail::Action::Role::Purge',

	dist_version_from  => 'lib/Mail/Action/Role/Purge.pm',

    script_files       => [ qw|
        bin/mail_tempaddress_purge.pl
        bin/mail_simplelist_purge.pl
    |],

	license            => 'perl',

	requires           => {
		'Mail::Action'      => '0.20',
        'Class::Roles'      => '0.30',
        'Mail::TempAddress' => '0.55',
        'Mail::SimpleList'  => '0.85',
	},

    build_requires     => {
        'Test::Role'        => 0.012_000,
    },

    create_readme      => 1,

    create_makefile_pl => 'traditional',

);

$build->create_build_script;

#
# EOF
