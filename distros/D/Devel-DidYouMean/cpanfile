requires "Perl::Builtins" => "0";
requires "Text::Levenshtein" => "0";
requires "perl" => "5.008";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Data::Dumper" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
