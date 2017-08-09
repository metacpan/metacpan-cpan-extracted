requires "Carp" => "0";
requires "HTTP::Date" => "6";
requires "HTTP::Headers::Util" => "6";
requires "HTTP::Request" => "0";
requires "Time::Local" => "0";
requires "locale" => "0";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "vars" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "HTTP::Response" => "0";
  requires "Test" => "0";
  requires "Test::More" => "0";
  requires "URI" => "0";
  requires "warnings" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::Code::TidyAll" => "0.50";
  requires "Test::More" => "0.96";
  requires "warnings" => "0";
};
