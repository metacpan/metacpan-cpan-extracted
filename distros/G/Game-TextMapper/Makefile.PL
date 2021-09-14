use 5.008004;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
  NAME             => 'Game::TextMapper',
  VERSION_FROM     => 'lib/Game/TextMapper.pm',
  ABSTRACT_FROM    => 'lib/Game/TextMapper.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/text-mapper',
  ],
  PREREQ_PM => {
    'strict' => 0,
    'warnings' => 0,
    'Modern::Perl' => 1.20180701, # for '2018'
    'Mojolicious' => 0, # for Mojo::Template and Mojo::UserAgent
    'File::Slurper' => 0,
    'Role::Tiny' => 0,
    'List::MoreUtils' => 0,
    'File::ShareDir' => 0,
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
	url  => 'https://alexschroeder.ch/cgit/text-mapper',
	web  => 'https://alexschroeder.ch/cgit/text-mapper/about/',
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
check:
	find lib -name '*.pm' -exec perl -Ilib -c '{}' ';' -exec podchecker '{}' ';'

# Assuming you want to run Hex Describe on port 3000 and Face Generator on port
# 3020, start Text Mapper on port 3010. Morbo watche lib and script folders already
# and changes to share don't require a restart. Since we expect a config file in the
# current directory, watch it.
run:
	morbo --verbose --listen http://*:3010 script/text-mapper --watch text-mapper.conf
EOT
  return join "\n", @ret;
}
