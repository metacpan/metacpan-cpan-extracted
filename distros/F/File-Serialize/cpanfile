requires "Class::Load" => "0";
requires "Exporter::Tiny" => "0";
requires "List::AllUtils" => "0";
requires "List::MoreUtils" => "0";
requires "List::Util" => "1.41";
requires "Module::Info" => "0";
requires "Module::Pluggable" => "0";
requires "Module::Runtime" => "0";
requires "Moo" => "0";
requires "Path::Tiny" => "0";
requires "Role::Tiny" => "0";
requires "feature" => "0";
requires "parent" => "0";
requires "perl" => "v5.16.0";
requires "strict" => "0";
requires "warnings" => "0";
recommends "JSON5" => "0";
recommends "JSON::MaybeXS" => "0";
recommends "YAML::Tiny" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
  requires "Test::Requires" => "0";
  requires "Test::Warnings" => "0";
  requires "utf8" => "0";
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
