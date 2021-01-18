requires "CPAN::Changes" => "0.20";
requires "Dist::Zilla::Role::AfterRelease" => "0";
requires "Dist::Zilla::Role::BeforeRelease" => "0";
requires "Dist::Zilla::Role::FileMunger" => "0";
requires "Dist::Zilla::Role::Plugin" => "0";
requires "Dist::Zilla::Role::TextTemplate" => "0";
requires "Dist::Zilla::Role::VersionProvider" => "0";
requires "List::AllUtils" => "0";
requires "List::Util" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Moose::Util::TypeConstraints" => "0";
requires "Perl::Version" => "0";
requires "perl" => "v5.10.0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::DZil" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
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
