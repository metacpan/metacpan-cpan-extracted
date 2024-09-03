use strict;
use warnings;
use ExtUtils::MakeMaker;

# so `cpanm --installdeps .` can work:
(my $fsdi = eval { require File::ShareDir::Install; File::ShareDir::Install->import; 1 }) && do {
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share(dist => "share");
};
{
package
MY;
File::ShareDir::Install->import(qw(postamble)) if $fsdi;
}

my $repo = 'mohawk2/p5-Map-Metro-London';
my $class = 'Map::Metro::Plugin::Map::London';
my $author = 'Ed J <etj@cpan.org>';
(my $vfrom = $class) =~ s#::#/#g;
WriteMakefile(
  AUTHOR => $author,
  MIN_PERL_VERSION => '5.012000', # Pod::Elemental
  NAME => $class,
  VERSION_FROM => "lib/$vfrom.pm",
  ABSTRACT_FROM => "lib/$vfrom.pm",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '6.63_03',
    "File::ShareDir::Install" => "0.06",
  },
  PREREQ_PM => {
    "Map::Metro" => "0.2300",
    "Moose" => "2.1400",
    "namespace::autoclean" => "0.24",
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
  },
  LICENSE => 'perl',
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      dynamic_config => 0,
      bugtracker => { web => "https://github.com/$repo/issues" },
      license => 'http://dev.perl.org/licenses/',
      repository => {
        type => 'git',
        url => "https://github.com/$repo.git",
        web => "https://github.com/$repo",
      },
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod' => '1.45',
        },
      },
    },
  },
);
