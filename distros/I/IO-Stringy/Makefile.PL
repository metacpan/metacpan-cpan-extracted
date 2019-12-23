use strict;
use warnings;

use ExtUtils::MakeMaker;

# Carp first shipped with Perl 5
# Exporter first shipped with Perl 5
# File::Basename first shipped with Perl 5
# FileHandle first shipped with Perl 5
# IO::File first shipped with Perl 5.00307
# IO::Handle first shipped with Perl 5.00307
# Symbol first shipped with Perl 5.002
# Test::More first shipped with Perl 5.006002
# overload first shipped with Perl 5.002
# strict first shipped with Perl 5
# warnings first shipped with Perl 5.006
my %ConfigReqs = (
  "ExtUtils::MakeMaker" => 0,
);
my %DevReqs = (
  'Test::CPAN::Changes' => 0,
  'Test::Kwalitee' => 0,
  'Test::Pod' => 0,
  'Test::TrailingSpace' => 0,
);
my %TestReqs = (
  'File::Basename' => 0,
  'File::Spec' => 0,
  'File::Temp' => 0,
  'FileHandle' => 0,
  "IO::File" => 0,
  "IO::Handle" => 0,
  "Test::More" => 0,
  "strict" => 0,
  "warnings" => 0,
);
my %prereqs = (
  "Carp" => 0,
  "Exporter" => "5.57",
  'FileHandle' => 0,
  'IO::File' => 0,
  'IO::Handle' => 0,
  'Symbol' => 0,
  "overload" => 0,
  "strict" => 0,
  "warnings" => 0,
);

my %WriteMakefileArgs = (
  NAME         => 'IO::Stringy',
  DISTNAME     => 'IO-Stringy',
  VERSION_FROM => 'lib/IO/Stringy.pm',
  ABSTRACT     => 'I/O on in-core objects like strings and arrays',
  AUTHOR       => 'Erik Dorfman <eryq@cpan.org>',
  LICENSE      => 'perl_5',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['contrib', 'examples', 't',]},
    prereqs        => {runtime => {requires => {perl => '5.006002'}}},
    resources      => {
      repository => {
        type => 'git',
        url  => 'https://github.com/genio/IO-Stringy.git',
        # url => 'http://git.roaringpenguin.com/IO-Stringy.git/',
      },
      x_IRC => 'irc://irc.perl.org/#perl'
    },
    'x_contributors' => [
      'Chase Whitener <capoeirab@cpan.org>',
      'Dianne Skoll <dskoll@cpan.org>',
    ],
  },
  "CONFIGURE_REQUIRES" => \%ConfigReqs,
  "TEST_REQUIRES" => \%TestReqs,
  "PREREQ_PM" => \%prereqs,
  test => {TESTS => 't/*.t'},
);
unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
    my %fallback = (%prereqs, %TestReqs);
    delete $WriteMakefileArgs{TEST_REQUIRES};
    $WriteMakefileArgs{PREREQ_PM} = \%fallback;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52') };

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48') };

delete $WriteMakefileArgs{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.46') };

delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31') };

WriteMakefile(%WriteMakefileArgs);
