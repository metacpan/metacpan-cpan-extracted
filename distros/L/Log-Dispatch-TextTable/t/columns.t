use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
  use_ok('Log::Dispatch');
  use_ok('Log::Dispatch::TextTable');
}

my $return;

{ 
  my $dispatcher = Log::Dispatch->new;
  isa_ok($dispatcher, 'Log::Dispatch');

  my $table_dispatch = Log::Dispatch::TextTable->new(
    name      => 'mood-o-meter',
    min_level => 'debug',
    send_to   => sub { $return = $_[0] },
    columns   => [ qw(message ambiance) ],
  );

  isa_ok($table_dispatch, 'Log::Dispatch::TextTable');
  isa_ok($table_dispatch, 'Log::Dispatch::Output');

  $dispatcher->add($table_dispatch);

  $dispatcher->log(
    level    => 'info',
    message  => "dinner",
    ambiance => "romantic",
  );

  $dispatcher->log(
    level    => 'error',
    message  => 'movie',
    ambiance => 'pornographic',
  );

  $dispatcher->log(
    level    => 'alert',
    message  => 'consequences',
    ambiance => 'hilarious',
  );
}

isa_ok($return, 'Text::Table', 'the result of logging');

my $table = "$return";

is(ref($table), '', 'stringified table is just a plain old scalar');

my @lines = split /\n/, $table;

is(@lines, 4, "there were four lines in the table");

like(
  $lines[0],
  qr/\Amessage\s+\|\s+ambiance\s*\z/,
  "first line is headers"
);

