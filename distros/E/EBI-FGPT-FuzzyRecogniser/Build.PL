use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name => 'EBI::FGPT::FuzzyRecogniser',
	license     => 'gpl',
	dist_author => q{Emma Hastings <ehastings@cpan.org>},
	dist_abstract =>
	  'A set of modules that compares a supplied term to an ontology and suggests the best match 
based on some similarity metric (n-grams).',
	configure_requires => { 'Module::Build' => 0.38 },
	build_requires     => {
						'Test::More' => 0,
						'File::Temp' => 0,
	},
	requires => {
				  'Moose'                            => '0.89',
				  'Log::Log4perl'                    => 0,
				  'List::Util'                       => 0,
				  'XML::Parser'                      => '2.34',
				  'OWL::Simple::Parser'              => '1.00',
				  'MeSH::Parser::ASCII'              => '0.02',
				  'GO::Parser'   => 0,
				  'Bio::Phenotype::OMIM::OMIMparser' => 0
	},
	recommends => {
		'IO::File'     => 0,
		'IO::Handle'   => 0,
		'Getopt::Long' => 0,
		'Benchmark'    => 0,

	},

	script_files        => ['scripts/similarity_match.pl'],
	add_to_cleanup     => ['FuzzyRecongiser-*'],
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();