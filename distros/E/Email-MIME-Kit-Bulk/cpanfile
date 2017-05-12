requires "Email::MIME" => "0";
requires "Email::MIME::Kit" => "3.000005";
requires "Email::MIME::Kit::ManifestReader::JSON" => "0";
requires "Email::MIME::Kit::Renderer::TT" => "0";
requires "Email::Sender::Simple" => "0";
requires "JSON" => "0";
requires "List::AllUtils" => "0";
requires "MCE::Map" => "0";
requires "Moose" => "0";
requires "MooseX::App::Simple" => "0";
requires "MooseX::Types::Email" => "0";
requires "MooseX::Types::Path::Tiny" => "0";
requires "PerlX::Maybe" => "0";
requires "Try::Tiny" => "0";
requires "namespace::autoclean" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Email::Sender::Transport::Maildir" => "0";
  requires "Exporter" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Path::Tiny" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "parent" => "0";
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
