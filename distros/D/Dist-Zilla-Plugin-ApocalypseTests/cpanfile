requires "Dist::Zilla::Plugin::InlineFiles" => "2.101170";
requires "Dist::Zilla::Role::FileMunger" => "2.101170";
requires "Moose" => "1.03";
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
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
