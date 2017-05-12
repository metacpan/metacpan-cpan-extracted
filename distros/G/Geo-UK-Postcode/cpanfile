requires "Exporter" => "0";
requires "Geo::UK::Postcode::Regex" => "0.012";
requires "Moo" => "0";
requires "MooX::Aliases" => "0";
requires "base" => "0";
requires "overload" => "0";
requires "perl" => "5.010";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "List::Util" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Most" => "0";
  requires "lib" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Milla" => "0";
  requires "Dist::Zilla::Plugin::MetaProvides" => 0;
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
