requires "Dist::Zilla::Role::FileFinderUser" => "0";
requires "Dist::Zilla::Role::FileMunger" => "0";
requires "Log::Any" => "0";
requires "Log::Any::Adapter" => "0";
requires "Moose" => "0";
requires "Moose::Util" => "0";
requires "Pod::Knit" => "0";
requires "experimental" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
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
};

on 'develop' => sub {
  requires "Test::More" => "0.96";
  requires "Test::Vars" => "0";
};
