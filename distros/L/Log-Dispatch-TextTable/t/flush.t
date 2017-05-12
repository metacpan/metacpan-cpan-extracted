use strict;
use warnings;

use Test::More tests => 21;

BEGIN {
  use_ok('Log::Dispatch');
  use_ok('Log::Dispatch::TextTable');
}

my $return;

{ 
  my $dispatcher = Log::Dispatch->new;
  isa_ok($dispatcher, 'Log::Dispatch');

  my $table_dispatch = Log::Dispatch::TextTable->new(
    name      => 'tiny_bladder_log_TEEHEE',
    min_level => 'debug',
    send_to   => sub { $return = "$_[0]" },
    flush_if  => sub { $_[0]->entry_count >= 5 },
  );

  isa_ok($table_dispatch, 'Log::Dispatch::TextTable');
  isa_ok($table_dispatch, 'Log::Dispatch::Output');

  $dispatcher->add($table_dispatch);

  is($table_dispatch->table->body_height, 0, "no lines in body yet");

  for (1..4) {
    $dispatcher->alert("line $_");
    is($table_dispatch->table->body_height, $_, "$_ line(s) in body");
    is($return, undef, "nothing flushed yet");
  }

  $dispatcher->alert("line 5: the final chapter");

  is($table_dispatch->table->body_height, 0, "flushed! nothing in body now");
  like($return, qr/\Atime/, 'flushed into $return');
  like($return, qr/line 5/, 'and it contains the line we expected');

  $dispatcher->alert("line 6: a new beginning");
}

is(ref($return), '', 'stringified table is just a plain old scalar');

my @lines = split /\n/, $return;

is(@lines, 2, "there were two lines in the table");

like(
  $lines[0],
  qr/\Atime\s+\|\s+level\s+\|\s+message\s*\z/,
  "first line is headers"
);


like(
  $lines[1],
  qr/a new beginning/,
  "second line is the final line logged"
);
