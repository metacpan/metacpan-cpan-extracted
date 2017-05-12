requires "CPAN::Changes" => "0.17";
requires "Dist::Zilla::Role::AfterRelease" => "0";
requires "Dist::Zilla::Role::FileMunger" => "0";
requires "Dist::Zilla::Role::Plugin" => "0";
requires "Git::Repository" => "0";
requires "List::Util" => "0";
requires "Module::Load" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util" => "0";
requires "MooseX::Role::Parameterized" => "0";
requires "Path::Tiny" => "0";
requires "Perl::Version" => "0";
requires "Try::Tiny" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::DZil" => "0";
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
