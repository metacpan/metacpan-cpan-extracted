use 5.008;
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
	module_name         => 'Lingua::TH::Numbers',
	license             => 'Perl_5',
	dist_author         => q{Guillaume Aubert <aubertg@cpan.org>},
	dist_version_from   => 'lib/Lingua/TH/Numbers.pm',
	build_requires      =>
	{
		'Test::More'            => 0.94, # For subtest().
		'Test::Exception'       => 0,
		'Test::FailWarnings'    => 0,
	},
	requires            =>
	{
		'perl'                  => 5.008,
		'Carp'                  => 0,
	},
	add_to_cleanup      =>
	[
		'Lingua-TH-Numbers-*',
	],
	create_makefile_pl  => 'traditional',
	configure_requires  =>
	{
		'Module::Build'         => 0,
	},
	meta_merge          =>
	{
		resources               =>
		{
			repository  => 'https://github.com/guillaumeaubert/Lingua-TH-Numbers',
			homepage    => 'https://metacpan.org/release/Lingua-TH-Numbers',
			bugtracker  => 'https://github.com/guillaumeaubert/Lingua-TH-Numbers/issues',
		},
	},
);

$builder->create_build_script();
