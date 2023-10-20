use 5.008004;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
  NAME             => 'Game::FaceGenerator',
  VERSION_FROM     => 'lib/Game/FaceGenerator.pm',
  ABSTRACT_FROM    => 'lib/Game/FaceGenerator.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/face-generator',
  ],
  PREREQ_PM => {
    'strict' => 0,
    'warnings' => 0,
    'Modern::Perl' => 1.20180701, # for '2018'
    'File::ShareDir' => 0,
    'File::Slurper' => 0,
    'Mojolicious' => 0,
    'Mojolicious::Plugin::Authentication' => 0,
    'GD' => 0,
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
	url  => 'https://alexschroeder.ch/cgit/face-generator',
	web  => 'https://alexschroeder.ch/cgit/face-generator/about/',
      },
    },
  },
  clean => {
    FILES => "test-[0-9][0-9][0-9][0-9]",
  },
);

package MY;
use File::ShareDir::Install;

sub postamble {
  my $self = shift;
  my @ret = File::ShareDir::Install::postamble($self);
  push @ret, <<'EOT';
check:
	find lib -name '*.pm' -exec perl -Ilib -c '{}' ';' -exec podchecker '{}' ';'

# Assuming you want to run Hex Describe on port 3000 and Text Mapper on port
# 3010, start Face Generator on port 3020.
run:
	morbo --watch=lib --watch=share --mode=development --listen="http://*:3020" script/face-generator
EOT
  return join "\n", @ret;
}
