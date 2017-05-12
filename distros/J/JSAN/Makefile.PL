use inc::Module::Install;

name           ( 'JSAN'                                    );
abstract       ( 'JavaScript Archive Network (JSAN) Shell' );
author         ( 'Casey West <casey@geeknest.com>'         );
version_from   ( 'lib/JSAN.pm'                             );
license        ( 'perl'                                    );
requires       ( 'perl'                         => '5.006' );
include        ( 'ExtUtils::AutoInstall'                   );
install_script ( 'bin/jsan'                                );

my @modules = (
	'Class::DBI::SQLite'          => '0.09',
	'DBD::SQLite'                 => '1.09',
	'Class::Accessor::Fast'       => '0.19',
	'Class::DBI'                  => '0.96',
	'Class::DBI::DATA::Schema'    => '0.04',
	'Class::DBI::Loader'          => '0.22',
	'Cwd'                         => '3.01',
	'File::Path'                  => '1.06',
	'File::Temp'                  => '0.14',
	'Getopt::Long'                => '2.34',
	'LWP::Simple'                 => '1.41',
	'SQL::Translator'             => '0.07',
	'Term::ReadLine'              => '1.01',
	'Test::More'                  => '0.6' ,
	'YAML'                        => '0.39',
	'Class::DBI::Loader::SQLite'  => '0.22',
	'Test::Differences'           => '0.47',
	'XML::XPath'                  => '1.13',
	'ExtUtils::AutoInstall'       => '0.61',
	);
while ( @modules ) {
	my $module  = shift @modules;
	my $version = shift @modules;
	requires( $module => $version );
	# I've left this, but it's only needed for testing classes I thought
	build_requires( $module => $version );
}

# Silly, this doesn't do what you think it does.
# auto_include_deps();

WriteAll();
