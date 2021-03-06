# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.010.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share\/dist\/MarpaX\-Languages\-C\-AST";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Translate a C source to an AST",
  "AUTHOR" => "Jean-Damien Durand <jeandamiendurand\@free.fr>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "MarpaX-Languages-C-AST",
  "EXE_FILES" => [
    "bin/c2ast",
    "bin/cdecl",
    "bin/cscan",
    "bin/csl"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "MarpaX::Languages::C::AST",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Class::Struct" => 0,
    "Data::Dumper" => 0,
    "Env" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Find" => 0,
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "Getopt::Long" => 0,
    "IO::CaptureOutput" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "IO::String" => 0,
    "IPC::Cmd" => 0,
    "IPC::Run" => 0,
    "Log::Any" => 0,
    "Log::Any::Adapter" => 0,
    "Log::Log4perl" => 0,
    "Marpa::R2" => "2.081001",
    "POSIX" => 0,
    "Pod::Usage" => 0,
    "Regexp::Common" => 0,
    "SUPER" => 0,
    "Scalar::Util" => 0,
    "Term::ProgressBar" => 0,
    "Try::Tiny" => 0,
    "Unicode::CaseFold" => 0,
    "XML::LibXML" => 0,
    "XML::LibXSLT" => 0,
    "constant" => 0,
    "diagnostics" => 0,
    "filetest" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Clone" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Test::Differences" => 0,
    "Test::More" => 0,
    "Test::Trap" => 0
  },
  "VERSION" => "0.48",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Class::Struct" => 0,
  "Clone" => 0,
  "Data::Dumper" => 0,
  "Env" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Basename" => 0,
  "File::Copy" => 0,
  "File::Find" => 0,
  "File::ShareDir" => 0,
  "File::Slurp" => 0,
  "File::Spec" => 0,
  "File::Temp" => 0,
  "Getopt::Long" => 0,
  "IO::CaptureOutput" => 0,
  "IO::File" => 0,
  "IO::Handle" => 0,
  "IO::String" => 0,
  "IPC::Cmd" => 0,
  "IPC::Open3" => 0,
  "IPC::Run" => 0,
  "Log::Any" => 0,
  "Log::Any::Adapter" => 0,
  "Log::Log4perl" => 0,
  "Marpa::R2" => "2.081001",
  "POSIX" => 0,
  "Pod::Usage" => 0,
  "Regexp::Common" => 0,
  "SUPER" => 0,
  "Scalar::Util" => 0,
  "Term::ProgressBar" => 0,
  "Test::Differences" => 0,
  "Test::More" => 0,
  "Test::Trap" => 0,
  "Try::Tiny" => 0,
  "Unicode::CaseFold" => 0,
  "XML::LibXML" => 0,
  "XML::LibXSLT" => 0,
  "constant" => 0,
  "diagnostics" => 0,
  "filetest" => 0,
  "parent" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

if ( $^O eq 'MSWin32' ) {
	$WriteMakefileArgs{PREREQ_PM}{'Win32::ShellQuote'} = '> 0';
}

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}
