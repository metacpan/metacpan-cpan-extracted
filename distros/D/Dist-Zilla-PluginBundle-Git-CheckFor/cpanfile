requires "Dist::Zilla::Plugin::Git::NextVersion" => "1.120370";
requires "Dist::Zilla::Role::BeforeRelease" => "0";
requires "Dist::Zilla::Role::Git::Repo" => "0";
requires "Dist::Zilla::Role::PluginBundle::Easy" => "0";
requires "Git::Wrapper" => "0";
requires "IPC::System::Simple" => "0";
requires "List::Util" => "1.33";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "MooseX::AttributeShortcuts" => "0";
requires "Try::Tiny" => "0";
requires "autodie" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Capture::Tiny" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::chdir" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Path::Tiny" => "0";
  requires "Test::CheckDeps" => "0.010";
  requires "Test::DZil" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::Moose::More" => "0.008";
  requires "Test::More" => "0.94";
  requires "Test::TempDir::Tiny" => "0";
  requires "blib" => "1.01";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "Devel::CheckBin" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoSmartComments" => "0";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
};
