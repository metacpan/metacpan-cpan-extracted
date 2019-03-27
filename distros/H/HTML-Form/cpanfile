requires "Carp" => "0";
requires "Encode" => "2";
requires "HTML::TokeParser" => "0";
requires "HTTP::Request" => "6";
requires "HTTP::Request::Common" => "6.03";
requires "URI" => "1.10";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "vars" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "HTTP::Response" => "0";
  requires "Test" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "warnings" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::EOL" => "0";
  requires "Test::MinimumVersion" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.94";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Portability::Files" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Version" => "1";
  requires "perl" => "5.006";
  requires "warnings" => "0";
};

on 'develop' => sub {
  recommends "Dist::Zilla::PluginBundle::Git::VersionManager" => "0.007";
};
