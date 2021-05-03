use strict;
use warnings;
package Test::Deep::JType;
# ABSTRACT: Test::Deep helpers for JSON::Typist data
$Test::Deep::JType::VERSION = '0.007';
use JSON::PP ();
use JSON::Typist ();
use Test::Deep 1.126 (); # LeafWrapper, as_test_deep_cmp

use Exporter 'import';
our @EXPORT = qw( jcmp_deeply jstr jnum jbool jtrue jfalse );

#pod =head1 OVERVIEW
#pod
#pod L<Test::Deep> is a very useful library for testing data structures.
#pod Test::Deep::JType extends it with routines for testing
#pod L<JSON::Typist>-annotated data.
#pod
#pod By default, Test::Deep's C<cmp_deeply> will interpret plain numbers and strings
#pod as shorthand for C<shallow(...)> tests, meaning that the corresponding input
#pod data will also need to be a plain number or string.  That means that this test
#pod won't work:
#pod
#pod   my $json  = q[ { "key": "value" } ];
#pod   my $data  = decode_json($json);
#pod   my $typed = JSON::Typist->new->apply_types( $data );
#pod
#pod   cmp_deeply($typed, { key => "value" });
#pod
#pod ...because C<"value"> will refuse to match an object.  You I<could> wrap each
#pod string or number to be compared in C<str()> or C<num()> respectively, but this
#pod can be a hassle, as well as a lot of clutter.
#pod
#pod C<jcmp_deeply> is exported by Test::Deep::JType, and behaves just like
#pod C<cmp_deeply>, but plain numbers and strings are wrapped in C<str()> tests
#pod rather than shallow ones, so they always compare with C<eq>.
#pod
#pod To test that the input data matches the right type, other routines are exported
#pod that check type as well as content.
#pod
#pod =cut

#pod =func jcmp_deeply
#pod
#pod This behaves just like Test::Deep's C<jcmp_deeply> but wraps plain scalar and
#pod number expectations in C<str>, meaning they're compared with C<eq> only,
#pod instead of also asserting that the found value must not be an object.
#pod
#pod =cut

sub jcmp_deeply {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  local $Test::Deep::LeafWrapper = sub { Test::Deep::JType::_String->new(@_) },
  Test::Deep::cmp_deeply(@_);
}

#pod =func jstr
#pod
#pod =func jnum
#pod
#pod =func jbool
#pod
#pod =func jtrue
#pod
#pod =func jfalse
#pod
#pod These routines are plain old Test::Deep-style assertions that check not only
#pod for data equivalence, but also that the data is the right type.
#pod
#pod C<jstr>, C<jnum>, and C<jbool> take arguments, which are passed to the non-C<j>
#pod version of the test used in building the C<j>-style version.  In other words,
#pod you can write:
#pod
#pod   jcmp_deeply(
#pod     $got,
#pod     {
#pod       name => jstr("Ricardo"),
#pod       age  => jnum(38.2, 0.01),
#pod       calm => jbool(1),
#pod       cool => jbool(),
#pod       collected => jfalse(),
#pod     },
#pod   );
#pod
#pod If no argument is given, then the wrapped value isn't inspected.  C<jstr> just
#pod makes sure the value was a JSON string, without comparing it to anything.
#pod
#pod C<jtrue> and C<jfalse> are shorthand for C<jbool(1)> and C<jbool(0)>,
#pod respectively.
#pod
#pod As long as they've got a specific value to test for (that is, you called
#pod C<jstr("foo")> and not C<jstr()>, the tests produced by these routines will
#pod serialize via a C<convert_blessed>-enabled JSON encode into the appropriate
#pod types.  This makes it convenient to use these routines for building JSON as
#pod well as testing it.
#pod
#pod =cut

my $STRING = Test::Deep::obj_isa('JSON::Typist::String');
my $NUMBER = Test::Deep::obj_isa('JSON::Typist::Number');
my $BOOL   = Test::Deep::any(
  Test::Deep::obj_isa('JSON::XS::Boolean'),
  Test::Deep::obj_isa('JSON::PP::Boolean'),
);

sub jstr  { Test::Deep::JType::jstr->new(@_);  }
sub jnum  { Test::Deep::JType::jnum->new(@_);  }
sub jbool { Test::Deep::JType::jbool->new(@_); }

my $TRUE  = jbool(1);
my $FALSE = jbool(0);

sub jtrue  { $TRUE  }
sub jfalse { $FALSE }

{
  package
    Test::Deep::JType::_String;

  use Test::Deep::Cmp;

  sub init
  {
    my $self = shift;

    $self->{val} = shift;
  }

  sub descend
  {
    my $self = shift;
    my $got = shift;

    # Stringify what we got for test output purposes. Otherwise,
    # string overloading won't be called on $got, and we'll end up
    # with 'JSON::Typist::String=SCALAR(0x...) in our test output
    $self->data->{got} = $got . "" if defined $got;

    # If either is undef but not both this is a failure where
    # as Test::Deep::String would just stringify the undef,
    # throw a warning, and pass
    if (defined($got) xor defined($self->{val})) {
      return 0;
    }

    return $got eq $self->{val};
  }

  sub diag_message
  {
    my $self = shift;

    my $where = shift;

    return "Comparing $where as a string";
  }
}

{
  package Test::Deep::JType::jstr;
$Test::Deep::JType::jstr::VERSION = '0.007';
use overload
    '""'    => sub {
      Carp::confess("can't use valueless jstr() as a string")
        unless defined ${ $_[0] };
      return ${ $_[0] };
    },
    fallback => 1;

  BEGIN { our @ISA = 'JSON::Typist::String'; }
  sub TO_JSON {
    Carp::confess("can't use valueless jstr() test as JSON data")
      unless defined ${ $_[0] };
    return "${ $_[0] }";
  }

  sub as_test_deep_cmp {
    my ($self) = @_;
    my $value = $$self;
    return defined $value ? Test::Deep::all($STRING, Test::Deep::str($value))
                          : $STRING;
  }
}

{
  package Test::Deep::JType::jnum;
$Test::Deep::JType::jnum::VERSION = '0.007';
use overload
    '0+'    => sub {
      Carp::confess("can't use valueless jnum() as a number")
        unless defined ${ $_[0] };
      return ${ $_[0] };
    },
    fallback => 1;

  BEGIN { our @ISA = 'JSON::Typist::Number'; }
  sub TO_JSON {
    Carp::confess("can't use valueless jnum() test as JSON data")
      unless defined ${ $_[0] };
    return 0 + ${ $_[0] };
  }

  sub as_test_deep_cmp {
    my ($self) = @_;
    my $value = $$self;
    return defined $value ? Test::Deep::all($NUMBER, Test::Deep::num($value))
                          : $NUMBER;
  }
}

{
  package Test::Deep::JType::jbool;
$Test::Deep::JType::jbool::VERSION = '0.007';
use overload
    'bool'    => sub {
      Carp::confess("can't use valueless jbool() as a bool")
        unless defined ${ $_[0] };
      return ${ $_[0] };
    },
    fallback => 1;

  sub TO_JSON {
    Carp::confess("can't use valueless jbool() test as JSON data")
      unless defined ${ $_[0] };
    return ${ $_[0] } ? \1 : \0;
  }

  sub new {
    my ($class, $value) = @_;
    bless \$value, $class;
  }

  sub as_test_deep_cmp {
    my ($self) = @_;
    my $value = $$self;
    return defined $value ? Test::Deep::all($BOOL, Test::Deep::bool($value))
                          : $BOOL;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::JType - Test::Deep helpers for JSON::Typist data

=head1 VERSION

version 0.007

=head1 OVERVIEW

L<Test::Deep> is a very useful library for testing data structures.
Test::Deep::JType extends it with routines for testing
L<JSON::Typist>-annotated data.

By default, Test::Deep's C<cmp_deeply> will interpret plain numbers and strings
as shorthand for C<shallow(...)> tests, meaning that the corresponding input
data will also need to be a plain number or string.  That means that this test
won't work:

  my $json  = q[ { "key": "value" } ];
  my $data  = decode_json($json);
  my $typed = JSON::Typist->new->apply_types( $data );

  cmp_deeply($typed, { key => "value" });

...because C<"value"> will refuse to match an object.  You I<could> wrap each
string or number to be compared in C<str()> or C<num()> respectively, but this
can be a hassle, as well as a lot of clutter.

C<jcmp_deeply> is exported by Test::Deep::JType, and behaves just like
C<cmp_deeply>, but plain numbers and strings are wrapped in C<str()> tests
rather than shallow ones, so they always compare with C<eq>.

To test that the input data matches the right type, other routines are exported
that check type as well as content.

=head1 FUNCTIONS

=head2 jcmp_deeply

This behaves just like Test::Deep's C<jcmp_deeply> but wraps plain scalar and
number expectations in C<str>, meaning they're compared with C<eq> only,
instead of also asserting that the found value must not be an object.

=head2 jstr

=head2 jnum

=head2 jbool

=head2 jtrue

=head2 jfalse

These routines are plain old Test::Deep-style assertions that check not only
for data equivalence, but also that the data is the right type.

C<jstr>, C<jnum>, and C<jbool> take arguments, which are passed to the non-C<j>
version of the test used in building the C<j>-style version.  In other words,
you can write:

  jcmp_deeply(
    $got,
    {
      name => jstr("Ricardo"),
      age  => jnum(38.2, 0.01),
      calm => jbool(1),
      cool => jbool(),
      collected => jfalse(),
    },
  );

If no argument is given, then the wrapped value isn't inspected.  C<jstr> just
makes sure the value was a JSON string, without comparing it to anything.

C<jtrue> and C<jfalse> are shorthand for C<jbool(1)> and C<jbool(0)>,
respectively.

As long as they've got a specific value to test for (that is, you called
C<jstr("foo")> and not C<jstr()>, the tests produced by these routines will
serialize via a C<convert_blessed>-enabled JSON encode into the appropriate
types.  This makes it convenient to use these routines for building JSON as
well as testing it.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
