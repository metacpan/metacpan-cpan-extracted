use 5.014;

use lib 't/lib';

use Do;
use Test::Auto;
use Test::More;

=name

Doodle::Column::Helpers

=cut

=abstract

Doodle Column Helpers

=cut

=includes

method: binary
method: boolean
method: char
method: date
method: datetime
method: datetime_tz
method: decimal
method: default
method: default_current_date
method: default_current_time
method: default_current_datetime
method: double
method: enum
method: float
method: increments
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
method: not_null
method: null
method: primary
method: references
method: string
method: text
method: text_long
method: text_medium
method: time
method: time_tz
method: timestamp
method: timestamp_tz
method: uuid

=cut

=synopsis

  use Doodle::Column;

  use Doodle;
  use Doodle::Column;
  use Doodle::Table;

  my $ddl = Doodle->new;

  my $table = Doodle::Table->new(
    name => 'users',
    doodle => $ddl
  );

  my $self = Doodle::Column->new(
    name => 'id',
    table => $table,
    doodle => $ddl
  );

=cut

=description

Helpers for configuring Column classes.

=cut

=libraries

Doodle::Library

=cut

=method binary

Configures a binary column and returns itself.

=cut

=signature binary

binary(Any %args) : Column

=cut

=example-1 binary

  # given: synopsis

  my $binary = $self->binary;

=cut

=method boolean

Configures a boolean column and returns itself.

=cut

=signature boolean

boolean(Any %args) : Column

=cut

=example-1 boolean

  # given: synopsis

  my $boolean = $self->boolean;

=cut

=method char

Configures a char column and returns itself.

=cut

=signature char

char(Any %args) : Column

=cut

=example-1 char

  # given: synopsis

  my $char = $self->char;

=cut

=method date

Configures a date column and returns itself.

=cut

=signature date

date(Any %args) : Column

=cut

=example-1 date

  # given: synopsis

  my $date = $self->date;

=cut

=method datetime

Configures a datetime column and returns itself.

=cut

=signature datetime

datetime(Any %args) : Column

=cut

=example-1 datetime

  # given: synopsis

  my $datetime = $self->datetime;

=cut

=method datetime_tz

Configures a datetime column with timezone and returns itself.

=cut

=signature datetime_tz

datetime_tz(Any %args) : Column

=cut

=example-1 datetime_tz

  # given: synopsis

  my $datetime_tz = $self->datetime_tz;

=cut

=method decimal

Configures a decimal column and returns itself.

=cut

=signature decimal

decimal(Any %args) : Column

=cut

=example-1 decimal

  # given: synopsis

  my $decimal = $self->decimal;

=cut

=method default

Configures a default value and returns itself.

=cut

=signature default

default(Str @args) : Column

=cut

=example-1 default

  # given: synopsis

  my $default = $self->default(123);

  # produces, default 123

=example-2 default

  # given: synopsis

  my $default = $self->default(string => 123);

  # produces, default '123'

=example-3 default

  # given: synopsis

  my $default = $self->default(integer => 123);

  # produces, default 123

=example-4 default

  # given: synopsis

  my $default = $self->default(function => 'current_timestamp');

  # produces, default CURRENT_TIMESTAMP

=cut

=method default_current_date

Configures a C<CURRENT_DATE> default value and returns itself.

=cut

=signature default_current_date

default_current_date() : Column

=cut

=example-1 default_current_date

  # given: synopsis

  my $default = $self->default_current_date;

=cut

=method default_current_time

Configures a C<CURRENT_TIME> default value and returns itself.

=cut

=signature default_current_time

default_current_time() : Column

=cut

=example-1 default_current_time

  # given: synopsis

  my $default = $self->default_current_time;

=cut

=method default_current_datetime

Configures a C<CURRENT_TIMESTAMP> default value and returns itself.

=cut

=signature default_current_datetime

default_current_datetime() : Column

=cut

=example-1 default_current_datetime

  # given: synopsis

  my $default = $self->default_current_datetime;

=cut

=method double

Configures a double column and returns itself.

=cut

=signature double

double(Any %args) : Column

=cut

=example-1 double

  # given: synopsis

  my $double = $self->double;

=cut

=method enum

Configures an enum column and returns itself.

=cut

=signature enum

enum(Any %args) : Column

=cut

=example-1 enum

  # given: synopsis

  my $enum = $self->enum(options => [
    'red', 'blue', 'green'
  ]);

=cut

=method float

Configures a float column and returns itself.

=cut

=signature float

float(Any %args) : Column

=cut

=example-1 float

  # given: synopsis

  my $float = $self->float;

=cut

=method increments

Denotes that the column auto-increments and returns the Column object.

=cut

=signature increments

increments() : Column

=cut

=example-1 increments

  # given: synopsis

  my $increments = $self->increments;

=cut

=method increments_big

Configures an auto-incrementing big integer (8-byte) column and returns itself.

=cut

=signature increments_big

increments_big(Any %args) : Column

=cut

=example-1 increments_big

  # given: synopsis

  my $increments_big = $self->increments_big;

=cut

=method increments_medium

Configures an auto-incrementing medium integer (3-byte) column and returns itself.

=cut

=signature increments_medium

increments_medium(Any %args) : Column

=cut

=example-1 increments_medium

  # given: synopsis

  my $increments_medium = $self->increments_medium;

=cut

=method increments_small

Configures an auto-incrementing small integer (2-byte) column and returns itself.

=cut

=signature increments_small

increments_small(Any %args) : Column

=cut

=example-1 increments_small

  # given: synopsis

  my $increments_small = $self->increments_small;

=cut

=method integer

Configures an integer (4-byte) column and returns itself.

=cut

=signature integer

integer(Any %args) : Column

=cut

=example-1 integer

  # given: synopsis

  my $integer = $self->integer;

=cut

=method integer_big

Configures a big integer (8-byte) column and returns itself.

=cut

=signature integer_big

integer_big(Any %args) : Column

=cut

=example-1 integer_big

  # given: synopsis

  my $integer_big = $self->integer_big;

=cut

=method integer_big_unsigned

Configures an unsigned big integer (8-byte) column and returns itself.

=cut

=signature integer_big_unsigned

integer_big_unsigned(Any %args) : Column

=cut

=example-1 integer_big_unsigned

  # given: synopsis

  my $integer_big_unsigned = $self->integer_big_unsigned;

=cut

=method integer_medium

Configures a medium integer (3-byte) column and returns itself.

=cut

=signature integer_medium

integer_medium(Any %args) : Column

=cut

=example-1 integer_medium

  # given: synopsis

  my $integer_medium = $self->integer_medium;

=cut

=method integer_medium_unsigned

Configures an unsigned medium integer (3-byte) column and returns itself.

=cut

=signature integer_medium_unsigned

integer_medium_unsigned(Any %args) : Column

=cut

=example-1 integer_medium_unsigned

  # given: synopsis

  my $integer_medium_unsigned = $self->integer_medium_unsigned;

=cut

=method integer_small

Configures a small integer (2-byte) column and returns itself.

=cut

=signature integer_small

integer_small(Any %args) : Column

=cut

=example-1 integer_small

  # given: synopsis

  my $integer_small = $self->integer_small;

=cut

=method integer_small_unsigned

Configures an unsigned small integer (2-byte) column and returns itself.

=cut

=signature integer_small_unsigned

integer_small_unsigned(Any %args) : Column

=cut

=example-1 integer_small_unsigned

  # given: synopsis

  my $integer_small_unsigned = $self->integer_small_unsigned;

=cut

=method integer_tiny

Configures a tiny integer (1-byte) column and returns itself.

=cut

=signature integer_tiny

integer_tiny(Any %args) : Column

=cut

=example-1 integer_tiny

  # given: synopsis

  my $integer_tiny = $self->integer_tiny;

=cut

=method integer_tiny_unsigned

Configures an unsigned tiny integer (1-byte) column and returns itself.

=cut

=signature integer_tiny_unsigned

integer_tiny_unsigned(Any %args) : Column

=cut

=example-1 integer_tiny_unsigned

  # given: synopsis

  my $integer_tiny_unsigned = $self->integer_tiny_unsigned;

=cut

=method integer_unsigned

Configures an unsigned integer (4-byte) column and returns itself.

=cut

=signature integer_unsigned

integer_unsigned(Any %args) : Column

=cut

=example-1 integer_unsigned

  # given: synopsis

  my $integer_unsigned = $self->integer_unsigned;

=cut

=method json

Configures a JSON column and returns itself.

=cut

=signature json

json(Any %args) : Column

=cut

=example-1 json

  # given: synopsis

  my $json = $self->json;

=cut

=method not_null

Denotes that the Column is not nullable and returns itself.

=cut

=signature not_null

not_null(Any %args) : Column

=cut

=example-1 not_null

  # given: synopsis

  my $not_null = $self->not_null;

=cut

=method null

Denotes that the Column is nullable and returns itself.

=cut

=signature null

null(Any %args) : Column

=cut

=example-1 null

  # given: synopsis

  my $null = $self->null;

=cut

=method primary

Denotes that the column is the primary key and returns the Column object.

=cut

=signature primary

primary(Any %args) : Column

=cut

=example-1 primary

  # given: synopsis

  my $primary = $self->primary('id');

=cut

=method references

Configures a relation and returns the Relation object.

=cut

=signature references

references(Str $table, Str $column) : Relation

=cut

=example-1 references

  # given: synopsis

  my $references = $self->references('entities');

=cut

=example-2 references

  # given: synopsis

  my $references = $self->references('entities', 'uuid');

=cut

=method string

Configures a string column and returns itself.

=cut

=signature string

string(Any %args) : Column

=cut

=example-1 string

  # given: synopsis

  my $string = $self->string;

=cut

=method text

Configures a text column and returns itself.

=cut

=signature text

text(Any %args) : Column

=cut

=example-1 text

  # given: synopsis

  my $text = $self->text;

=cut

=method text_long

Configures a long text column and returns itself.

=cut

=signature text_long

text_long(Any %args) : Column

=cut

=example-1 text_long

  # given: synopsis

  my $text_long = $self->text_long;

=cut

=method text_medium

Configures a medium text column and returns itself.

=cut

=signature text_medium

text_medium(Any %args) : Column

=cut

=example-1 text_medium

  # given: synopsis

  my $text_medium = $self->text_medium;

=cut

=method time

Configures a time column and returns itself.

=cut

=signature time

time(Any %args) : Column

=cut

=example-1 time

  # given: synopsis

  my $time = $self->time;

=cut

=method time_tz

Configures a time column with timezone and returns itself.

=cut

=signature time_tz

time_tz(Any %args) : Column

=cut

=example-1 time_tz

  # given: synopsis

  my $time_tz = $self->time_tz;

=cut

=method timestamp

Configures a timestamp column and returns itself.

=cut

=signature timestamp

timestamp(Any %args) : Column

=cut

=example-1 timestamp

  # given: synopsis

  my $timestamp = $self->timestamp;

=cut

=method timestamp_tz

Configures a timestamp_tz column and returns itself.

=cut

=signature timestamp_tz

timestamp_tz(Any %args) : Column

=cut

=example-1 timestamp_tz

  # given: synopsis

  my $timestamp_tz = $self->timestamp_tz;

=cut

=method uuid

Configures a uuid column and returns itself.

=cut

=signature uuid

uuid(Any %args) : Column

=cut

=example-1 uuid

  # given: synopsis

  my $uuid = $self->uuid;

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

$subtests->example(-1, 'default', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is_deeply $result->data->{default}, ['deduce', 123], 'metadata ok';

  $result;
});

$subtests->example(-2, 'default', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is_deeply $result->data->{default}, ['string', 123], 'metadata ok';

  $result;
});

$subtests->example(-3, 'default', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is_deeply $result->data->{default}, ['integer', 123], 'metadata ok';

  $result;
});

$subtests->example(-4, 'default', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is_deeply $result->data->{default}, ['function', 'current_timestamp'], 'metadata ok';

  $result;
});

$subtests->example(-1, 'default_current_date', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'default_current_time', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'default_current_datetime', 'method', fun($tryable) {
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

$subtests->example(-1, 'increments', 'method', fun($tryable) {
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

$subtests->example(-1, 'not_null', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'null', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'primary', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

$subtests->example(-1, 'references', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  ok $result->isa('Doodle::Relation'), 'isa ok';
  is $result->table->name, 'users', 'relation table ok';
  is $result->column, 'id', 'relation column ok';
  is $result->foreign_table, 'entities', 'relation foreign_table ok';
  is $result->foreign_column, 'id', 'relation foreign_column ok';

  $result;
});

$subtests->example(-2, 'references', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';
  is $result->table->name, 'users', 'relation table ok';
  is $result->column, 'id', 'relation column ok';
  is $result->foreign_table, 'entities', 'relation foreign_table ok';
  is $result->foreign_column, 'uuid', 'relation foreign_column ok';

  $result;
});

$subtests->example(-1, 'string', 'method', fun($tryable) {
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

$subtests->example(-1, 'uuid', 'method', fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

subtest 't/0.05/can/Doodle_Column_Helpers_binary.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'package',
    method => 'binary'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_boolean.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'active',
    method => 'boolean'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_char.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'token',
    method => 'char'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_date.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'published',
    method => 'date'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_datetime.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'published_at',
    method => 'datetime'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_datetime_tz.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'published_at',
    method => 'datetime_tz'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_decimal.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'point',
    method => 'decimal'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_double.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'amount',
    method => 'double'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_enum.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'colors',
    arguments => [options => ['red', 'blue', 'green']],
    method => 'enum'
  );

  $test->execute(sub {
    my $c = shift;

    is_deeply $c->data->{options}, ['red', 'blue', 'green'];
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_float.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'amount',
    method => 'float'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_increments.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'id',
    method => 'increments'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_increments_big.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'id',
    method => 'increments_big'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer_big';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_increments_medium.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'id',
    method => 'increments_medium'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer_medium';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_increments_small.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'id',
    method => 'increments_small'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'integer_small';
    is $c->data->{increments}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'rank',
    method => 'integer'
  );

  $test->execute;

  use Doodle;
  use Doodle::Column::Helpers;

  can_ok "Doodle::Column::Helpers", "integer";

  my $d = Doodle->new;
  my $c = $d->table('users')->column('rank')->integer;

  isa_ok $c, 'Doodle::Column';

  is $c->type, 'integer';

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_big.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_big'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_big_unsigned.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_big_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_medium.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_medium'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_medium_unsigned.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_medium_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_small.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_small'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_small_unsigned.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_small_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_tiny.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_tiny'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_tiny_unsigned.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_tiny_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_integer_unsigned.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'number',
    method => 'integer_unsigned'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_json.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'metadata',
    method => 'json'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_not_null.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'not_null'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'string';
    is $c->data->{nullable}, 0;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_null.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'null'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'string';
    is $c->data->{nullable}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_primary.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'id',
    method => 'primary'
  );

  $test->execute(sub {
    my $c = shift;

    is $c->type, 'string';
    is $c->data->{primary}, 1;
  });

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_string.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'fname',
    method => 'string'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_text.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'biography',
    method => 'text'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_text_long.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'background',
    method => 'text_long'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_text_medium.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'background',
    method => 'text_medium'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_time.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'clock_in',
    method => 'time'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_time_tz.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'clock_in',
    method => 'time_tz'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_timestamp.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'timestamp'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_timestamp_tz.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'verified',
    method => 'timestamp_tz'
  );

  $test->execute;

  ok 1 and done_testing;
};

subtest 't/0.05/can/Doodle_Column_Helpers_uuid.t', fun() {
  use Test_Doodle_Column_Helpers;

  my $test = Test_Doodle_Column_Helpers->new(
    table => 'users',
    column => 'reference',
    method => 'uuid'
  );

  $test->execute;

  ok 1 and done_testing;
};

ok 1 and done_testing;
