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
	module_name          => 'Email::ExactTarget',
	license              => 'GPL_3',
	dist_author          => q|Guillaume Aubert <aubertg@cpan.org>|,
	dist_version_from    => 'lib/Email/ExactTarget.pm',
	build_requires       =>
	{
		'Test::Deep'           => 0,
		'Test::Exception'      => 0,
		'Test::FailWarnings'   => 0,
		'Test::More'           => 0.94,
		'Test::Type'           => 0,
	},
	requires             =>
	{
		'perl'                 => 5.006,
		'Carp'                 => 0,
		'Data::Dumper'         => 0,
		'Data::Validate::Type' => 0,
		'HTML::Entities'       => 0,
		'HTTP::Request'        => 0,
		'LWP::UserAgent'       => 0,
		'SOAP::Lite'           => 0.71,
		'Text::Unaccent'       => 0,
		'Try::Tiny'            => 0,
		'URI::Escape'          => 0,
	},
	add_to_cleanup       => [ 'Email-ExactTarget-*' ],
	create_makefile_pl   => 'traditional',
	recursive_test_files => 1,
	configure_requires   =>
	{
		'Module::Build'  => 0,
	},
	meta_merge           =>
	{
		resources        =>
		{
			repository  => 'https://github.com/guillaumeaubert/Email-ExactTarget',
			homepage    => 'https://metacpan.org/release/Email-ExactTarget',
			bugtracker  => 'https://github.com/guillaumeaubert/Email-ExactTarget/issues',
		},
		no_index         =>
		{
			package     =>
			[
				'ExactTargetConfig',
			],
		},
	},
);

$builder->create_build_script();
