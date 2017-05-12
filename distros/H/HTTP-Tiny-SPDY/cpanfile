requires "HTTP::Tiny" => "0";
requires "HTTP::Tiny::Handle" => "0";
requires "IO::Socket" => "0";
requires "IO::Socket::SSL" => "1.56";
requires "Net::SPDY::Session" => "0";
requires "Net::SSLeay" => "1.49";
requires "parent" => "0";
requires "perl" => "5.006";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Data::Dumper" => "0";
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Basename" => "0";
  requires "File::Spec" => "0";
  requires "File::Spec::Functions" => "0";
  requires "File::Temp" => "0";
  requires "IO::Dir" => "0";
  requires "IO::File" => "0";
  requires "IO::Handle" => "0";
  requires "IO::Socket::INET" => "0";
  requires "IO::Socket::SSL" => "1.56";
  requires "IPC::Cmd" => "0";
  requires "IPC::Open3" => "0";
  requires "List::Util" => "0";
  requires "Mozilla::CA" => "0";
  requires "Test::More" => "0.96";
  requires "open" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
