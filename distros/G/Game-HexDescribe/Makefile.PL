use 5.008004;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
  NAME             => 'Game::HexDescribe',
  VERSION_FROM     => 'lib/Game/HexDescribe.pm',
  ABSTRACT_FROM    => 'lib/Game/HexDescribe.pm',
  AUTHOR           => 'Alex Schroeder',
  LICENSE          => 'agpl_3',
  MIN_PERL_VERSION => '5.26.0', # Modern::Perl '2018'
  EXE_FILES        => [
    'script/hex-describe',
  ],
  PREREQ_PM => {
    'strict' => 0,
    'warnings' => 0,
    'Modern::Perl' => 1.20180701, # for '2018'
    'Mojolicious' => 0,
    'Array::Utils' => 0,
    'List::MoreUtils' => 0,
    'Text::Autoformat' => 0,
    'File::ShareDir' => 0,
    'Role::Tiny' => 0,
    'IO::Socket::SSL' => 0, # if text-mapper requires https
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
	url  => 'https://alexschroeder.ch/cgit/hex-describe',
	web  => 'https://alexschroeder.ch/cgit/hex-describe/about/',
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

# Assuming you want to run Text Mapper on port 3010 and Face Generator on port
# 3020, start Hex Describe on port 3000.
run:
	morbo --mode development --listen http://*:3000 script/hex-describe
EOT
  return join "\n", @ret;
}
