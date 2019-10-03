use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Table::Helpers

=cut

=abstract

Doodle Table Helpers

=cut

=includes

method: binary
method: boolean
method: char
method: date
method: datetime
method: datetime_tz
method: decimal
method: double
method: enum
method: float
method: if_exists
method: if_not_exists
method: increments_big
method: increments_medium
method: increments_small
method: integer
method: integer_big
method: integer_big_unsigned
method: integer_medium
method: integer_medium_unsigned
method: integer_small
method: integer_small_unsigned
method: integer_tiny
method: integer_tiny_unsigned
method: integer_unsigned
method: json
method: morphs
method: no_morphs
method: no_timestamps
method: primary
method: string
method: temporary
method: text
method: text_long
method: text_medium
method: time
method: time_tz
method: timestamp
method: timestamp_tz
method: timestamps
method: timestamps_tz
method: uuid

=cut

=synopsis

  use Doodle;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $self = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

=cut

=description

Helpers for configuring Table classes.

=cut

=libraries

Doodle::Library

=cut

=method binary

Registers a binary column and returns the Command object set.

=cut

=signature binary

binary(Str $name, Any %args) : Column

=cut

=example-1 binary

  # given: synopsis

  my $binary = $self->binary('resume');

=cut

=method boolean

Registers a boolean column and returns the Command object set.

=cut

=signature boolean

boolean(Str $name, Any %args) : Column

=cut

=example-1 boolean

  # given: synopsis

  my $boolean = $self->boolean('verified');

=cut

=method char

Registers a char column and returns the Command object set.

=cut

=signature char

char(Str $name, Any %args) : Column

=cut

=example-1 char

  # given: synopsis

  my $char = $self->char('level', size => 2);

=cut

=method date

Registers a date column and returns the Command object set.

=cut

=signature date

date(Str $name, Any %args) : Column

=cut

=example-1 date

  # given: synopsis

  my $date = $self->date('start_date');

=cut

=method datetime

Registers a datetime column and returns the Command object set.

=cut

=signature datetime

datetime(Str $name, Any %args) : Column

=cut

=example-1 datetime

  # given: synopsis

  my $datetime = $self->datetime('published_at');

=cut

=method datetime_tz

Registers a datetime column with timezone and returns the Command object set.

=cut

=signature datetime_tz

datetime_tz(Str $name, Any %args) : Column

=cut

=example-1 datetime_tz

  # given: synopsis

  my $datetime_tz = $self->datetime_tz('published_at');

=cut

=method decimal

Registers a decimal column and returns the Command object set.

=cut

=signature decimal

decimal(Str $name, Any %args) : Column

=cut

=example-1 decimal

  # given: synopsis

  my $decimal = $self->decimal('point');

=cut

=method double

Registers a double column and returns the Command object set.

=cut

=signature double

double(Str $name, Any %args) : Column

=cut

=example-1 double

  # given: synopsis

  my $double = $self->double('amount');

=cut

=method enum

Registers an enum column and returns the Command object set.

=cut

=signature enum

enum(Str $name, Any %args) : Column

=cut

=example-1 enum

  # given: synopsis

  my $enum = $self->enum('colors', options => [
    'red', 'blue', 'green'
  ]);

=cut

=method float

Registers a float column and returns the Command object set.

=cut

=signature float

float(Str $name, Any %args) : Column

=cut

=example-1 float

  # given: synopsis

  my $float = $self->float('amount');

=cut

=method if_exists

Used with the C<delete> method to denote that the table should be deleted only
if it already exists.

=cut

=signature if_exists

if_exists() : Table

=cut

=example-1 if_exists

  # given: synopsis

  $self->if_exists;

=cut

=method if_not_exists

Used with the C<create> method to denote that the table should be created only
if it doesn't already exist.

=cut

=signature if_not_exists

if_not_exists() : Table

=cut

=example-1 if_not_exists

  # given: synopsis

  $self->if_not_exists;

=cut

=method increments_big

Registers an auto-incrementing big integer (8-byte) column and returns the Command object set.

=cut

=signature increments_big

increments_big(Str $name, Any %args) : Column

=cut

=example-1 increments_big

  # given: synopsis

  my $increments_big = $self->increments_big('number');

=cut

=method increments_medium

Registers an auto-incrementing medium integer (3-byte) column and returns the Command object set.

=cut

=signature increments_medium

increments_medium(Str $name, Any %args) : Column

=cut

=example-1 increments_medium

  # given: synopsis

  my $increments_medium = $self->increments_medium('number');

=cut

=method increments_small

Registers an auto-incrementing small integer (2-byte) column and returns the Command object set.

=cut

=signature increments_small

increments_small(Str $name, Any %args) : Column

=cut

=example-1 increments_small

  # given: synopsis

  my $increments_small = $self->increments_small('number');

=cut

=method integer

Registers an integer (4-byte) column and returns the Command object set.

=cut

=signature integer

integer(Str $name, Any %args) : Column

=cut

=example-1 integer

  # given: synopsis

  my $integer = $self->integer('number');

=cut

=method integer_big

Registers a big integer (8-byte) column and returns the Command object set.

=cut

=signature integer_big

integer_big(Str $name, Any %args) : Column

=cut

=example-1 integer_big

  # given: synopsis

  my $integer_big = $self->integer_big('number');

=cut

=method integer_big_unsigned

Registers an unsigned big integer (8-byte) column and returns the Command object set.

=cut

=signature integer_big_unsigned

integer_big_unsigned(Str $name, Any %args) : Column

=cut

=example-1 integer_big_unsigned

  # given: synopsis

  my $integer_big_unsigned = $self->integer_big_unsigned('number');

=cut

=method integer_medium

Registers a medium integer (3-byte) column and returns the Command object set.

=cut

=signature integer_medium

integer_medium(Str $name, Any %args) : Column

=cut

=example-1 integer_medium

  # given: synopsis

  my $integer_medium = $self->integer_medium('number');

=cut

=method integer_medium_unsigned

Registers an unsigned medium integer (3-byte) column and returns the Command object set.

=cut

=signature integer_medium_unsigned

integer_medium_unsigned(Str $name, Any %args) : Column

=cut

=example-1 integer_medium_unsigned

  # given: synopsis

  my $integer_medium_unsigned = $self->integer_medium_unsigned('number');

=cut

=method integer_small

Registers a small integer (2-byte) column and returns the Command object set.

=cut

=signature integer_small

integer_small(Str $name, Any %args) : Column

=cut

=example-1 integer_small

  # given: synopsis

  my $integer_small = $self->integer_small('number');

=cut

=method integer_small_unsigned

Registers an unsigned small integer (2-byte) column and returns the Command object set.

=cut

=signature integer_small_unsigned

integer_small_unsigned(Str $name, Any %args) : Column

=cut

=example-1 integer_small_unsigned

  # given: synopsis

  my $integer_small_unsigned = $self->integer_small_unsigned('number');

=cut

=method integer_tiny

Registers a tiny integer (1-byte) column and returns the Command object set.

=cut

=signature integer_tiny

integer_tiny(Str $name, Any %args) : Column

=cut

=example-1 integer_tiny

  # given: synopsis

  my $integer_tiny = $self->integer_tiny('number');

=cut

=method integer_tiny_unsigned

Registers an unsigned tiny integer (1-byte) column and returns the Command object set.

=cut

=signature integer_tiny_unsigned

integer_tiny_unsigned(Str $name, Any %args) : Column

=cut

=example-1 integer_tiny_unsigned

  # given: synopsis

  my $integer_tiny_unsigned = $self->integer_tiny_unsigned('number');

=cut

=method integer_unsigned

Registers an unsigned integer (4-byte) column and returns the Command object set.

=cut

=signature integer_unsigned

integer_unsigned(Str $name, Any %args) : Column

=cut

=example-1 integer_unsigned

  # given: synopsis

  my $integer_unsigned = $self->integer_unsigned('number');

=cut

=method json

Registers a JSON column and returns the Command object set.

=cut

=signature json

json(Str $name, Any %args) : Column

=cut

=example-1 json

  # given: synopsis

  my $json = $self->json('metadata');

=cut

=method morphs

Registers columns neccessary for polymorphism and returns the Column object set.

=cut

=signature morphs

morphs(Str $name) : ArrayRef[Column]

=cut

=example-1 morphs

  # given: synopsis

  my $morphs = $self->morphs('parent');

=cut

=method no_morphs

Registers a drop for C<{name}_fkey> and C<{name}_type> polymorphic columns and
returns the Command object set.

=cut

=signature no_morphs

no_morphs(Str $name) : ArrayRef[Command]

=cut

=example-1 no_morphs

  # given: synopsis

  my $no_morphs = $self->no_morphs('profile');

=cut

=method no_timestamps

Registers a drop for C<created_at>, C<updated_at> and C<deleted_at> columns and
returns the Command object set.

=cut

=signature no_timestamps

no_timestamps() : ArrayRef[Command]

=cut

=example-1 no_timestamps

  # given: synopsis

  my $no_timestamps = $self->no_timestamps;

=cut

=method primary

Registers primary key(s) and returns the Command object set.

=cut

=signature primary

primary(Str $name, Any %args) : Column

=cut

=example-1 primary

  # given: synopsis

  my $primary = $self->primary('id');

=cut

=method string

Registers a string column and returns the Command object set.

=cut

=signature string

string(Str $name, Any %args) : Column

=cut

=example-1 string

  # given: synopsis

  my $string = $self->string('fname');

=cut

=method temporary

Denotes that the table created should be a temporary one.

=cut

=signature temporary

temporary() : Table

=cut

=example-1 temporary

  # given: synopsis

  my $temporary = $self->temporary;

=cut

=method text

Registers a text column and returns the Command object set.

=cut

=signature text

text(Str $name, Any %args) : Column

=cut

=example-1 text

  # given: synopsis

  my $text = $self->text('biography');

=cut

=method text_long

Registers a long text column and returns the Command object set.

=cut

=signature text_long

text_long(Str $name, Any %args) : Column

=cut

=example-1 text_long

  # given: synopsis

  my $text_long = $self->text_long('biography');

=cut

=method text_medium

Registers a medium text column and returns the Command object set.

=cut

=signature text_medium

text_medium(Str $name, Any %args) : Column

=cut

=example-1 text_medium

  # given: synopsis

  my $text_medium = $self->text_medium('biography');

=cut

=method time

Registers a time column and returns the Command object set.

=cut

=signature time

time(Str $name, Any %args) : Column

=cut

=example-1 time

  # given: synopsis

  my $time = $self->time('clock_in');

=cut

=method time_tz

Registers a time column with timezone and returns the Command object set.

=cut

=signature time_tz

time_tz(Str $name, Any %args) : Column

=cut

=example-1 time_tz

  # given: synopsis

  my $time_tz = $self->time_tz('clock_in');

=cut

=method timestamp

Registers a timestamp column and returns the Command object set.

=cut

=signature timestamp

timestamp(Str $name, Any %args) : Column

=cut

=example-1 timestamp

  # given: synopsis

  my $timestamp = $self->timestamp('verified');

=cut

=method timestamp_tz

Registers a timestamp_tz column and returns the Command object set.

=cut

=signature timestamp_tz

timestamp_tz(Str $name, Any %args) : Column

=cut

=example-1 timestamp_tz

  # given: synopsis

  my $timestamp_tz = $self->timestamp_tz('verified');

=cut

=method timestamps

Registers C<created_at>, C<updated_at> and C<deleted_at> columns and returns
the Command object set.

=cut

=signature timestamps

timestamps() : ArrayRef[Column]

=cut

=example-1 timestamps

  # given: synopsis

  my $timestamps = $self->timestamps;

=cut

=method timestamps_tz

Registers C<created_at>, C<updated_at> and C<deleted_at> columns with timezone
and returns the Command object set.

=cut

=signature timestamps_tz

timestamps_tz() : ArrayRef[Column]

=cut

=example-1 timestamps_tz

  # given: synopsis

  my $timestamps_tz = $self->timestamps_tz;

=cut

=method uuid

Registers a uuid column and returns the Command object set.

=cut

=signature uuid

uuid(Str $name, Any %args) : Column

=cut

=example-1 uuid

  # given: synopsis

  my $uuid = $self->uuid('reference');

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subtests = $test->subtests->standard;

$subtests->example(-1, 'binary', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'boolean', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'char', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'date', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'datetime', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'datetime_tz', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'decimal', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'double', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'enum', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'float', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'if_exists', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'if_not_exists', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'increments_big', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'increments_medium', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'increments_small', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_big', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_big_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_medium', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_medium_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_small', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_small_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_tiny', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_tiny_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'integer_unsigned', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'json', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'morphs', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'no_morphs', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'no_timestamps', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'primary', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'string', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'temporary', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'text', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'text_long', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'text_medium', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'time', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'time_tz', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'timestamp', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'timestamp_tz', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'timestamps', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'timestamps_tz', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'uuid', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

subtest 't/0.05/can/Doodle_Table_Helpers_double.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'amount',
    method => 'double'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_no_morphs.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "no_morphs";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->no_morphs('profile');

  my $type = $x->[0];
  my $fkey = $x->[1];

  isa_ok $type, 'Doodle::Command';
  isa_ok $fkey, 'Doodle::Command';

  is $type->columns->first->name, 'profile_type';
  is $type->name, 'delete_column';

  is $fkey->columns->first->name, 'profile_fkey';
  is $fkey->name, 'delete_column';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_tiny.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_tiny'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_temporary.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "temporary";

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->temporary;

  is $t->data->{temporary}, 1;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_big.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_big'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_unsigned.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_small.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_small'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_string.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'fname',
    method => 'string'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_time.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'clock_in',
    method => 'time'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_datetime.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'published_at',
    method => 'datetime'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_increments_small.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'increments_small'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer_small';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_medium_unsigned.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_medium_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_primary.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Table_Helpers;

  my $test = Test_Doodle_Table_Helpers->new(
    table => 'users',
    column => 'id',
    method => 'primary'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_medium.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_medium'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_no_timestamps.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "no_timestamps";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->no_timestamps;

  my $created_at = $x->[0];
  my $updated_at = $x->[1];
  my $deleted_at = $x->[2];

  isa_ok $created_at, 'Doodle::Command';
  isa_ok $updated_at, 'Doodle::Command';
  isa_ok $deleted_at, 'Doodle::Command';

  is $created_at->columns->first->name, 'created_at';
  is $created_at->name, 'delete_column';

  is $updated_at->columns->first->name, 'updated_at';
  is $updated_at->name, 'delete_column';

  is $deleted_at->columns->first->name, 'deleted_at';
  is $deleted_at->name, 'delete_column';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_binary.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'resume',
    method => 'binary'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_enum.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'colors',
    method => 'enum',
    arguments => [options => ['red', 'blue', 'green']]
  );

  my $column = $test->execute;

  is_deeply $column->data->{options}, ['red', 'blue', 'green'];

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_float.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'amount',
    method => 'float'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_boolean.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'boolean'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_text.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'biography',
    method => 'text'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_time_tz.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'clock_in',
    method => 'time_tz'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_date.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'start_date',
    method => 'date'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_increments_big.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'increments_big'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer_big';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_increments_medium.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'increments_medium'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer_medium';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_decimal.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'point',
    method => 'decimal'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_timestamp.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'timestamp'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_text_long.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'biography',
    method => 'text_long'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_datetime_tz.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'published_at',
    method => 'datetime_tz'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_json.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'metadata',
    method => 'json'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_big_unsigned.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_big_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_uuid.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'reference',
    method => 'uuid'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_timestamps.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "timestamps";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->timestamps;

  my $created_at = $x->[0];
  my $updated_at = $x->[1];
  my $deleted_at = $x->[2];

  isa_ok $created_at, 'Doodle::Column';
  isa_ok $updated_at, 'Doodle::Column';
  isa_ok $deleted_at, 'Doodle::Column';

  is $created_at->type, 'datetime';
  is $created_at->data->{nullable}, 1;
  is $updated_at->type, 'datetime';
  is $updated_at->data->{nullable}, 1;
  is $deleted_at->type, 'datetime';
  is $deleted_at->data->{nullable}, 1;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_morphs.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "morphs";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->morphs('profile');

  my $profile_type = $x->[0];
  my $profile_fkey = $x->[1];

  is $profile_type->name, 'profile_type';
  is $profile_type->type, 'string';
  isa_ok $profile_type, 'Doodle::Column';

  is $profile_fkey->name, 'profile_fkey';
  is $profile_fkey->type, 'integer';
  isa_ok $profile_fkey, 'Doodle::Column';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_timestamps_tz.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "timestamps_tz";

  my $d = Doodle->new;
  my $t = $d->table('users');
  my $x = $t->timestamps_tz;

  my $created_at = $x->[0];
  my $updated_at = $x->[1];
  my $deleted_at = $x->[2];

  isa_ok $created_at, 'Doodle::Column';
  isa_ok $updated_at, 'Doodle::Column';
  isa_ok $deleted_at, 'Doodle::Column';

  is $created_at->type, 'datetime_tz';
  is $created_at->data->{nullable}, 1;
  is $updated_at->type, 'datetime_tz';
  is $updated_at->data->{nullable}, 1;
  is $deleted_at->type, 'datetime_tz';
  is $deleted_at->data->{nullable}, 1;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_small_unsigned.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_small_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_char.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'level',
    method => 'char'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_if_not_exists.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "if_not_exists";

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->if_not_exists;

  is $t->data->{if_not_exists}, 1;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_integer_tiny_unsigned.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_tiny_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_text_medium.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'biography',
    method => 'text_medium'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_if_exists.t', fun() {
  use Doodle;
  use Doodle::Table::Helpers;

  can_ok "Doodle::Table::Helpers", "if_exists";

  my $d = Doodle->new;
  my $t = $d->table('users');

  $t->if_exists;

  is $t->data->{if_exists}, 1;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Table_Helpers_timestamp_tz.t', fun() {
  use lib 't/lib';

  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'timestamp_tz'
  );

  $test->execute;

  ok 1 and done_testing;
};

ok 1 and done_testing;
