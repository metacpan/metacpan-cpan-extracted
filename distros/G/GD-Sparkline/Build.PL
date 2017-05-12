use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'GD::Sparkline',
				 dist_author         => 'Roger M Pettett <rpettett@cpan.org>',
				 dist_version_from   => 'lib/GD/Sparkline.pm',
				 dist_abstract       => 'GD::Sparkline - basic sparkline graphs',
				 license             => 'perl',
				 requires => {
					      'strict'          => '1.04',
					      'warnings'        => '1.06',
					      'GD'              => '2.41',
					      'base'            => '2.13',
					      'Class::Accessor' => '0.31',
					      'Readonly'        => '1.03',
					      'Math::Bezier'    => '0.01',
					      'Carp'            => '1.08',
					      'English'         => '1.04',
					     },
				 build_requires => {
						    'Test::More' => 0,
						    'IO::Scalar' => '2.110',
						   },
				 build_recommends => {
						      'Test::Pod::Coverage' => '1.00',
						      'Test::Pod'           => '1.00',
						      'Test::Distribution'  => 0,
						      'Test::Perl::Critic'  => 0,
						     },
				 create_makefile_pl  => 'passthrough',
				);

$builder->create_build_script();
