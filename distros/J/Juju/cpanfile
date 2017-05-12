requires "AnyEvent" => "0";
requires "AnyEvent::WebSocket::Client" => "0";
requires "Function::Parameters" => "0";
requires "HTTP::Tiny" => "0";
requires "JSON::PP" => "0";
requires "Moose" => "0";
requires "Moose::Role" => "0";
requires "Throwable::Error" => "0";
requires "YAML::Tiny" => "0";
requires "namespace::autoclean" => "0";

on 'test' => sub {
  requires "DDP" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "FindBin" => "0";
  requires "IO::Handle" => "0";
  requires "IO::Socket::SSL" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Elemental::Transformer::List" => "0";
  requires "Pod::Weaver::Plugin::Encoding" => "0";
  requires "Pod::Weaver::Section::SeeAlso" => "0";
  requires "Test::Compile" => "0";
  requires "Test::Exception" => "0";
  requires "Test::Kwalitee" => "0";
  requires "Test::More" => "0";
  requires "Test::NoTabs" => "0";
  requires "lib" => "0";
  requires "perl" => "5.006";
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
  requires "Test::Kwalitee" => "1.21";
};
