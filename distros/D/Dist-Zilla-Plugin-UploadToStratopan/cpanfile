requires "Dist::Zilla::Role::Releaser" => "0";
requires "LWP::Protocol::https" => "0";
requires "Mojo::DOM" => "0";
requires "Mojo::UserAgent" => "0";
requires "Moose" => "0";
requires "perl" => "5.006";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Exception" => "0";
  requires "Test::Mock::One" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5";
  requires "Dist::Zilla::Plugin::Prereqs" => "0";
  requires "Dist::Zilla::PluginBundle::Author::WATERKIP" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Software::License::Perl_5" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::CPAN::Meta::JSON" => "0.16";
  requires "Test::EOL" => "0";
  requires "Test::Kwalitee" => "1.21";
  requires "Test::MinimumVersion" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.96";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Portability::Files" => "0";
  requires "Test::Synopsis" => "0";
  requires "Test::Vars" => "0";
  requires "Test::Version" => "1";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
