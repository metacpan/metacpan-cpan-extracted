requires "Dist::Zilla::Role::FileFinderUser" => "4.102345";
requires "Dist::Zilla::Role::FileMunger" => "4.102345";
requires "Dist::Zilla::Role::MetaProvider" => "4.102345";
requires "Dist::Zilla::Role::PPI" => "4.300001";
requires "Dist::Zilla::Util" => "0";
requires "File::HomeDir" => "0";
requires "File::Spec" => "0";
requires "Moose" => "1.03";
requires "Moose::Util::TypeConstraints" => "1.01";
requires "PPI" => "1.206";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.28";
};

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0.88";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "Module::Build" => "0.28";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
