requires "Class::Method::Modifiers";
requires "Email::Stuffer";
requires "Mojolicious", "6.00";
requires "Mojo::UserAgent";
requires "Test::Most";

on 'test' => sub {
  requires "Test::Builder::Tester";
  requires "Test::More";
  requires "Email::Sender::Transport::Test";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker";
};
