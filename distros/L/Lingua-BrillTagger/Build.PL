use strict;
use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Lingua::BrillTagger',
   license => 'perl',
   extra_linker_flags => '-lbrill',
   extra_compiler_flags => '-I../../external/BRILL-TAGGER/Utils -Wall',
   create_makefile_pl => 'passthrough',
   build_requires => {
		      'Module::Build' => '0.21',
		      'Test::More' => 0,
		     },
  );

my @files = qw(LEXICON BIGRAMS LEXICALRULEFILE CONTEXTUALRULEFILE);

my $bt_home = $build->prompt
  ("\nFor testing purposes, please enter a directory containing the files\n".
   join( ', ', map "'$_'", @files) . "\n",
   $ENV{BT_MODELDIR} ||
   "../../external/BRILL-TAGGER/Bin_and_Data");

foreach my $file (@files) {
  my $full_file = File::Spec->catfile($bt_home, $file);
  die "Can't find $full_file, aborting build\n" unless -e $full_file;
}

$build->notes(bt_home => $bt_home);

$build->create_build_script;
