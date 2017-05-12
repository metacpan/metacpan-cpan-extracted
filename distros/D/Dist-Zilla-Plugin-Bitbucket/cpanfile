requires "Carp" => "0";
requires "Config::Identity" => "0.0018";
requires "Dist::Zilla::Role::AfterMint" => "0";
requires "Dist::Zilla::Role::AfterRelease" => "0";
requires "Dist::Zilla::Role::MetaProvider" => "0";
requires "Dist::Zilla::Role::TextTemplate" => "0";
requires "File::Slurp::Tiny" => "0";
requires "File::pushd" => "1.009";
requires "Git::Wrapper" => "0.037";
requires "HTTP::Tiny" => "0.050";
requires "JSON::MaybeXS" => "1.002006";
requires "MIME::Base64" => "3.14";
requires "Moose" => "2.1400";
requires "Moose::Util::TypeConstraints" => "1.01";
requires "Try::Tiny" => "0.22";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "perl" => "5.006";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build::Tiny" => "0.039";
  requires "perl" => "5.006";
};
