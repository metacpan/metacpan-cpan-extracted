requires "Moose" => "0";
requires "MooseX::Method::Signatures" => "0";
requires "MooseX::Types" => "0";
requires "MooseX::Types::Moose" => "0";
requires "Text::Wrap::Smart::XS" => "0";
requires "constant" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build" => "0.28";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::EOL" => "0";
  requires "Test::More" => "0.88";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "strict" => "0";
  requires "warnings" => "0";
};
