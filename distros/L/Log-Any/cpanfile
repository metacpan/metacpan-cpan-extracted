requires "B" => "0";
requires "Carp" => "0";
requires "Data::Dumper" => "0";
requires "Exporter" => "0";
requires "Fcntl" => "0";
requires "File::Basename" => "0";
requires "FindBin" => "0";
requires "IO::File" => "0";
requires "Storable" => "0";
requires "Sys::Syslog" => "0";
requires "Test::Builder" => "0";
requires "constant" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::More" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
