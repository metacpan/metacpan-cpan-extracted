requires "Dist::Zilla::Role::AfterBuild" => "3.101461";
requires "Dist::Zilla::Role::InstallTool" => "3.101461";
requires "Dist::Zilla::Role::PrereqSource" => "3.101461";
requires "Moose" => "1.03";
requires "Moose::Util::TypeConstraints" => "1.01";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0.88";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "Module::Build::Tiny" => "0.039";
  requires "perl" => "5.006";
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
