requires "Carp" => "0";
requires "Exporter" => "0";
requires "JSON" => "0";
requires "List::Util" => "0";
requires "Moo" => "1.004003";
requires "Moo::Role" => "0";
requires "Type::Library" => "0";
requires "Type::Utils" => "0";
requires "Types::Standard" => "0";
requires "base" => "0";
requires "constant" => "0";
requires "perl" => "5.008";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Class::Load" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "Path::Class" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "lib" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Milla" => "1.0.14";
  requires "Dist::Zilla::Plugin::MetaProvides" => "0";
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
