requires "Carp" => "0";
requires "Clone" => "0";
requires "Exporter::Tiny" => "0";
requires "List::MoreUtils" => "0";
requires "Moo" => "0";
requires "MooX::HandlesVia" => "0";
requires "experimental" => "0";
requires "perl" => "v5.22.0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
  requires "Test::Warn" => "0";
  requires "strict" => "0";
  requires "warnings" => "0";
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
