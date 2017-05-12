requires "Carp" => "0";
requires "Exporter" => "0";
requires "Tie::Hash" => "0";
requires "base" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Clone" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Exception" => "0";
  requires "lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
  requires "File::ShareDir::Install" => "0.03";
};

on 'develop' => sub {
  requires "Dist::Milla" => "0";
  requires "Dist::Zilla::Plugin::MetaProvides" => "0";
  requires "Dist::Zilla::Plugin::MetaNoIndex" => "0";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};

on 'develop' => sub {
  recommends "HTML::TreeBuilder" => "0";
};
