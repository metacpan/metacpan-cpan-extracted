
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "root";


my %WriteMakefileArgs = (
  "ABSTRACT" => "KING OF CMS",
  "AUTHOR" => "Devin Austin <dhoss\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::DBIx::Class" => "0.28",
    "Test::More" => "0.88",
    "Test::WWW::Mechanize::PSGI" => "0.35"
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Grimlock",
  "EXE_FILES" => [
    "script/dbic-diff",
    "script/grimlock_deploy_schema.pl",
    "script/grimlock_web.psgi",
    "script/grimlock_web_create.pl",
    "script/grimlock_web_server.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Grimlock",
  "PREREQ_PM" => {
    "Bread::Board" => 0,
    "Catalyst::Action::RenderView" => 0,
    "Catalyst::Authentication::Store::DBIx::Class" => 0,
    "Catalyst::Controller::REST" => "0.96",
    "Catalyst::Model::DBIC::Schema" => "0.59",
    "Catalyst::Plugin::Authentication" => 0,
    "Catalyst::Plugin::Authorization::Roles" => 0,
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::I18N" => 0,
    "Catalyst::Plugin::MessageStack" => 0,
    "Catalyst::Plugin::Session" => 0,
    "Catalyst::Plugin::Session::State::Cookie" => 0,
    "Catalyst::Plugin::Session::Store::DBIC" => 0,
    "Catalyst::Plugin::Static::Simple" => 0,
    "Catalyst::Runtime" => "5.90007",
    "Catalyst::View::JSON" => 0,
    "Catalyst::View::TT" => 0,
    "Config::General" => 0,
    "Config::JFDI" => 0,
    "Crypt::Eksblowfish::Bcrypt" => "0.009",
    "DBICx::MaterializedPath" => "0.03",
    "DBIx::Class" => "0.08196",
    "DBIx::Class::Candy" => "0.002001",
    "DBIx::Class::EncodedColumn::Crypt::Eksblowfish::Bcrypt" => "0.00011",
    "DBIx::Class::Helper::Row::ToJSON" => 0,
    "Data::Manager" => 0,
    "DateTime::Format::Pg" => "0.16007",
    "Email::Sender::Simple" => 0,
    "File::ShareDir" => "1.03",
    "HTML::Scrubber" => 0,
    "Moose" => "2.0402",
    "SQL::Translator" => "0.11010",
    "Template::Plugin::Filter::String::Truncate" => "0.02",
    "Text::Password::Pronounceable" => 0,
    "feature" => 0,
    "namespace::autoclean" => 0
  },
  "VERSION" => "0.11",
  "test" => {
    "TESTS" => "t/*.t"
  }
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

package
MY;
use File::ShareDir::Install qw(postamble);


