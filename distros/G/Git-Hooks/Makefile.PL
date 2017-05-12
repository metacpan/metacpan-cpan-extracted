use 5.010;
use strict;
use warnings;

# See http://wiki.cpantesters.org/wiki/CPANAuthorNotes

use 5.010;

if ($^O eq 'MSWin32') {
    warn "I do not support Windows yet. Sorry.\n";
    exit 0;
}

sub git {
    my ($args) = @_;
    my $output = `git $args`;
    if ($? == -1) {
        warn "Failed to execute 'git $args': $!\n";
        exit 0;
    } elsif ($? != 0) {
        warn "Command 'git $args' died with exit code=$?\n";
        exit 0;
    }
    return $output;
}

# Check if we have a proper git
chomp(my $git_version = git('version'));
if (my ($major, $minor, $patch) = ($git_version =~ /(\d+)\.(\d+)\.(\d+)/)) {
    if ($major < 1 || $major == 1 && ($minor < 7 || $minor == 7 && $patch < 2)) {
	warn "Don't support gits older than 1.7.2. Your version is $git_version.\n";
	exit 0;
    }
} else {
    warn "Couldn't parse git version: '$git_version'\n";
    exit 0;
}

use ExtUtils::MakeMaker ;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Framework for implementing Git (and Gerrit) hooks',
  'AUTHOR' => 'Gustavo L. de M. Chaves <gnustavo@cpan.org>',
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0'
  },
  'DISTNAME' => 'Git-Hooks',
  'LICENSE' => 'perl',
  'MIN_PERL_VERSION' => '5.010',
  'NAME' => 'Git::Hooks',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Cwd' => '0',
    'Email::Valid' => '0',
    'Encode' => '0',
    'Error' => '0',
    'Exporter' => '0',
    'File::pushd' => '0',
    'Git' => '0',
    'List::MoreUtils' => '0',
    'Path::Tiny' => '0',
    'Sub::Util' => '0',
    'Test::More' => '0',
    'Text::Glob' => '0',
    'URI::Escape' => '0',
    'URI::file' => '0',
    'parent' => '0',
    'strict' => '0',
    'utf8' => '0',
    'warnings' => '0'
  },
  'TEST_REQUIRES' => {
    'Config' => '0',
    'Data::Dumper' => '0',
    'Test::Requires::Git' => '0',
    'lib' => '0'
  },
  'VERSION' => '1.15.1',
  'test' => {
    'TESTS' => 't/*.t'
  },
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



