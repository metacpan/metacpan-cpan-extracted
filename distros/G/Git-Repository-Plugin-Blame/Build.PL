use 5.006;
use strict;
use warnings;

use Module::Build;


my $class = Module::Build->subclass(
	code =>
	q|
		# Override 'test' to support running extended tests in the xt/
		# directory.
		sub ACTION_test
		{
			my ( $self ) = @_;

			$self->recursive_test_files(1);

			$self->test_files( 't', 'xt' )
				if $ENV{'RELEASE_TESTING'};

			return $self->SUPER::ACTION_test();
		}

		# Force running extended tests when testing the distribution.
		sub ACTION_disttest
		{
			my ( $self ) = @_;

			local $ENV{ RELEASE_TESTING } = 1;

			return $self->SUPER::ACTION_disttest();
		}
	|,
);

my $builder = $class->new(
	module_name          => 'Git::Repository::Plugin::Blame',
	license              => 'Perl_5',
	dist_author          => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from    => 'lib/Git/Repository/Plugin/Blame.pm',
	build_requires       =>
	{
		'Data::Dumper'                 => 0,
		'Test::Deep'                   => 0,
		'Test::Exception'              => 0,
		'Test::FailWarnings'           => 0,
		'Test::Git'                    => 0,
		'Test::Requires::Git'          => 1.005,
		'Test::More'                   => 0,
		'Test::Type'                   => 0,
	},
	requires             =>
	{
		'Carp'                         => 0,
		'Class::Load'                  => 0.20,  # Required for load_class()'s return value.
		'Data::Validate::Type'         => 0,
		'Git::Repository'              => 1.20,
		'Git::Repository::Plugin::Log' => 0,
		'Perl6::Slurp'                 => 0,
		'perl'                         => 5.006,
	},
	add_to_cleanup       =>
	[
		'Git-Repository-Plugin-Blame-*',
	],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'           => 0,
	},
	meta_merge           =>
	{
		resources                 =>
		{
			repository  => 'https://github.com/guillaumeaubert/Git-Repository-Plugin-Blame',
			homepage    => 'https://metacpan.org/release/Git-Repository-Plugin-Blame',
			bugtracker  => 'https://github.com/guillaumeaubert/Git-Repository-Plugin-Blame/issues',
		},
	},
);

$builder->create_build_script();
