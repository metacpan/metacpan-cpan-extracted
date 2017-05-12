requires "Carp" => "0";
requires "Scalar::Util" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Test::More" => "0.96";
};

on 'test' => sub {
  requires "Data::Dump" => "0";
  requires "Test::Deep" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
};
