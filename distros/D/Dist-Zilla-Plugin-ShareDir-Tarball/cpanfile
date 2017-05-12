requires "Archive::Tar" => "0";
requires "Compress::Zlib" => "0";
requires "Dist::Zilla::File::InMemory" => "0";
requires "Dist::Zilla::Role::FileGatherer" => "0";
requires "Dist::Zilla::Role::FileInjector" => "0";
requires "Dist::Zilla::Role::FileMunger" => "0";
requires "Dist::Zilla::Role::FilePruner" => "0";
requires "Dist::Zilla::Role::ShareDir" => "0";
requires "Moose" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Module::Build" => "0.3601";
  requires "Test::DZil" => "0";
  requires "Test::More" => "0.88";
  requires "perl" => "5.006";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "version" => "0.9901";
};
