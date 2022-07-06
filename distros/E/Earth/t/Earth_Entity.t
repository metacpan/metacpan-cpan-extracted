package main;

use 5.018;

use strict;
use warnings;

use Test::More;
use Venus::Test;

my $test = test(__FILE__);

=name

Earth::Entity

=cut

$test->for('name');

=tagline

FP Library Functions

=cut

$test->for('tagline');

=abstract

FP Standard Library Functions for Perl 5

=cut

$test->for('abstract');

=includes

function: Args
function: Array
function: Boolean
function: Code
function: Data
function: Date
function: Error
function: Float
function: Hash
function: Json
function: Match
function: Name
function: Number
function: Opts
function: Path
function: Process
function: Regexp
function: Replace
function: Scalar
function: Search
function: Space
function: String
function: Template
function: Throw
function: Try
function: Type
function: Undef
function: Vars
function: Yaml

=cut

$test->for('includes');

=synopsis

  package main;

  use Earth;
  use Earth::Entity 'Space';

  Space;

  # "Venus::Space"

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Space';

  $result
});

=description

This package compliments the Earth functional-programming framework by
providing wrapper functions, via L<Earth/wrap>, which wrap L<Venus> classes,
providing a functional abstraction around the Venus object-oriented standard
library.

=cut

$test->for('description');

=function Args

The Args function dispatches function and method calls to L<Venus::Args>.

=signature Args

  Args(HashRef $data) (Str | Object)

=metadata Args

{
  since => '0.01',
}

=example-1 Args

  package main;

  use Earth;
  use Earth::Entity 'Args';

  my $string = Args();

  # "Venus::Args"

=cut

$test->for('example', 1, 'Args', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Args';

  $result
});

=example-2 Args

  package main;

  use Earth;
  use Earth::Entity 'Args';

  my $string = Args({});

  # bless( {...}, "Venus::Args" )

=cut

$test->for('example', 2, 'Args', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Args');

  $result
});

=function Array

The Array function dispatches function and method calls to L<Venus::Array>.

=signature Array

  Array(HashRef $data) (Str | Object)

=metadata Array

{
  since => '0.01',
}

=example-1 Array

  package main;

  use Earth;
  use Earth::Entity 'Array';

  my $string = Array();

  # "Venus::Array"

=cut

$test->for('example', 1, 'Array', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Array';

  $result
});

=example-2 Array

  package main;

  use Earth;
  use Earth::Entity 'Array';

  my $string = Array({});

  # bless( {...}, "Venus::Array" )

=cut

$test->for('example', 2, 'Array', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Array');

  $result
});

=function Boolean

The Boolean function dispatches function and method calls to L<Venus::Boolean>.

=signature Boolean

  Boolean(HashRef $data) (Str | Object)

=metadata Boolean

{
  since => '0.01',
}

=example-1 Boolean

  package main;

  use Earth;
  use Earth::Entity 'Boolean';

  my $string = Boolean();

  # "Venus::Boolean"

=cut

$test->for('example', 1, 'Boolean', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Boolean';

  $result
});

=example-2 Boolean

  package main;

  use Earth;
  use Earth::Entity 'Boolean';

  my $string = Boolean({});

  # bless( {...}, "Venus::Boolean" )

=cut

$test->for('example', 2, 'Boolean', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Boolean');

  $result
});

=function Code

The Code function dispatches function and method calls to L<Venus::Code>.

=signature Code

  Code(HashRef $data) (Str | Object)

=metadata Code

{
  since => '0.01',
}

=example-1 Code

  package main;

  use Earth;
  use Earth::Entity 'Code';

  my $string = Code();

  # "Venus::Code"

=cut

$test->for('example', 1, 'Code', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Code';

  $result
});

=example-2 Code

  package main;

  use Earth;
  use Earth::Entity 'Code';

  my $string = Code({});

  # bless( {...}, "Venus::Code" )

=cut

$test->for('example', 2, 'Code', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Code');

  $result
});

=function Data

The Data function dispatches function and method calls to L<Venus::Data>.

=signature Data

  Data(HashRef $data) (Str | Object)

=metadata Data

{
  since => '0.01',
}

=example-1 Data

  package main;

  use Earth;
  use Earth::Entity 'Data';

  my $string = Data();

  # "Venus::Data"

=cut

$test->for('example', 1, 'Data', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Data';

  $result
});

=example-2 Data

  package main;

  use Earth;
  use Earth::Entity 'Data';

  my $string = Data({});

  # bless( {...}, "Venus::Data" )

=cut

$test->for('example', 2, 'Data', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Data');

  $result
});

=function Date

The Date function dispatches function and method calls to L<Venus::Date>.

=signature Date

  Date(HashRef $data) (Str | Object)

=metadata Date

{
  since => '0.01',
}

=example-1 Date

  package main;

  use Earth;
  use Earth::Entity 'Date';

  my $string = Date();

  # "Venus::Date"

=cut

$test->for('example', 1, 'Date', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Date';

  $result
});

=example-2 Date

  package main;

  use Earth;
  use Earth::Entity 'Date';

  my $string = Date({});

  # bless( {...}, "Venus::Date" )

=cut

$test->for('example', 2, 'Date', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Date');

  $result
});

=function Error

The Error function dispatches function and method calls to L<Venus::Error>.

=signature Error

  Error(HashRef $data) (Str | Object)

=metadata Error

{
  since => '0.01',
}

=example-1 Error

  package main;

  use Earth;
  use Earth::Entity 'Error';

  my $string = Error();

  # "Venus::Error"

=cut

$test->for('example', 1, 'Error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Error';

  $result
});

=example-2 Error

  package main;

  use Earth;
  use Earth::Entity 'Error';

  my $string = Error({});

  # bless( {...}, "Venus::Error" )

=cut

$test->for('example', 2, 'Error', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Error');

  $result
});

=function Float

The Float function dispatches function and method calls to L<Venus::Float>.

=signature Float

  Float(HashRef $data) (Str | Object)

=metadata Float

{
  since => '0.01',
}

=example-1 Float

  package main;

  use Earth;
  use Earth::Entity 'Float';

  my $string = Float();

  # "Venus::Float"

=cut

$test->for('example', 1, 'Float', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Float';

  $result
});

=example-2 Float

  package main;

  use Earth;
  use Earth::Entity 'Float';

  my $string = Float({});

  # bless( {...}, "Venus::Float" )

=cut

$test->for('example', 2, 'Float', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Float');

  1+$result
});

=function Hash

The Hash function dispatches function and method calls to L<Venus::Hash>.

=signature Hash

  Hash(HashRef $data) (Str | Object)

=metadata Hash

{
  since => '0.01',
}

=example-1 Hash

  package main;

  use Earth;
  use Earth::Entity 'Hash';

  my $string = Hash();

  # "Venus::Hash"

=cut

$test->for('example', 1, 'Hash', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Hash';

  $result
});

=example-2 Hash

  package main;

  use Earth;
  use Earth::Entity 'Hash';

  my $string = Hash({});

  # bless( {...}, "Venus::Hash" )

=cut

$test->for('example', 2, 'Hash', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Hash');

  $result
});

=function Json

The Json function dispatches function and method calls to L<Venus::Json>.

=signature Json

  Json(HashRef $data) (Str | Object)

=metadata Json

{
  since => '0.01',
}

=example-1 Json

  package main;

  use Earth;
  use Earth::Entity 'Json';

  my $string = Json();

  # "Venus::Json"

=cut

$test->for('example', 1, 'Json', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Json';

  $result
});

=example-2 Json

  package main;

  use Earth;
  use Earth::Entity 'Json';

  my $string = Json({});

  # bless( {...}, "Venus::Json" )

=cut

$test->for('example', 2, 'Json', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Json');

  $result
});

=function Match

The Match function dispatches function and method calls to L<Venus::Match>.

=signature Match

  Match(HashRef $data) (Str | Object)

=metadata Match

{
  since => '0.01',
}

=example-1 Match

  package main;

  use Earth;
  use Earth::Entity 'Match';

  my $string = Match();

  # "Venus::Match"

=cut

$test->for('example', 1, 'Match', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Match';

  $result
});

=example-2 Match

  package main;

  use Earth;
  use Earth::Entity 'Match';

  my $string = Match({});

  # bless( {...}, "Venus::Match" )

=cut

$test->for('example', 2, 'Match', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Match');

  $result
});

=function Name

The Name function dispatches function and method calls to L<Venus::Name>.

=signature Name

  Name(HashRef $data) (Str | Object)

=metadata Name

{
  since => '0.01',
}

=example-1 Name

  package main;

  use Earth;
  use Earth::Entity 'Name';

  my $string = Name();

  # "Venus::Name"

=cut

$test->for('example', 1, 'Name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Name';

  $result
});

=example-2 Name

  package main;

  use Earth;
  use Earth::Entity 'Name';

  my $string = Name({});

  # bless( {...}, "Venus::Name" )

=cut

$test->for('example', 2, 'Name', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Name');

  $result
});

=function Number

The Number function dispatches function and method calls to L<Venus::Number>.

=signature Number

  Number(HashRef $data) (Str | Object)

=metadata Number

{
  since => '0.01',
}

=example-1 Number

  package main;

  use Earth;
  use Earth::Entity 'Number';

  my $string = Number();

  # "Venus::Number"

=cut

$test->for('example', 1, 'Number', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Number';

  $result
});

=example-2 Number

  package main;

  use Earth;
  use Earth::Entity 'Number';

  my $string = Number({});

  # bless( {...}, "Venus::Number" )

=cut

$test->for('example', 2, 'Number', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::Number');

  !$result
});

=function Opts

The Opts function dispatches function and method calls to L<Venus::Opts>.

=signature Opts

  Opts(HashRef $data) (Str | Object)

=metadata Opts

{
  since => '0.01',
}

=example-1 Opts

  package main;

  use Earth;
  use Earth::Entity 'Opts';

  my $string = Opts();

  # "Venus::Opts"

=cut

$test->for('example', 1, 'Opts', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Opts';

  $result
});

=example-2 Opts

  package main;

  use Earth;
  use Earth::Entity 'Opts';

  my $string = Opts({});

  # bless( {...}, "Venus::Opts" )

=cut

$test->for('example', 2, 'Opts', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Opts');

  $result
});

=function Path

The Path function dispatches function and method calls to L<Venus::Path>.

=signature Path

  Path(HashRef $data) (Str | Object)

=metadata Path

{
  since => '0.01',
}

=example-1 Path

  package main;

  use Earth;
  use Earth::Entity 'Path';

  my $string = Path();

  # "Venus::Path"

=cut

$test->for('example', 1, 'Path', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Path';

  $result
});

=example-2 Path

  package main;

  use Earth;
  use Earth::Entity 'Path';

  my $string = Path({});

  # bless( {...}, "Venus::Path" )

=cut

$test->for('example', 2, 'Path', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Path');

  $result
});

=function Process

The Process function dispatches function and method calls to L<Venus::Process>.

=signature Process

  Process(HashRef $data) (Str | Object)

=metadata Process

{
  since => '0.01',
}

=example-1 Process

  package main;

  use Earth;
  use Earth::Entity 'Process';

  my $string = Process();

  # "Venus::Process"

=cut

$test->for('example', 1, 'Process', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Process';

  $result
});

=example-2 Process

  package main;

  use Earth;
  use Earth::Entity 'Process';

  my $string = Process({});

  # bless( {...}, "Venus::Process" )

=cut

$test->for('example', 2, 'Process', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Process');

  $result
});

=function Regexp

The Regexp function dispatches function and method calls to L<Venus::Regexp>.

=signature Regexp

  Regexp(HashRef $data) (Str | Object)

=metadata Regexp

{
  since => '0.01',
}

=example-1 Regexp

  package main;

  use Earth;
  use Earth::Entity 'Regexp';

  my $string = Regexp();

  # "Venus::Regexp"

=cut

$test->for('example', 1, 'Regexp', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Regexp';

  $result
});

=example-2 Regexp

  package main;

  use Earth;
  use Earth::Entity 'Regexp';

  my $string = Regexp({});

  # bless( {...}, "Venus::Regexp" )

=cut

$test->for('example', 2, 'Regexp', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Regexp');

  $result
});

=function Replace

The Replace function dispatches function and method calls to L<Venus::Replace>.

=signature Replace

  Replace(HashRef $data) (Str | Object)

=metadata Replace

{
  since => '0.01',
}

=example-1 Replace

  package main;

  use Earth;
  use Earth::Entity 'Replace';

  my $string = Replace();

  # "Venus::Replace"

=cut

$test->for('example', 1, 'Replace', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Replace';

  $result
});

=example-2 Replace

  package main;

  use Earth;
  use Earth::Entity 'Replace';

  my $string = Replace({});

  # bless( {...}, "Venus::Replace" )

=cut

$test->for('example', 2, 'Replace', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::Replace');

  !$result
});

=function Scalar

The Scalar function dispatches function and method calls to L<Venus::Scalar>.

=signature Scalar

  Scalar(HashRef $data) (Str | Object)

=metadata Scalar

{
  since => '0.01',
}

=example-1 Scalar

  package main;

  use Earth;
  use Earth::Entity 'Scalar';

  my $string = Scalar();

  # "Venus::Scalar"

=cut

$test->for('example', 1, 'Scalar', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Scalar';

  $result
});

=example-2 Scalar

  package main;

  use Earth;
  use Earth::Entity 'Scalar';

  my $string = Scalar({});

  # bless( {...}, "Venus::Scalar" )

=cut

$test->for('example', 2, 'Scalar', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Scalar');

  $result
});

=function Search

The Search function dispatches function and method calls to L<Venus::Search>.

=signature Search

  Search(HashRef $data) (Str | Object)

=metadata Search

{
  since => '0.01',
}

=example-1 Search

  package main;

  use Earth;
  use Earth::Entity 'Search';

  my $string = Search();

  # "Venus::Search"

=cut

$test->for('example', 1, 'Search', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Search';

  $result
});

=example-2 Search

  package main;

  use Earth;
  use Earth::Entity 'Search';

  my $string = Search({});

  # bless( {...}, "Venus::Search" )

=cut

$test->for('example', 2, 'Search', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::Search');

  !$result
});

=function Space

The Space function dispatches function and method calls to L<Venus::Space>.

=signature Space

  Space(HashRef $data) (Str | Object)

=metadata Space

{
  since => '0.01',
}

=example-1 Space

  package main;

  use Earth;
  use Earth::Entity 'Space';

  my $string = Space();

  # "Venus::Space"

=cut

$test->for('example', 1, 'Space', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Space';

  $result
});

=example-2 Space

  package main;

  use Earth;
  use Earth::Entity 'Space';

  my $string = Space({});

  # bless( {...}, "Venus::Space" )

=cut

$test->for('example', 2, 'Space', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Space');

  $result
});

=function String

The String function dispatches function and method calls to L<Venus::String>.

=signature String

  String(HashRef $data) (Str | Object)

=metadata String

{
  since => '0.01',
}

=example-1 String

  package main;

  use Earth;
  use Earth::Entity 'String';

  my $string = String();

  # "Venus::String"

=cut

$test->for('example', 1, 'String', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::String';

  $result
});

=example-2 String

  package main;

  use Earth;
  use Earth::Entity 'String';

  my $string = String({});

  # bless( {...}, "Venus::String" )

=cut

$test->for('example', 2, 'String', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::String');

  !$result
});

=function Template

The Template function dispatches function and method calls to L<Venus::Template>.

=signature Template

  Template(HashRef $data) (Str | Object)

=metadata Template

{
  since => '0.01',
}

=example-1 Template

  package main;

  use Earth;
  use Earth::Entity 'Template';

  my $string = Template();

  # "Venus::Template"

=cut

$test->for('example', 1, 'Template', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Template';

  $result
});

=example-2 Template

  package main;

  use Earth;
  use Earth::Entity 'Template';

  my $string = Template({});

  # bless( {...}, "Venus::Template" )

=cut

$test->for('example', 2, 'Template', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::Template');

  !$result
});

=function Throw

The Throw function dispatches function and method calls to L<Venus::Throw>.

=signature Throw

  Throw(HashRef $data) (Str | Object)

=metadata Throw

{
  since => '0.01',
}

=example-1 Throw

  package main;

  use Earth;
  use Earth::Entity 'Throw';

  my $string = Throw();

  # "Venus::Throw"

=cut

$test->for('example', 1, 'Throw', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Throw';

  $result
});

=example-2 Throw

  package main;

  use Earth;
  use Earth::Entity 'Throw';

  my $string = Throw({});

  # bless( {...}, "Venus::Throw" )

=cut

$test->for('example', 2, 'Throw', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Throw');

  $result
});

=function Try

The Try function dispatches function and method calls to L<Venus::Try>.

=signature Try

  Try(HashRef $data) (Str | Object)

=metadata Try

{
  since => '0.01',
}

=example-1 Try

  package main;

  use Earth;
  use Earth::Entity 'Try';

  my $string = Try();

  # "Venus::Try"

=cut

$test->for('example', 1, 'Try', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Try';

  $result
});

=example-2 Try

  package main;

  use Earth;
  use Earth::Entity 'Try';

  my $string = Try({});

  # bless( {...}, "Venus::Try" )

=cut

$test->for('example', 2, 'Try', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Try');

  $result
});

=function Type

The Type function dispatches function and method calls to L<Venus::Type>.

=signature Type

  Type(HashRef $data) (Str | Object)

=metadata Type

{
  since => '0.01',
}

=example-1 Type

  package main;

  use Earth;
  use Earth::Entity 'Type';

  my $string = Type();

  # "Venus::Type"

=cut

$test->for('example', 1, 'Type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Type';

  $result
});

=example-2 Type

  package main;

  use Earth;
  use Earth::Entity 'Type';

  my $string = Type({});

  # bless( {...}, "Venus::Type" )

=cut

$test->for('example', 2, 'Type', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Type');

  $result
});

=function Undef

The Undef function dispatches function and method calls to L<Venus::Undef>.

=signature Undef

  Undef(HashRef $data) (Str | Object)

=metadata Undef

{
  since => '0.01',
}

=example-1 Undef

  package main;

  use Earth;
  use Earth::Entity 'Undef';

  my $string = Undef();

  # "Venus::Undef"

=cut

$test->for('example', 1, 'Undef', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Undef';

  $result
});

=example-2 Undef

  package main;

  use Earth;
  use Earth::Entity 'Undef';

  my $string = Undef({});

  # bless( {...}, "Venus::Undef" )

=cut

$test->for('example', 2, 'Undef', sub {
  my ($tryable) = @_;
  ok !(my $result = $tryable->result);
  ok $result->isa('Venus::Undef');

  !$result
});

=function Vars

The Vars function dispatches function and method calls to L<Venus::Vars>.

=signature Vars

  Vars(HashRef $data) (Str | Object)

=metadata Vars

{
  since => '0.01',
}

=example-1 Vars

  package main;

  use Earth;
  use Earth::Entity 'Vars';

  my $string = Vars();

  # "Venus::Vars"

=cut

$test->for('example', 1, 'Vars', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Vars';

  $result
});

=example-2 Vars

  package main;

  use Earth;
  use Earth::Entity 'Vars';

  my $string = Vars({});

  # bless( {...}, "Venus::Vars" )

=cut

$test->for('example', 2, 'Vars', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Vars');

  $result
});

=function Yaml

The Yaml function dispatches function and method calls to L<Venus::Yaml>.

=signature Yaml

  Yaml(HashRef $data) (Str | Object)

=metadata Yaml

{
  since => '0.01',
}

=example-1 Yaml

  package main;

  use Earth;
  use Earth::Entity 'Yaml';

  my $string = Yaml();

  # "Venus::Yaml"

=cut

$test->for('example', 1, 'Yaml', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result eq 'Venus::Yaml';

  $result
});

=example-2 Yaml

  package main;

  use Earth;
  use Earth::Entity 'Yaml';

  my $string = Yaml({});

  # bless( {...}, "Venus::Yaml" )

=cut

$test->for('example', 2, 'Yaml', sub {
  my ($tryable) = @_;
  ok my $result = $tryable->result;
  ok $result->isa('Venus::Yaml');

  $result
})
if require Venus::Yaml && Venus::Yaml->package;

=authors

Awncorp, C<awncorp@cpan.org>

=cut

# END

$test->render('lib/Earth/Entity.pod') if $ENV{RENDER};

ok 1 and done_testing;
