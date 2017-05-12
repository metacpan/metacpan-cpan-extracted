use ExtUtils::MakeMaker 6.46;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile(
	NAME         => 'Git::Github::Creator',
	ABSTRACT     => 'Create a Github repository for your Perl module',
	VERSION_FROM => 'lib/Git/Github/Creator.pm',
	LICENSE      => 'perl',
	AUTHOR       => 'brian d foy <bdfoy@cpan.org>',

	PREREQ_PM    => {
		'Config::IniFiles'     => '0',
		'File::Find::Closures' => '0',
		'Log::Log4perl'        => '0',
		'Test::More'           => '0',
		'Test::Output'         => '0',
		'YAML'                 => '0',
		'Net::GitHub'          => '0.48',
		},

	EXE_FILES    => [ 'github_creator' ],

	MAN1PODS     => {
		'github_creator' => '$(INST_MAN1DIR)/github_creator.$(MAN1EXT)',
		},

	META_MERGE => {
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/briandfoy/github_creator.git',
				web  => 'https://github.com/briandfoy/github_creator',
				}
			}
		},

	clean  => { FILES => q|github_creator-*| },
	);
