package Defaults::Modern;
$Defaults::Modern::VERSION = '0.011001';
use v5.14;

use strictures 2;
no indirect ':fatal';
no bareword::filehandles;

use Module::Runtime 'use_package_optimistically';
use Try::Tiny;
use Import::Into;


use Carp    ();
use feature ();
use true    ();

use match::simple ();

use Defaults::Modern::Define  ();
use Function::Parameters      ();
use List::Objects::WithUtils  ();
use Path::Tiny                ();
use PerlX::Maybe              ();
use Quote::Code               ();
use Scalar::Util              ();
use Switch::Plain             ();

use Types::Standard           ();
use Types::Path::Tiny         ();
use Type::Registry            ();
use Type::Utils               ();
use List::Objects::Types      ();


sub import {
  my $class = shift;
  my $pkg = caller;

  state $known = +{ 
    map {; $_ => 1 } qw/
      all
      autobox_lists 
      moo
    /
  };

  my %params;
  my $idx = 0;
  my $typelibs;
  PARAM: for my $item (@_) {
    my $current = $idx++;
    if ($item eq 'with_types' || $item eq '-with_types') {
      # backwards-compat ; may go away someday
      Carp::carp(
        "'with_types' option is deprecated; ",
        "'use TYPELIB -all' after 'use Defaults::Modern;' instead"
      );
      $typelibs = $_[$idx];
      splice @_, $current, 2;
      if (ref $typelibs) {
        Carp::croak "with_types should be an ARRAY, got $typelibs"
          if Scalar::Util::reftype($typelibs) ne 'ARRAY';
      } else {
        $typelibs = [ $typelibs ]
      }
      next PARAM
    }

    my $opt = lc($item =~ s/^(?:[-:])//r);
    Carp::croak("$class does not export $opt") unless $known->{$opt};

    if ($opt eq 'all') {
      $params{$_} = 1 for grep {; $_ ne 'all' } keys %$known;
      next PARAM
    }

    $params{$opt} = 1;
  }

  # Us
  Defaults::Modern::Define->import::into($pkg);

  # Core
  Carp->import::into($pkg,
    qw/carp croak confess/,
  );

  Scalar::Util->import::into($pkg,
    qw/blessed reftype weaken/,
  );
  
  # Pragmas
  strictures->import::into($pkg, version => 2);
  bareword::filehandles->unimport;
  indirect->unimport(':fatal');
  warnings->unimport('once');
  if ($] >= 5.018) {
    warnings->unimport('experimental');
  }

  feature->import(':5.14');
  feature->unimport('switch');

  match::simple->import::into($pkg);
  true->import;

  # External functionality

  state $fp_defaults = +{
    strict                => 1,
    default_arguments     => 1,
    named_parameters      => 1,
    types                 => 1,
    reify_type            => sub {
      state $guard = do { require Type::Utils };
      Type::Utils::dwim_type($_[0], for => $_[1])
    },
  };

  Function::Parameters->import(
    +{
      fun => {
        name                  => 'optional',
        %$fp_defaults
      },
      method => {
        name                  => 'required',
        attributes            => ':method',
        shift                 => '$self',
        invocant              => 1,
        %$fp_defaults
      }
    }
  );

  Path::Tiny->import::into($pkg, 'path');

  PerlX::Maybe->import::into($pkg, qw/maybe provided/);

  Quote::Code->import::into($pkg, qw/qc qcw qc_to/);

  Try::Tiny->import::into($pkg);
  Switch::Plain->import;

  $params{autobox_lists} ?
    List::Objects::WithUtils->import::into($pkg, 'all')
    : List::Objects::WithUtils->import::into($pkg);

  # Types
  state $mytypelibs = [ qw/
    Types::Standard
    Types::Path::Tiny
    List::Objects::Types
  / ];

  for my $typelib (@$mytypelibs, @$typelibs) {
    use_package_optimistically($typelib)->import::into($pkg, -all);
# Irrelevant with Type::Tiny-1.x ->
#    try {
#      Type::Registry->for_class($pkg)->add_types($typelib);
#    } catch {
      # Usually conflicts; whine but prefer user's previous imports:
#      Carp::carp($_)
#    };
  }

  if (defined $params{moo}) {
    require Moo;
    Moo->import::into($pkg);
  }

  $class
}

1;

=pod

=head1 NAME

Defaults::Modern - Yet another approach to modernistic Perl

=head1 SYNOPSIS

  use Defaults::Modern;

  # Function::Parameters + List::Objects::WithUtils + types ->
  fun to_immutable ( (ArrayRef | ArrayObj) $arr ) {
    # blessed() and confess() are available (amongst others):
    my $immutable = immarray( blessed $arr ? $arr->all : @$arr );
    confess 'No items in array!' unless $immutable->has_any;
    $immutable
  }

  package My::Foo {
    use Defaults::Modern;

    # define keyword for defining constants ->
    define ARRAY_MAX = 10;

    # Moo(se) with types ->
    use Moo;

    has myarray => (
      is      => 'ro',
      isa     => ArrayObj,
      writer  => '_set_myarray',
      coerce  => 1,
      builder => sub { [] },
    );

    # Method with optional positional param and implicit $self ->
    method slice_to_max (Int $max = -1) {
      my $arr = $self->myarray;
      $self->_set_myarray( 
        $arr->sliced( 0 .. $max >= 0 ? $max : ARRAY_MAX )
      )
    }
  }

  # Optionally autobox list-type refs via List::Objects::WithUtils ->
  use Defaults::Modern 'autobox_lists';
  my $obj = +{ foo => 'bar', baz => 'quux' }->inflate;
  my $baz = $obj->baz;

  # See DESCRIPTION for complete details on imported functionality.

=head1 DESCRIPTION

Yet another approach to writing Perl in a modern style.

. . . also saves me extensive typing ;-)

When you C<use Defaults::Modern>, you get:

=over

=item *

L<strictures> (version 2), which enables L<strict> and makes most warnings
fatal; additionally L<bareword::filehandles> and L<indirect> method calls are
disallowed explicitly (not just in development environments)

=item *

The C<v5.14> feature set (C<state>, C<say>, C<unicode_strings>, C<array_base>) -- except for
C<switch>, which is deprecated in newer perls (and L<Switch::Plain> is
provided anyway).

C<experimental> warnings are also disabled on C<v5.18+>.

=item *

B<carp>, B<croak>, and B<confess> error reporting tools from L<Carp>

=item *

B<blessed>, B<reftype>, and B<weaken> utilities from L<Scalar::Util>

=item *

All of the L<List::Objects::WithUtils> object constructors (B<array>,
B<array_of>, B<immarray>, B<immarray_of>, B<hash>, B<hash_of>, B<immhash>,
B<immhash_of>)

=item *

B<fun> and B<method> keywords from L<Function::Parameters> configured to
accept L<Type::Tiny> types (amongst other reasonably sane defaults including
arity checks)

=item *

The full L<Types::Standard> set and L<List::Objects::Types> -- useful in
combination with L<Function::Parameters> (see the L</SYNOPSIS> and
L<Function::Parameters> POD)

=item *

B<try> and B<catch> from L<Try::Tiny>

=item *

The B<path> object constructor from L<Path::Tiny> and related types/coercions
from L<Types::Path::Tiny>

=item *

B<maybe> and B<provided> definedness-checking syntax sugar from L<PerlX::Maybe>

=item *

A B<define> keyword for defining constants based on L<PerlX::Define>

=item *

The B<|M|> match operator from L<match::simple>

=item *

The B<sswitch> and B<nswitch> switch/case constructs from L<Switch::Plain>

=item *

The B<qc>, B<qcw>, and B<qc_to> code-interpolating keywords from
L<Quote::Code> (as of Defaults::Modern C<v0.11.1>)

=item *

L<true>.pm so you can skip adding '1;' to all of your modules

=back

If you import the tag C<autobox_lists>, ARRAY and HASH type references are autoboxed
via L<List::Objects::WithUtils>:

  use Defaults::Modern 'autobox_lists';
  my $itr = [ 1 .. 10 ]->natatime(2);

L<Moo> version 2+ is depended upon in order to guarantee availability, but not
automatically imported:

  use Defaults::Modern;
  use Moo;
  use MooX::TypeTiny;   # recommended for faster inline type checks

  has foo => (
    is  => 'ro',
    isa => ArrayObj,
    coerce  => 1,
    default => sub { [] },
  );

If you're building classes, you may want to look into L<namespace::clean> /
L<namespace::sweep> or similar -- L<Defaults::Modern> imports an awful lot of
Stuff:

  use Defaults::Modern;
  use Moo;
  use namespace::clean;
  # ...

=head1 SEE ALSO

This package just glues together useful parts of CPAN, the
most visible portions of which come from the following modules:

L<Carp>

L<Function::Parameters>

L<List::Objects::WithUtils> and L<List::Objects::Types>

L<match::simple>

L<Path::Tiny>

L<PerlX::Maybe>

L<Quote::Code>

L<Scalar::Util>

L<Switch::Plain>

L<Try::Tiny>

L<Types::Standard>

L<Type::Tiny>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

Inspired by L<Defaults::Mauke> and L<Moops>.

The code backing the B<define> keyword is forked from TOBYINK's
L<PerlX::Define> to avoid the L<Moops> dependency and is copyright Toby
Inkster.

=cut

# vim: ts=2 sw=2 et sts=2 ft=perl
