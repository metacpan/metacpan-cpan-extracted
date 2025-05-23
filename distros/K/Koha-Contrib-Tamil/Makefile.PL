# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Various scripts to manage Koha instances",
  "AUTHOR" => "Fr\x{e9}d\x{e9}ric Demians <f.demians\@tamil.fr>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "Koha-Contrib-Tamil",
  "EXE_FILES" => [
    "bin/koha-auth",
    "bin/koha-authoritize",
    "bin/koha-claim",
    "bin/koha-cloud",
    "bin/koha-coce-url",
    "bin/koha-dump-biblio",
    "bin/koha-index",
    "bin/koha-index-daemon",
    "bin/koha-overdue",
    "bin/koha-rebuild-editors",
    "bin/koha-unimarc-4xx"
  ],
  "LICENSE" => "gpl",
  "MIN_PERL_VERSION" => "5.010",
  "NAME" => "Koha::Contrib::Tamil",
  "PREREQ_PM" => {
    "AnyEvent" => 0,
    "AnyEvent::Processor" => 0,
    "AnyEvent::Processor::Conversion" => 0,
    "Business::ISBN" => 0,
    "Carp" => 0,
    "DBI" => 0,
    "DateTime" => 0,
    "Fatal" => 0,
    "File::Path" => 0,
    "File::Temp" => 0,
    "FindBin" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "JSON" => 0,
    "LWP" => 0,
    "LWP::UserAgent" => 0,
    "List::Util" => 0,
    "Locale::TextDomain" => 0,
    "Log::Dispatch" => 0,
    "Log::Dispatch::File" => 0,
    "Log::Dispatch::Screen" => 0,
    "MARC::Batch" => 0,
    "MARC::File::XML" => 0,
    "MARC::Moose::Formater::Iso2709" => 0,
    "MARC::Moose::Formater::Marcxml" => 0,
    "MARC::Moose::Formater::Text" => 0,
    "MARC::Moose::Parser::Iso2709" => 0,
    "MARC::Moose::Reader::File::Iso2709" => 0,
    "MARC::Moose::Reader::File::Marcxml" => 0,
    "MARC::Moose::Record" => 0,
    "MARC::Moose::Writer" => 0,
    "MARC::Record" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Getopt" => 0,
    "MooseX::LogDispatch" => 0,
    "MooseX::RW::Reader" => 0,
    "MooseX::RW::Writer::File" => 0,
    "Path::Tiny" => 0,
    "Pod::Usage" => 0,
    "Search::Elasticsearch" => 0,
    "Text::Xslate" => 0,
    "Try::Tiny" => 0,
    "XML::Simple" => 0,
    "YAML" => 0,
    "YAML::Syck" => 0,
    "ZOOM" => 0,
    "diagnostics" => 0,
    "feature" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Find" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.074",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "AnyEvent" => 0,
  "AnyEvent::Processor" => 0,
  "AnyEvent::Processor::Conversion" => 0,
  "Business::ISBN" => 0,
  "Carp" => 0,
  "DBI" => 0,
  "DateTime" => 0,
  "Fatal" => 0,
  "File::Find" => 0,
  "File::Path" => 0,
  "File::Temp" => 0,
  "FindBin" => 0,
  "Getopt::Long" => 0,
  "IO::File" => 0,
  "JSON" => 0,
  "LWP" => 0,
  "LWP::UserAgent" => 0,
  "List::Util" => 0,
  "Locale::TextDomain" => 0,
  "Log::Dispatch" => 0,
  "Log::Dispatch::File" => 0,
  "Log::Dispatch::Screen" => 0,
  "MARC::Batch" => 0,
  "MARC::File::XML" => 0,
  "MARC::Moose::Formater::Iso2709" => 0,
  "MARC::Moose::Formater::Marcxml" => 0,
  "MARC::Moose::Formater::Text" => 0,
  "MARC::Moose::Parser::Iso2709" => 0,
  "MARC::Moose::Reader::File::Iso2709" => 0,
  "MARC::Moose::Reader::File::Marcxml" => 0,
  "MARC::Moose::Record" => 0,
  "MARC::Moose::Writer" => 0,
  "MARC::Record" => 0,
  "Modern::Perl" => 0,
  "Moose" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "MooseX::Getopt" => 0,
  "MooseX::LogDispatch" => 0,
  "MooseX::RW::Reader" => 0,
  "MooseX::RW::Writer::File" => 0,
  "Path::Tiny" => 0,
  "Pod::Usage" => 0,
  "Search::Elasticsearch" => 0,
  "Test::More" => 0,
  "Text::Xslate" => 0,
  "Try::Tiny" => 0,
  "XML::Simple" => 0,
  "YAML" => 0,
  "YAML::Syck" => 0,
  "ZOOM" => 0,
  "diagnostics" => 0,
  "feature" => 0,
  "strict" => 0,
  "utf8" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}
