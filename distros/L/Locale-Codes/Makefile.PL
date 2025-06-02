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
   VERSION          => "3.83",
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
                file    => 'blib/lib/Locale/Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::Constants' => {
                file    => 'blib/lib/Locale/Codes/Constants.pm',
                version => '3.83',
             },
             'Locale::Codes::Country' => {
                file    => 'blib/lib/Locale/Codes/Country.pm',
                version => '3.83',
             },
             'Locale::Codes::Country_Codes' => {
                file    => 'blib/lib/Locale/Codes/Country_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::Country_Retired' => {
                file    => 'blib/lib/Locale/Codes/Country_Retired.pm',
                version => '3.83',
             },
             'Locale::Codes::Currency' => {
                file    => 'blib/lib/Locale/Codes/Currency.pm',
                version => '3.83',
             },
             'Locale::Codes::Currency_Codes' => {
                file    => 'blib/lib/Locale/Codes/Currency_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::Currency_Retired' => {
                file    => 'blib/lib/Locale/Codes/Currency_Retired.pm',
                version => '3.83',
             },
             'Locale::Codes::LangExt' => {
                file    => 'blib/lib/Locale/Codes/LangExt.pm',
                version => '3.83',
             },
             'Locale::Codes::LangExt_Codes' => {
                file    => 'blib/lib/Locale/Codes/LangExt_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::LangExt_Retired' => {
                file    => 'blib/lib/Locale/Codes/LangExt_Retired.pm',
                version => '3.83',
             },
             'Locale::Codes::LangFam' => {
                file    => 'blib/lib/Locale/Codes/LangFam.pm',
                version => '3.83',
             },
             'Locale::Codes::LangFam_Codes' => {
                file    => 'blib/lib/Locale/Codes/LangFam_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::LangFam_Retired' => {
                file    => 'blib/lib/Locale/Codes/LangFam_Retired.pm',
                version => '3.83',
             },
             'Locale::Codes::LangVar' => {
                file    => 'blib/lib/Locale/Codes/LangVar.pm',
                version => '3.83',
             },
             'Locale::Codes::LangVar_Codes' => {
                file    => 'blib/lib/Locale/Codes/LangVar_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::LangVar_Retired' => {
                file    => 'blib/lib/Locale/Codes/LangVar_Retired.pm',
                version => '3.83',
             },
             'Locale::Codes::Language' => {
                file    => 'blib/lib/Locale/Codes/Language.pm',
                version => '3.83',
             },
             'Locale::Codes::Language_Codes' => {
                file    => 'blib/lib/Locale/Codes/Language_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::Language_Retired' => {
                file    => 'blib/lib/Locale/Codes/Language_Retired.pm',
                version => '3.83',
             },
             'Locale::Codes::Script' => {
                file    => 'blib/lib/Locale/Codes/Script.pm',
                version => '3.83',
             },
             'Locale::Codes::Script_Codes' => {
                file    => 'blib/lib/Locale/Codes/Script_Codes.pm',
                version => '3.83',
             },
             'Locale::Codes::Script_Retired' => {
                file    => 'blib/lib/Locale/Codes/Script_Retired.pm',
                version => '3.83',
             },
             'Locale::Country' => {
                file    => 'blib/lib/Locale/Country.pm',
                version => '3.83',
             },
             'Locale::Currency' => {
                file    => 'blib/lib/Locale/Currency.pm',
                version => '3.83',
             },
             'Locale::Language' => {
                file    => 'blib/lib/Locale/Language.pm',
                version => '3.83',
             },
             'Locale::Script' => {
                file    => 'blib/lib/Locale/Script.pm',
                version => '3.83',
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
                web  => 'https://github.com/SBECK-github/Locale-Codes/issues',
             },
             homepage => 'https://github.com/SBECK-github/Locale-Codes',
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
