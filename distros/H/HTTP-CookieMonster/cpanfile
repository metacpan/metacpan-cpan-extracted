requires "Carp" => "0";
requires "HTTP::Cookies" => "0";
requires "Moo" => "1.000003";
requires "Safe::Isa" => "0";
requires "Scalar::Util" => "0";
requires "Sub::Exporter" => "0";
requires "URI::Escape" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Data::Serializer" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod::Coverage" => "1.08";
};
