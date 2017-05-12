requires "Carp" => "0";
requires "Class::Accessor::Chained::Fast" => "0";
requires "Devel::StackTrace" => "2.00";
requires "Exporter" => "0";
requires "File::Spec" => "0";
requires "FindBin" => "0";
requires "Getopt::Long" => "0";
requires "IO::Socket::INET" => "0";
requires "Module::Pluggable" => "0";
requires "PadWalker" => "0";
requires "Proc::Background" => "0";
requires "Scalar::Util" => "0";
requires "String::Koremutake" => "0";
requires "Term::ReadLine" => "0";
requires "YAML" => "0";
requires "base" => "0";
requires "lib" => "0";
requires "perl" => "5.008";
requires "strict" => "0";
requires "vars" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Test::More" => "0";
  requires "perl" => "5.008";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "perl" => "5.008";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};
