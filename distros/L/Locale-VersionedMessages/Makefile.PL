######################################################################
# Makefile.PL for Locale::VersionedMessages
######################################################################

use strict;
use warnings;
use 5.008;
use ExtUtils::MakeMaker 6.30;

my %IsWin32 = map { $_ => 1 } qw( MSWin32 NetWare symbian );
my $IsWin32 = 1   if ($IsWin32{ $^O });
my $Pvers   = $];
my $ConvVers= $ExtUtils::MakeMaker::VERSION;

my %module_prereq = (
   'File::Path'               => '0',
   'IO::File'                 => '0',
);

my %script_prereq = (
);

my %test_prereq = (
   'Test::Inter'              => '1.09',
   'Test::More'               => '0',
);

my %config_prereq = (
   'ExtUtils::MakeMaker'      => '6.30',
);

%module_prereq = (%module_prereq,%script_prereq);
my $EU_MM_V    = $ExtUtils::MakeMaker::VERSION;
$EU_MM_V       =~ s/_//g;
if ($EU_MM_V < 6.64) {
   %config_prereq = (%config_prereq,%test_prereq);
}

WriteMakefile(
   NAME             => "Locale::VersionedMessages",
   VERSION          => "0.96",
   ABSTRACT         => "handle all aspects of the localization process",
   LICENSE          => "perl",
   ($EU_MM_V >= 6.48
    ? (MIN_PERL_VERSION => "5.008")
    : ()),
   AUTHOR           => "Sullivan Beck (https://github.com/SBECK-github/)",
   "dist"           => {COMPRESS=>"gzip",SUFFIX=>"gz"},
   PL_FILES         => {},
   PREREQ_PM        => \%module_prereq,
   ($EU_MM_V >= 6.52
    ? (CONFIGURE_REQUIRES => \%config_prereq)
    : ()),
   ($EU_MM_V >= 6.64
    ? (TEST_REQUIRES   => \%test_prereq)
    : ()),
   ($EU_MM_V > 6.45
    ? (META_ADD => {
          provides     => {
             'Locale::VersionedMessages' => {
                file    => 'lib/Locale/VersionedMessages.pm',
                version => '0.96',
             },
             'Locale::VersionedMessages::Sets::Empty' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Empty.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Empty::en_US' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Empty/en_US.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test1' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test1.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test1::de_DE' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test1/de_DE.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test1::en_US' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test1/en_US.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test1::fr_FR' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test1/fr_FR.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test2' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test2.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test2::en_US' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test2/en_US.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::Test2::fr_FR' => {
                file    => 't/lib/Locale/VersionedMessages/Sets/Test2/fr_FR.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::lm_gui' => {
                file    => 'lib/Locale/VersionedMessages/Sets/lm_gui.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::lm_gui::en_US' => {
                file    => 'lib/Locale/VersionedMessages/Sets/lm_gui/en_US.pm',
                version => '0',
             },
             'Locale::VersionedMessages::Sets::lm_gui::fr_FR' => {
                file    => 'lib/Locale/VersionedMessages/Sets/lm_gui/fr_FR.pm',
                version => '0',
             },
             'Locale::VersionedMessages::lm' => {
                file    => 'lib/Locale/VersionedMessages/lm.pm',
                version => '0.96',
             },

          },
       }
      )
    : ()),

   ($EU_MM_V > 6.46
    ? (META_MERGE => {
          'meta-spec'  => {
             version   => 2,
          },
          resources    => {
             bugtracker => {
                web  => 'https://github.com/SBECK-github/Locale-VersionedMessages/issues',
             },
             homepage => 'https://github.com/SBECK-github/Locale-VersionedMessages',
             repository => {
                type => 'git',
                web  => 'https://github.com/SBECK-github/Locale-VersionedMessages',
                url  => 'git://github.com/SBECK-github/Locale-VersionedMessages.git',
             },
          },
       }
      )
    : ()),

   EXE_FILES        => [
                        'bin/lm_gui',

                       ],

   MAN1PODS => {
      'bin/lm_gui' => 'blib/man1/lm_gui.1',
   },


);
