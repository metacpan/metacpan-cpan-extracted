requires "perl" => "v5.6.0";
recommends "Graphics::ColorNames" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "Module::Metadata" => "0";
  requires "Test::More" => "0";
  requires "Test::Most" => "0";
  requires "Types::Common::Numeric" => "1.004";
  requires "Types::Standard" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::CleanNamespaces" => "0.15";
  requires "Test::EOF" => "0";
  requires "Test::EOL" => "0";
  requires "Test::MinimumVersion" => "0";
  requires "Test::More" => "0.88";
  requires "Test::NoTabs" => "0";
  requires "Test::Perl::Critic" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Portability::Files" => "0";
  requires "Test::TrailingSpace" => "0.0203";
};
