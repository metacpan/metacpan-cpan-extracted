use Module::Build;
use File::Spec;

my $build = Module::Build->new
  (
   module_name => 'Lingua::CollinsParser',
   license => 'perl',
   extra_linker_flags => '-lcollins',
   extra_compiler_flags => '-I../COLLINS-PARSER/code -Wall',
   create_makefile_pl => 'passthrough',
   requires => { 'XML::Generator' => 0 },
   build_requires => {
		      'Module::Build' => '0.21',
		      'Test::More' => 0,
		     },
  );

my $cp_home = $build->prompt
  ("\nFor testing purposes, please enter a directory containing\n'grammar' and 'events' model files\n",
   $ENV{CP_MODELDIR} || "../COLLINS-PARSER/models/model1");

foreach my $file (qw(grammar.grm grammar.lexicon grammar.nts events)) {
  my $full_file = File::Spec->catfile($cp_home, $file);
  die "Can't find $full_file, aborting build\n" unless -e $full_file;
}

$build->notes(cp_home => $cp_home);

$build->create_build_script;
