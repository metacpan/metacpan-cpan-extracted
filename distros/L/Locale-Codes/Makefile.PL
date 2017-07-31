######################################################################
# Makefile.PL for Locale::Codes
######################################################################

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker 6.30;

my %IsWin32 = map { $_ => 1 } qw( MSWin32 NetWare symbian );
my $IsWin32 = 1   if ($IsWin32{ $^O });
my $Pvers   = $];
my $ConvVers= $ExtUtils::MakeMaker::VERSION;

my %module_prereq = (
   'Carp'                     => '0',
   'utf8'                     => '0',
);

my %script_prereq = (
);

my %test_prereq = (
   'Storable'                 => '0',
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
   NAME             => "Locale::Codes",
   VERSION          => "3.53",
   ABSTRACT         => "a distribution of modules to handle locale codes",
   LICENSE          => "perl",
   ($EU_MM_V >= 6.48
    ? (MIN_PERL_VERSION => "5.006")
    : ()),
   AUTHOR           => "Sullivan Beck (sbeck\@cpan.org)",
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
             'Locale::Codes' => {
                file    => 'Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::Constants' => {
                file    => 'Constants.pm',
                version => '3.53',
             },
             'Locale::Codes::Country' => {
                file    => 'Country.pm',
                version => '3.53',
             },
             'Locale::Codes::Country_Codes' => {
                file    => 'Country_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::Country_Retired' => {
                file    => 'Country_Retired.pm',
                version => '3.53',
             },
             'Locale::Codes::Currency' => {
                file    => 'Currency.pm',
                version => '3.53',
             },
             'Locale::Codes::Currency_Codes' => {
                file    => 'Currency_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::Currency_Retired' => {
                file    => 'Currency_Retired.pm',
                version => '3.53',
             },
             'Locale::Codes::LangExt' => {
                file    => 'LangExt.pm',
                version => '3.53',
             },
             'Locale::Codes::LangExt_Codes' => {
                file    => 'LangExt_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::LangExt_Retired' => {
                file    => 'LangExt_Retired.pm',
                version => '3.53',
             },
             'Locale::Codes::LangFam' => {
                file    => 'LangFam.pm',
                version => '3.53',
             },
             'Locale::Codes::LangFam_Codes' => {
                file    => 'LangFam_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::LangFam_Retired' => {
                file    => 'LangFam_Retired.pm',
                version => '3.53',
             },
             'Locale::Codes::LangVar' => {
                file    => 'LangVar.pm',
                version => '3.53',
             },
             'Locale::Codes::LangVar_Codes' => {
                file    => 'LangVar_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::LangVar_Retired' => {
                file    => 'LangVar_Retired.pm',
                version => '3.53',
             },
             'Locale::Codes::Language' => {
                file    => 'Language.pm',
                version => '3.53',
             },
             'Locale::Codes::Language_Codes' => {
                file    => 'Language_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::Language_Retired' => {
                file    => 'Language_Retired.pm',
                version => '3.53',
             },
             'Locale::Codes::Script' => {
                file    => 'Script.pm',
                version => '3.53',
             },
             'Locale::Codes::Script_Codes' => {
                file    => 'Script_Codes.pm',
                version => '3.53',
             },
             'Locale::Codes::Script_Retired' => {
                file    => 'Script_Retired.pm',
                version => '3.53',
             },
             'Locale::Country' => {
                file    => 'Country.pm',
                version => '3.53',
             },
             'Locale::Currency' => {
                file    => 'Currency.pm',
                version => '3.53',
             },
             'Locale::Language' => {
                file    => 'Language.pm',
                version => '3.53',
             },
             'Locale::Script' => {
                file    => 'Script.pm',
                version => '3.53',
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
             repository => {
                type => 'git',
                web  => 'https://github.com/SBECK-github/Locale-Codes',
                url  => 'git://github.com/SBECK-github/Locale-Codes.git',
             },
          },
       }
      )
    : ()),



   INSTALLDIRS      => (($] >= 5.007003) ? 'perl' : 'site'),

);
