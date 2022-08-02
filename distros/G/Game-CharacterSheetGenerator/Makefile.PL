use 5.008004;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
  NAME             => 'Game::CharacterSheetGenerator',
  VERSION_FROM     => 'lib/Game/CharacterSheetGenerator.pm',
  ABSTRACT_FROM    => 'lib/Game/CharacterSheetGenerator.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/character-sheet-generator',
  ],
  PREREQ_PM => {
    'strict' => 0,
    'warnings' => 0,
    'Modern::Perl' => 1.20180701,
    'Mojolicious' => 0,
    'I18N::AcceptLanguage' => 0,
    'Encode::Locale' => 0,
    'File::ShareDir' => 0,
    'File::Slurper' => 0,
    'XML::LibXML' => 0,
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.52',
    'File::ShareDir::Install' => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
	type => 'git',
	url  => 'https://alexschroeder.ch/cgit/character-sheet-generator',
	web  => 'https://alexschroeder.ch/cgit/character-sheet-generator/about/',
      },
    },
  },
);

package MY;
use File::ShareDir::Install;

sub postamble {
  my $self = shift;
  my @ret = File::ShareDir::Install::postamble($self);
  push @ret, <<'EOT';
%.pdf: %.svg
	inkscape --file=$< --export-area-page --export-pdf=$@

check:
	find lib -name '*.pm' -exec perl -Ilib -c '{}' ';' -exec podchecker '{}' ';'

run:
	morbo --verbose --listen http://*:3040 script/character-sheet-generator --watch character-sheet-generator.conf --watch lib
EOT
  return join "\n", @ret;
}
