use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name          => 'Log::Log4perl::Layout::PatternLayout::Redact',
	license              => 'GPL_3',
	dist_author          =>
	[
		'Guillaume Aubert <aubertg@cpan.org>',
		'Kate Kirby <kate@cpan.org>',
	],
	dist_version_from    => 'lib/Log/Log4perl/Layout/PatternLayout/Redact.pm',
	build_requires       =>
	{
		'Data::Dumper'         => 0,
		'File::Spec'           => 0,
		'File::Temp'           => 0,
		'Perl6::Slurp'         => 0,
		'Test::Exception'      => 0,
		'Test::More'           => 0,
	},
	requires             =>
	{
		'Carp'                 => 0,
		'Carp::Parse::Redact'  => '1.001000',
		'Data::Validate::Type' => 0,
		'Log::Log4perl'        => 0,
		'Try::Tiny'            => 0,
		'perl'                 => 5.006,
	},
	add_to_cleanup       =>
	[
		'Log-Log4perl-Layout-PatternLayout-Redact-*',
	],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	meta_merge           =>
	{
		resources             =>
		{
			repository  => 'https://github.com/katekirby/Log-Log4perl-Layout-PatternLayout-Redact.git',
			homepage    => 'https://metacpan.org/release/Log-Log4perl-Layout-PatternLayout-Redact',
			bugtracker  => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=log-log4perl-layout-patternlayout-redact',
		},
	},
);

$builder->create_build_script();
