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
    name      => 'text_table_log',
    min_level => 'debug',
    send_to   => sub { $return = $_[0] }
  );

  isa_ok($table_dispatch, 'Log::Dispatch::TextTable');
  isa_ok($table_dispatch, 'Log::Dispatch::Output');

  $dispatcher->add($table_dispatch);

  $dispatcher->alert(message => "this is your face");
  $dispatcher->alert(message => "this is your face on drugs");
}

isa_ok($return, 'Text::Table', 'the result of logging');

my $table = "$return";

is(ref($table), '', 'stringified table is just a plain old scalar');

my @lines = split /\n/, $table;

is(@lines, 3, "there were three lines in the table");

like(
  $lines[0],
  qr/\Atime\s+\|\s+level\s+\|\s+message\s*\z/,
  "first line is headers"
);

