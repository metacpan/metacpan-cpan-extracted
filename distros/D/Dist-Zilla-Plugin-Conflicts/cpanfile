requires "Dist::CheckConflicts" => "0.02";
requires "Dist::Zilla" => "4.0";
requires "Dist::Zilla::File::FromCode" => "0";
requires "Dist::Zilla::File::InMemory" => "0";
requires "Dist::Zilla::Role::FileGatherer" => "0";
requires "Dist::Zilla::Role::InstallTool" => "0";
requires "Dist::Zilla::Role::MetaProvider" => "0";
requires "Dist::Zilla::Role::PrereqSource" => "0";
requires "Dist::Zilla::Role::TextTemplate" => "0";
requires "Moose" => "0";
requires "namespace::autoclean" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::pushd" => "0";
  requires "Path::Tiny" => "0";
  requires "Test::DZil" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Differences" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Requires" => "0";
  requires "if" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Code::TidyAll::Plugin::Test::Vars" => "0.02";
  requires "Dist::Zilla::Plugin::SurgicalPodWeaver" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Perl::Critic" => "1.126";
  requires "Perl::Tidy" => "20160302";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta::JSON" => "0.16";
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.96";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Pod::No404s" => "0";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Vars" => "0.009";
  requires "Test::Version" => "1";
  requires "Test::Warnings" => "0";
  requires "blib" => "1.01";
  requires "perl" => "5.006";
};
