requires "Class::Method::Modifiers";
requires "Email::Stuffer";
requires "Mojolicious", "6.00";
requires "Test::More";
requires "IO::Async::Loop";
requires "Net::Async::HTTP";
requires "IO::Async::SSL";
requires "Future::Utils";

on 'test' => sub {
  requires "Dist::Zilla::App::Command::xtest";
  requires "Test::Builder::Tester";
  requires "Email::Sender::Transport::Test";
  requires "Test::Exception";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker";
};
