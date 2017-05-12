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
	module_name         => 'IPC::Concurrency::DBI',
	license             => 'Perl_5',
	dist_author         => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from   => 'lib/IPC/Concurrency/DBI.pm',
	build_requires      =>
	{
		'DBD::SQLite'          => 0,
		'DBI'                  => 0,
		'Test::Exception'      => 0,
		'Test::FailWarnings'   => 0,
		'Test::More'           => 0,
	},
	requires            =>
	{
		'Carp'                 => 0,
		'Data::Dumper'         => 0,
		'Data::Validate::Type' => 0,
		'perl'                 => 5.006,
	},
	add_to_cleanup      =>
	[
		'IPC-Concurrency-DBI-*',
	],
	create_makefile_pl  => 'traditional',
	configure_requires  =>
	{
		'Module::Build' => 0,
	},
	meta_merge          =>
	{
		resources       =>
		{
			repository  => 'https://github.com/guillaumeaubert/IPC-Concurrency-DBI',
			homepage    => 'https://metacpan.org/release/IPC-Concurrency-DBI',
			bugtracker  => 'https://github.com/guillaumeaubert/IPC-Concurrency-DBI/issues',
		},
		no_index                =>
		{
			file        =>
			[
				't/LocalTest.pm',
			],
		},
	},
);

$builder->create_build_script();
