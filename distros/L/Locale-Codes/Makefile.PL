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
   'if'                       => '0',
   'utf8'                     => '0',
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
   NAME             => "Locale::Codes",
   VERSION          => "3.70",
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
                file    => 'lib/Locale/Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::Constants' => {
                file    => 'lib/Locale/Codes/Constants.pm',
                version => '3.70',
             },
             'Locale::Codes::Country' => {
                file    => 'lib/Locale/Codes/Country.pm',
                version => '3.70',
             },
             'Locale::Codes::Country_Codes' => {
                file    => 'lib/Locale/Codes/Country_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::Country_Retired' => {
                file    => 'lib/Locale/Codes/Country_Retired.pm',
                version => '3.70',
             },
             'Locale::Codes::Currency' => {
                file    => 'lib/Locale/Codes/Currency.pm',
                version => '3.70',
             },
             'Locale::Codes::Currency_Codes' => {
                file    => 'lib/Locale/Codes/Currency_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::Currency_Retired' => {
                file    => 'lib/Locale/Codes/Currency_Retired.pm',
                version => '3.70',
             },
             'Locale::Codes::LangExt' => {
                file    => 'lib/Locale/Codes/LangExt.pm',
                version => '3.70',
             },
             'Locale::Codes::LangExt_Codes' => {
                file    => 'lib/Locale/Codes/LangExt_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::LangExt_Retired' => {
                file    => 'lib/Locale/Codes/LangExt_Retired.pm',
                version => '3.70',
             },
             'Locale::Codes::LangFam' => {
                file    => 'lib/Locale/Codes/LangFam.pm',
                version => '3.70',
             },
             'Locale::Codes::LangFam_Codes' => {
                file    => 'lib/Locale/Codes/LangFam_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::LangFam_Retired' => {
                file    => 'lib/Locale/Codes/LangFam_Retired.pm',
                version => '3.70',
             },
             'Locale::Codes::LangVar' => {
                file    => 'lib/Locale/Codes/LangVar.pm',
                version => '3.70',
             },
             'Locale::Codes::LangVar_Codes' => {
                file    => 'lib/Locale/Codes/LangVar_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::LangVar_Retired' => {
                file    => 'lib/Locale/Codes/LangVar_Retired.pm',
                version => '3.70',
             },
             'Locale::Codes::Language' => {
                file    => 'lib/Locale/Codes/Language.pm',
                version => '3.70',
             },
             'Locale::Codes::Language_Codes' => {
                file    => 'lib/Locale/Codes/Language_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::Language_Retired' => {
                file    => 'lib/Locale/Codes/Language_Retired.pm',
                version => '3.70',
             },
             'Locale::Codes::Script' => {
                file    => 'lib/Locale/Codes/Script.pm',
                version => '3.70',
             },
             'Locale::Codes::Script_Codes' => {
                file    => 'lib/Locale/Codes/Script_Codes.pm',
                version => '3.70',
             },
             'Locale::Codes::Script_Retired' => {
                file    => 'lib/Locale/Codes/Script_Retired.pm',
                version => '3.70',
             },
             'Locale::Country' => {
                file    => 'lib/Locale/Country.pm',
                version => '3.70',
             },
             'Locale::Currency' => {
                file    => 'lib/Locale/Currency.pm',
                version => '3.70',
             },
             'Locale::Language' => {
                file    => 'lib/Locale/Language.pm',
                version => '3.70',
             },
             'Locale::Script' => {
                file    => 'lib/Locale/Script.pm',
                version => '3.70',
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



   INSTALLDIRS      => (($] >= 5.007003 && $] < 5.012) ? 'perl' : 'site'),

);
