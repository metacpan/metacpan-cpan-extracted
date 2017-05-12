use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name    => 'Lingua::StanfordCoreNLP',
	dist_name      => 'Lingua-StanfordCoreNLP',
	dist_author    => 'Kalle Raisanen <kal@cpan.org>',
	dist_abstract  => 'A Perl interface to Stanford\'s CoreNLP tool set.',
	create_readme  => 1,
	requires       => {
		'perl'         => '5.10.0',
		'Inline::Java' => '0.53',
	},
	configure_requires => { 'Module::Build' => '0.38' },
	license => 'gpl'
);

$build->add_build_element('jar');
$build->add_to_cleanup(qw/_Inline *~ *.bak/);
$build->create_build_script;

$build->dispatch('clean');
$build->dispatch('distmeta');
$build->dispatch('manifest');
$build->dispatch('build');
