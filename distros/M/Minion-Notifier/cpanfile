requires 'Mojolicious', '6.0';
requires 'Minion', '5.03'; # enqueue event

feature 'postgres' => sub {
  requires 'Mojo::Pg', '3.03'; # Mojo::Pg::PubSub::reset method
};

test_requires 'Mojo::SQLite';
test_requires 'Minion::Backend::SQLite';
test_requires 'Mercury', '0.003'; # message broker application for websocket test

