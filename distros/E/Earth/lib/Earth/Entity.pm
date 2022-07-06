package Earth::Entity;

use 5.018;

use strict;
use warnings;

use Earth;
use Exporter 'import';

our @EXPORT_OK = (
  'Args',
  'Array',
  'Boolean',
  'Code',
  'Data',
  'Date',
  'Error',
  'Float',
  'Hash',
  'Json',
  'Match',
  'Name',
  'Number',
  'Opts',
  'Path',
  'Process',
  'Regexp',
  'Replace',
  'Scalar',
  'Search',
  'Space',
  'String',
  'Template',
  'Throw',
  'Try',
  'Type',
  'Undef',
  'Vars',
  'Yaml',
);

# WRAPPERS

wrap 'Venus::Args', 'Args';
wrap 'Venus::Array', 'Array';
wrap 'Venus::Boolean', 'Boolean';
wrap 'Venus::Code', 'Code';
wrap 'Venus::Data', 'Data';
wrap 'Venus::Date', 'Date';
wrap 'Venus::Error', 'Error';
wrap 'Venus::Float', 'Float';
wrap 'Venus::Hash', 'Hash';
wrap 'Venus::Json', 'Json';
wrap 'Venus::Match', 'Match';
wrap 'Venus::Name', 'Name';
wrap 'Venus::Number', 'Number';
wrap 'Venus::Opts', 'Opts';
wrap 'Venus::Path', 'Path';
wrap 'Venus::Process', 'Process';
wrap 'Venus::Regexp', 'Regexp';
wrap 'Venus::Replace', 'Replace';
wrap 'Venus::Scalar', 'Scalar';
wrap 'Venus::Search', 'Search';
wrap 'Venus::Space', 'Space';
wrap 'Venus::String', 'String';
wrap 'Venus::Template', 'Template';
wrap 'Venus::Throw', 'Throw';
wrap 'Venus::Try', 'Try';
wrap 'Venus::Type', 'Type';
wrap 'Venus::Undef', 'Undef';
wrap 'Venus::Vars', 'Vars';
wrap 'Venus::Yaml', 'Yaml';

1;



=head1 NAME

Earth::Entity - FP Library Functions

=cut

=head1 ABSTRACT

FP Standard Library Functions for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Earth;
  use Earth::Entity 'Space';

  Space;

  # "Venus::Space"

=cut

=head1 DESCRIPTION

This package compliments the Earth functional-programming framework by
providing wrapper functions, via L<Earth/wrap>, which wrap L<Venus> classes,
providing a functional abstraction around the Venus object-oriented standard
library.

=cut

=head1 FUNCTIONS

This package provides the following functions:

=cut

=head2 args

  Args(HashRef $data) (Str | Object)

The Args function dispatches function and method calls to L<Venus::Args>.

I<Since C<0.01>>

=over 4

=item Args example 1

  package main;

  use Earth;
  use Earth::Entity 'Args';

  my $string = Args();

  # "Venus::Args"

=back

=over 4

=item Args example 2

  package main;

  use Earth;
  use Earth::Entity 'Args';

  my $string = Args({});

  # bless( {...}, "Venus::Args" )

=back

=cut

=head2 array

  Array(HashRef $data) (Str | Object)

The Array function dispatches function and method calls to L<Venus::Array>.

I<Since C<0.01>>

=over 4

=item Array example 1

  package main;

  use Earth;
  use Earth::Entity 'Array';

  my $string = Array();

  # "Venus::Array"

=back

=over 4

=item Array example 2

  package main;

  use Earth;
  use Earth::Entity 'Array';

  my $string = Array({});

  # bless( {...}, "Venus::Array" )

=back

=cut

=head2 boolean

  Boolean(HashRef $data) (Str | Object)

The Boolean function dispatches function and method calls to L<Venus::Boolean>.

I<Since C<0.01>>

=over 4

=item Boolean example 1

  package main;

  use Earth;
  use Earth::Entity 'Boolean';

  my $string = Boolean();

  # "Venus::Boolean"

=back

=over 4

=item Boolean example 2

  package main;

  use Earth;
  use Earth::Entity 'Boolean';

  my $string = Boolean({});

  # bless( {...}, "Venus::Boolean" )

=back

=cut

=head2 code

  Code(HashRef $data) (Str | Object)

The Code function dispatches function and method calls to L<Venus::Code>.

I<Since C<0.01>>

=over 4

=item Code example 1

  package main;

  use Earth;
  use Earth::Entity 'Code';

  my $string = Code();

  # "Venus::Code"

=back

=over 4

=item Code example 2

  package main;

  use Earth;
  use Earth::Entity 'Code';

  my $string = Code({});

  # bless( {...}, "Venus::Code" )

=back

=cut

=head2 data

  Data(HashRef $data) (Str | Object)

The Data function dispatches function and method calls to L<Venus::Data>.

I<Since C<0.01>>

=over 4

=item Data example 1

  package main;

  use Earth;
  use Earth::Entity 'Data';

  my $string = Data();

  # "Venus::Data"

=back

=over 4

=item Data example 2

  package main;

  use Earth;
  use Earth::Entity 'Data';

  my $string = Data({});

  # bless( {...}, "Venus::Data" )

=back

=cut

=head2 date

  Date(HashRef $data) (Str | Object)

The Date function dispatches function and method calls to L<Venus::Date>.

I<Since C<0.01>>

=over 4

=item Date example 1

  package main;

  use Earth;
  use Earth::Entity 'Date';

  my $string = Date();

  # "Venus::Date"

=back

=over 4

=item Date example 2

  package main;

  use Earth;
  use Earth::Entity 'Date';

  my $string = Date({});

  # bless( {...}, "Venus::Date" )

=back

=cut

=head2 error

  Error(HashRef $data) (Str | Object)

The Error function dispatches function and method calls to L<Venus::Error>.

I<Since C<0.01>>

=over 4

=item Error example 1

  package main;

  use Earth;
  use Earth::Entity 'Error';

  my $string = Error();

  # "Venus::Error"

=back

=over 4

=item Error example 2

  package main;

  use Earth;
  use Earth::Entity 'Error';

  my $string = Error({});

  # bless( {...}, "Venus::Error" )

=back

=cut

=head2 float

  Float(HashRef $data) (Str | Object)

The Float function dispatches function and method calls to L<Venus::Float>.

I<Since C<0.01>>

=over 4

=item Float example 1

  package main;

  use Earth;
  use Earth::Entity 'Float';

  my $string = Float();

  # "Venus::Float"

=back

=over 4

=item Float example 2

  package main;

  use Earth;
  use Earth::Entity 'Float';

  my $string = Float({});

  # bless( {...}, "Venus::Float" )

=back

=cut

=head2 hash

  Hash(HashRef $data) (Str | Object)

The Hash function dispatches function and method calls to L<Venus::Hash>.

I<Since C<0.01>>

=over 4

=item Hash example 1

  package main;

  use Earth;
  use Earth::Entity 'Hash';

  my $string = Hash();

  # "Venus::Hash"

=back

=over 4

=item Hash example 2

  package main;

  use Earth;
  use Earth::Entity 'Hash';

  my $string = Hash({});

  # bless( {...}, "Venus::Hash" )

=back

=cut

=head2 json

  Json(HashRef $data) (Str | Object)

The Json function dispatches function and method calls to L<Venus::Json>.

I<Since C<0.01>>

=over 4

=item Json example 1

  package main;

  use Earth;
  use Earth::Entity 'Json';

  my $string = Json();

  # "Venus::Json"

=back

=over 4

=item Json example 2

  package main;

  use Earth;
  use Earth::Entity 'Json';

  my $string = Json({});

  # bless( {...}, "Venus::Json" )

=back

=cut

=head2 match

  Match(HashRef $data) (Str | Object)

The Match function dispatches function and method calls to L<Venus::Match>.

I<Since C<0.01>>

=over 4

=item Match example 1

  package main;

  use Earth;
  use Earth::Entity 'Match';

  my $string = Match();

  # "Venus::Match"

=back

=over 4

=item Match example 2

  package main;

  use Earth;
  use Earth::Entity 'Match';

  my $string = Match({});

  # bless( {...}, "Venus::Match" )

=back

=cut

=head2 name

  Name(HashRef $data) (Str | Object)

The Name function dispatches function and method calls to L<Venus::Name>.

I<Since C<0.01>>

=over 4

=item Name example 1

  package main;

  use Earth;
  use Earth::Entity 'Name';

  my $string = Name();

  # "Venus::Name"

=back

=over 4

=item Name example 2

  package main;

  use Earth;
  use Earth::Entity 'Name';

  my $string = Name({});

  # bless( {...}, "Venus::Name" )

=back

=cut

=head2 number

  Number(HashRef $data) (Str | Object)

The Number function dispatches function and method calls to L<Venus::Number>.

I<Since C<0.01>>

=over 4

=item Number example 1

  package main;

  use Earth;
  use Earth::Entity 'Number';

  my $string = Number();

  # "Venus::Number"

=back

=over 4

=item Number example 2

  package main;

  use Earth;
  use Earth::Entity 'Number';

  my $string = Number({});

  # bless( {...}, "Venus::Number" )

=back

=cut

=head2 opts

  Opts(HashRef $data) (Str | Object)

The Opts function dispatches function and method calls to L<Venus::Opts>.

I<Since C<0.01>>

=over 4

=item Opts example 1

  package main;

  use Earth;
  use Earth::Entity 'Opts';

  my $string = Opts();

  # "Venus::Opts"

=back

=over 4

=item Opts example 2

  package main;

  use Earth;
  use Earth::Entity 'Opts';

  my $string = Opts({});

  # bless( {...}, "Venus::Opts" )

=back

=cut

=head2 path

  Path(HashRef $data) (Str | Object)

The Path function dispatches function and method calls to L<Venus::Path>.

I<Since C<0.01>>

=over 4

=item Path example 1

  package main;

  use Earth;
  use Earth::Entity 'Path';

  my $string = Path();

  # "Venus::Path"

=back

=over 4

=item Path example 2

  package main;

  use Earth;
  use Earth::Entity 'Path';

  my $string = Path({});

  # bless( {...}, "Venus::Path" )

=back

=cut

=head2 process

  Process(HashRef $data) (Str | Object)

The Process function dispatches function and method calls to L<Venus::Process>.

I<Since C<0.01>>

=over 4

=item Process example 1

  package main;

  use Earth;
  use Earth::Entity 'Process';

  my $string = Process();

  # "Venus::Process"

=back

=over 4

=item Process example 2

  package main;

  use Earth;
  use Earth::Entity 'Process';

  my $string = Process({});

  # bless( {...}, "Venus::Process" )

=back

=cut

=head2 regexp

  Regexp(HashRef $data) (Str | Object)

The Regexp function dispatches function and method calls to L<Venus::Regexp>.

I<Since C<0.01>>

=over 4

=item Regexp example 1

  package main;

  use Earth;
  use Earth::Entity 'Regexp';

  my $string = Regexp();

  # "Venus::Regexp"

=back

=over 4

=item Regexp example 2

  package main;

  use Earth;
  use Earth::Entity 'Regexp';

  my $string = Regexp({});

  # bless( {...}, "Venus::Regexp" )

=back

=cut

=head2 replace

  Replace(HashRef $data) (Str | Object)

The Replace function dispatches function and method calls to L<Venus::Replace>.

I<Since C<0.01>>

=over 4

=item Replace example 1

  package main;

  use Earth;
  use Earth::Entity 'Replace';

  my $string = Replace();

  # "Venus::Replace"

=back

=over 4

=item Replace example 2

  package main;

  use Earth;
  use Earth::Entity 'Replace';

  my $string = Replace({});

  # bless( {...}, "Venus::Replace" )

=back

=cut

=head2 scalar

  Scalar(HashRef $data) (Str | Object)

The Scalar function dispatches function and method calls to L<Venus::Scalar>.

I<Since C<0.01>>

=over 4

=item Scalar example 1

  package main;

  use Earth;
  use Earth::Entity 'Scalar';

  my $string = Scalar();

  # "Venus::Scalar"

=back

=over 4

=item Scalar example 2

  package main;

  use Earth;
  use Earth::Entity 'Scalar';

  my $string = Scalar({});

  # bless( {...}, "Venus::Scalar" )

=back

=cut

=head2 search

  Search(HashRef $data) (Str | Object)

The Search function dispatches function and method calls to L<Venus::Search>.

I<Since C<0.01>>

=over 4

=item Search example 1

  package main;

  use Earth;
  use Earth::Entity 'Search';

  my $string = Search();

  # "Venus::Search"

=back

=over 4

=item Search example 2

  package main;

  use Earth;
  use Earth::Entity 'Search';

  my $string = Search({});

  # bless( {...}, "Venus::Search" )

=back

=cut

=head2 space

  Space(HashRef $data) (Str | Object)

The Space function dispatches function and method calls to L<Venus::Space>.

I<Since C<0.01>>

=over 4

=item Space example 1

  package main;

  use Earth;
  use Earth::Entity 'Space';

  my $string = Space();

  # "Venus::Space"

=back

=over 4

=item Space example 2

  package main;

  use Earth;
  use Earth::Entity 'Space';

  my $string = Space({});

  # bless( {...}, "Venus::Space" )

=back

=cut

=head2 string

  String(HashRef $data) (Str | Object)

The String function dispatches function and method calls to L<Venus::String>.

I<Since C<0.01>>

=over 4

=item String example 1

  package main;

  use Earth;
  use Earth::Entity 'String';

  my $string = String();

  # "Venus::String"

=back

=over 4

=item String example 2

  package main;

  use Earth;
  use Earth::Entity 'String';

  my $string = String({});

  # bless( {...}, "Venus::String" )

=back

=cut

=head2 template

  Template(HashRef $data) (Str | Object)

The Template function dispatches function and method calls to L<Venus::Template>.

I<Since C<0.01>>

=over 4

=item Template example 1

  package main;

  use Earth;
  use Earth::Entity 'Template';

  my $string = Template();

  # "Venus::Template"

=back

=over 4

=item Template example 2

  package main;

  use Earth;
  use Earth::Entity 'Template';

  my $string = Template({});

  # bless( {...}, "Venus::Template" )

=back

=cut

=head2 throw

  Throw(HashRef $data) (Str | Object)

The Throw function dispatches function and method calls to L<Venus::Throw>.

I<Since C<0.01>>

=over 4

=item Throw example 1

  package main;

  use Earth;
  use Earth::Entity 'Throw';

  my $string = Throw();

  # "Venus::Throw"

=back

=over 4

=item Throw example 2

  package main;

  use Earth;
  use Earth::Entity 'Throw';

  my $string = Throw({});

  # bless( {...}, "Venus::Throw" )

=back

=cut

=head2 try

  Try(HashRef $data) (Str | Object)

The Try function dispatches function and method calls to L<Venus::Try>.

I<Since C<0.01>>

=over 4

=item Try example 1

  package main;

  use Earth;
  use Earth::Entity 'Try';

  my $string = Try();

  # "Venus::Try"

=back

=over 4

=item Try example 2

  package main;

  use Earth;
  use Earth::Entity 'Try';

  my $string = Try({});

  # bless( {...}, "Venus::Try" )

=back

=cut

=head2 type

  Type(HashRef $data) (Str | Object)

The Type function dispatches function and method calls to L<Venus::Type>.

I<Since C<0.01>>

=over 4

=item Type example 1

  package main;

  use Earth;
  use Earth::Entity 'Type';

  my $string = Type();

  # "Venus::Type"

=back

=over 4

=item Type example 2

  package main;

  use Earth;
  use Earth::Entity 'Type';

  my $string = Type({});

  # bless( {...}, "Venus::Type" )

=back

=cut

=head2 undef

  Undef(HashRef $data) (Str | Object)

The Undef function dispatches function and method calls to L<Venus::Undef>.

I<Since C<0.01>>

=over 4

=item Undef example 1

  package main;

  use Earth;
  use Earth::Entity 'Undef';

  my $string = Undef();

  # "Venus::Undef"

=back

=over 4

=item Undef example 2

  package main;

  use Earth;
  use Earth::Entity 'Undef';

  my $string = Undef({});

  # bless( {...}, "Venus::Undef" )

=back

=cut

=head2 vars

  Vars(HashRef $data) (Str | Object)

The Vars function dispatches function and method calls to L<Venus::Vars>.

I<Since C<0.01>>

=over 4

=item Vars example 1

  package main;

  use Earth;
  use Earth::Entity 'Vars';

  my $string = Vars();

  # "Venus::Vars"

=back

=over 4

=item Vars example 2

  package main;

  use Earth;
  use Earth::Entity 'Vars';

  my $string = Vars({});

  # bless( {...}, "Venus::Vars" )

=back

=cut

=head2 yaml

  Yaml(HashRef $data) (Str | Object)

The Yaml function dispatches function and method calls to L<Venus::Yaml>.

I<Since C<0.01>>

=over 4

=item Yaml example 1

  package main;

  use Earth;
  use Earth::Entity 'Yaml';

  my $string = Yaml();

  # "Venus::Yaml"

=back

=over 4

=item Yaml example 2

  package main;

  use Earth;
  use Earth::Entity 'Yaml';

  my $string = Yaml({});

  # bless( {...}, "Venus::Yaml" )

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut