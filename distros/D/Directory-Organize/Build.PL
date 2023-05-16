# vim: set ts=4 sw=4 tw=78 et si:
use Module::Build;
my $build = new Module::Build(
    configure_requires => {
        'Module::Build' => 0.42
    },
    create_makefile_pl => 'traditional',
    dist_abstract      => 'Create and Organize Directories',
    dist_author        => 'Mathias Weidner <mathias@weidner.in-bad-schmiedeberg.de>',
    license => 'perl',
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/Directory-Organize',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Directory-Organize',
        }
    },
    module_name => 'Directory::Organize',
    requires => {
	'Getopt::Long'  => 0,
        'Term::ReadKey' => 0,
        'version' => 0,
    },
    script_files => [
        'bin/mkdir_heute',
    ],
);
$build->create_build_script;
