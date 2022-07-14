package Mars::Kind;

use 5.018;

use strict;
use warnings;

# VARIABLES

state $cache = {};

# METHODS

sub ARGS {
  my ($self, @args) = @_;

  return (!@args)
    ? ($self->DATA)
    : ((@args == 1 && ref($args[0]) eq 'HASH')
    ? (!%{$args[0]} ? $self->DATA : {%{$args[0]}})
    : (@args % 2 ? {@args, undef} : {@args}));
}

sub ATTR {
  my ($self, $attr, @args) = @_;

  no strict 'refs';
  no warnings 'redefine';

  *{"@{[$self->NAME]}::$attr"}
    = sub { local @_ = ($_[0], $attr, @_[1 .. $#_]); goto \&attr };

  $${"@{[$self->NAME]}::META"}{ATTR}{$attr} = [$attr, @args];

  return $self;
}

sub AUDIT {
  my ($self) = @_;

  return $self;
}

sub BASE {
  my ($self, $base) = @_;

  no strict 'refs';

  eval "require $base" if !$$cache{$base};

  @{"@{[$self->NAME]}::ISA"} = (
    $base, (grep +($_ ne $base), @{"@{[$self->NAME]}::ISA"})
  );

  $${"@{[$self->NAME]}::META"}{BASE}{$base} = [$base];

  return $self;
}

sub BLESS {
  my ($self, @args) = @_;

  my $data = $self->ARGS($self->BUILDARGS(@args));
  my $anew = bless($data, $self->NAME);

  $anew->BUILD($data);

  return $anew;
}

sub BUILD {
  my ($self, $data) = @_;

  return $self;
}

sub BUILDARGS {
  my ($self, @args) = @_;

  return (@args);
}

sub DATA {
  my ($self) = @_;

  return {};
}

sub DESTROY {
  my ($self) = @_;

  return $self;
}

sub DOES {
  my ($self, $role) = @_;

  return if !$role;

  return $self->META->role($role);
}

sub EXPORT {
  my ($self, $into) = @_;

  return [];
}

sub FROM {
  my ($self, $base) = @_;

  $self->BASE($base);

  $base->AUDIT($self->NAME) if $base->can('AUDIT');

  return $self;
}

sub IMPORT {
  my ($self, $into) = @_;

  return $self;
}

sub META {
  my ($self) = @_;

  no strict 'refs';

  require Mars::Meta;

  return Mars::Meta->new(name => $self->NAME);
}

sub NAME {
  my ($self) = @_;

  return ref $self || $self;
}

sub ROLE {
  my ($self, $role) = @_;

  eval "require $role" if !$$cache{$role};

  no warnings 'redefine';

  $role->IMPORT($self->NAME);

  no strict 'refs';

  $${"@{[$self->NAME]}::META"}{ROLE}{$role} = [$role];

  return $self;
}

sub SUBS {
  my ($self) = @_;

  no strict 'refs';

  return [
    sort grep *{"@{[$self->NAME]}::$_"}{"CODE"},
    grep /^[_a-zA-Z]\w*$/, keys %{"@{[$self->NAME]}::"}
  ];
}

sub TEST {
  my ($self, $role) = @_;

  $self->ROLE($role);

  $role->AUDIT($self->NAME) if $role->can('AUDIT');

  return $self;
}

sub attr {
  my ($self, $name, @args) = @_;

  return $self if !$name;
  return $self->{$name} if !int@args;
  return $self->{$name} = $args[0];
}

1;



=head1 NAME

Mars::Kind - Kind Base Class

=cut

=head1 ABSTRACT

Kind Base Class for Perl 5

=cut

=head1 SYNOPSIS

  package User;

  use base 'Mars::Kind';

  package main;

  my $user = User->BLESS(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')

  # i.e. BLESS is somewhat equivalent to writing

  # User->BUILD(bless(User->ARGS(User->BUILDARGS(@args) || User->DATA), 'User'))

=cut

=head1 DESCRIPTION

This package provides a base class for L<"class"|Mars::Kine::Class> and
L<"role"|Mars::Kind::Role> (kind) derived packages and provides class building,
object construction, and object deconstruction lifecycle hooks. The
L<Mars::Class> and L<Mars::Role> packages provide a simple DSL for automating
L<Mars::Kind> derived base classes.

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 args

  ARGS(Any @args) (HashRef)

The ARGS method is a object construction lifecycle hook which accepts a list of
arguments and returns a blessable data structure.

I<Since C<0.01>>

=over 4

=item ARGS example 1

  # given: synopsis

  package main;

  my $args = User->ARGS;

  # {}

=back

=over 4

=item ARGS example 2

  # given: synopsis

  package main;

  my $args = User->ARGS(name => 'Elliot');

  # {name => 'Elliot'}

=back

=over 4

=item ARGS example 3

  # given: synopsis

  package main;

  my $args = User->ARGS({name => 'Elliot'});

  # {name => 'Elliot'}

=back

=cut

=head2 attr

  ATTR(Str $name, Any @args) (Str | Object)

The ATTR method is a class building lifecycle hook which installs an attribute
accessors in the calling package.

I<Since C<0.01>>

=over 4

=item ATTR example 1

  package User;

  use base 'Mars::Kind';

  User->ATTR('name');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

  # $user->name;

  # ""

  # $user->name('Elliot');

  # "Elliot"

=back

=over 4

=item ATTR example 2

  package User;

  use base 'Mars::Kind';

  User->ATTR('role');

  package main;

  my $user = User->BLESS(role => 'Engineer');

  # bless({role => 'Engineer'}, 'User')

  # $user->role;

  # "Engineer"

  # $user->role('Hacker');

  # "Hacker"

=back

=cut

=head2 audit

  AUDIT(Str $role) (Str | Object)

The AUDIT method is a class building lifecycle hook which exist in roles and is
executed as a callback when the consuming class invokes the L</TEST> hook.

I<Since C<0.01>>

=over 4

=item AUDIT example 1

  package HasType;

  use base 'Mars::Kind';

  sub AUDIT {
    die 'Consumer missing "type" attribute' if !$_[1]->can('type');
  }

  package User;

  use base 'Mars::Kind';

  User->TEST('HasType');

  package main;

  my $user = User->BLESS;

  # Exception! Consumer missing "type" attribute

=back

=over 4

=item AUDIT example 2

  package HasType;

  sub AUDIT {
    die 'Consumer missing "type" attribute' if !$_[1]->can('type');
  }

  package User;

  use base 'Mars::Kind';

  User->ATTR('type');

  User->TEST('HasType');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=cut

=head2 base

  BASE(Str $name) (Str | Object)

The BASE method is a class building lifecycle hook which registers a base class
for the calling package. B<Note:> Unlike the L</FROM> hook, this hook doesn't
invoke the L</AUDIT> hook.

I<Since C<0.01>>

=over 4

=item BASE example 1

  package Entity;

  sub work {
    return;
  }

  package User;

  use base 'Mars::Kind';

  User->BASE('Entity');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=over 4

=item BASE example 2

  package Engineer;

  sub debug {
    return;
  }

  package Entity;

  sub work {
    return;
  }

  package User;

  use base 'Mars::Kind';

  User->BASE('Entity');

  User->BASE('Engineer');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=cut

=head2 bless

  BLESS(Any @args) (Object)

The BLESS method is an object construction lifecycle hook which returns an
instance of the calling package.

I<Since C<0.01>>

=over 4

=item BLESS example 1

  package User;

  use base 'Mars::Kind';

  package main;

  my $example = User->BLESS;

  # bless({}, 'User')

=back

=over 4

=item BLESS example 2

  package User;

  use base 'Mars::Kind';

  package main;

  my $example = User->BLESS(name => 'Elliot');

  # bless({name => 'Elliot'}, 'User')

=back

=over 4

=item BLESS example 3

  package User;

  use base 'Mars::Kind';

  package main;

  my $example = User->BLESS({name => 'Elliot'});

  # bless({name => 'Elliot'}, 'User')

=back

=cut

=head2 build

  BUILD(HashRef $data) (Object)

The BUILD method is an object construction lifecycle hook which receives an
object and the data structure that was blessed, and should return an object
although its return value is ignored by the L</BLESS> hook.

I<Since C<0.01>>

=over 4

=item BUILD example 1

  package User;

  use base 'Mars::Kind';

  sub BUILD {
    my ($self) = @_;

    $self->{name} = 'Mr. Robot';

    return $self;
  }

  package main;

  my $example = User->BLESS(name => 'Elliot');

  # bless({name => 'Mr. Robot'}, 'User')

=back

=over 4

=item BUILD example 2

  package User;

  use base 'Mars::Kind';

  sub BUILD {
    my ($self) = @_;

    $self->{name} = 'Mr. Robot';

    return $self;
  }

  package Elliot;

  use base 'User';

  sub BUILD {
    my ($self, $data) = @_;

    $self->SUPER::BUILD($data);

    $self->{name} = 'Elliot';

    return $self;
  }

  package main;

  my $elliot = Elliot->BLESS;

  # bless({name => 'Elliot'}, 'Elliot')

=back

=cut

=head2 buildargs

  BUILDARGS(Any @args) (Any @args | HashRef $data)

The BUILDARGS method is an object construction lifecycle hook which receives
the arguments provided to the constructor (unaltered) and should return a list
of arguments, a hashref, or key/value pairs.

I<Since C<0.01>>

=over 4

=item BUILDARGS example 1

  package User;

  use base 'Mars::Kind';

  sub BUILD {
    my ($self) = @_;

    return $self;
  }

  sub BUILDARGS {
    my ($self, @args) = @_;

    my $data = @args == 1 && !ref $args[0] ? {name => $args[0]} : {};

    return $data;
  }

  package main;

  my $user = User->BLESS('Elliot');

  # bless({name => 'Elliot'}, 'User')

=back

=cut

=head2 data

  DATA() (Ref)

The DATA method is an object construction lifecycle hook which returns the
default data structure reference to be blessed when no arguments are provided
to the constructor. The default data structure is an empty hashref.

I<Since C<0.01>>

=over 4

=item DATA example 1

  package Example;

  use base 'Mars::Kind';

  sub DATA {
    return [];
  }

  package main;

  my $example = Example->BLESS;

  # bless([], 'Example')

=back

=over 4

=item DATA example 2

  package Example;

  use base 'Mars::Kind';

  sub DATA {
    return {};
  }

  package main;

  my $example = Example->BLESS;

  # bless({}, 'Example')

=back

=cut

=head2 destroy

  DESTROY() (Any)

The DESTROY method is an object destruction lifecycle hook which is called when
the last reference to the object goes away.

I<Since C<0.01>>

=over 4

=item DESTROY example 1

  package User;

  use base 'Mars::Kind';

  our $USERS = 0;

  sub BUILD {
    return $USERS++;
  }

  sub DESTROY {
    return $USERS--;
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');

  undef $user;

  # 1

=back

=cut

=head2 does

  DOES(Str $name) (Bool)

The DOES method returns true or false if the invocant consumed the role or
interface provided.

I<Since C<0.01>>

=over 4

=item DOES example 1

  package Admin;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  sub BUILD {
    return;
  }

  sub BUILDARGS {
    return;
  }

  package main;

  my $admin = User->DOES('Admin');

  # 1

=back

=over 4

=item DOES example 2

  package Admin;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  sub BUILD {
    return;
  }

  sub BUILDARGS {
    return;
  }

  package main;

  my $is_owner = User->DOES('Owner');

  # 0

=back

=cut

=head2 export

  EXPORT(Any @args) (ArrayRef)

The EXPORT method is a class building lifecycle hook which returns an arrayref
of routine names to be automatically imported by the calling package whenever
the L</ROLE> or L</TEST> hooks are used.

I<Since C<0.01>>

=over 4

=item EXPORT example 1

  package Admin;

  use base 'Mars::Kind';

  sub shutdown {
    return;
  }

  sub EXPORT {
    ['shutdown']
  }

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=cut

=head2 from

  FROM(Str $name) (Str | Object)

The FROM method is a class building lifecycle hook which registers a base class
for the calling package, automatically invoking the L</AUDIT> hook on the base
class.

I<Since C<0.03>>

=over 4

=item FROM example 1

  package Entity;

  use base 'Mars::Kind';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package User;

  use base 'Mars::Kind';

  User->ATTR('startup');
  User->ATTR('shutdown');

  User->FROM('Entity');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=over 4

=item FROM example 2

  package Entity;

  use base 'Mars::Kind';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package User;

  use base 'Mars::Kind';

  User->FROM('Entity');

  sub startup {
    return;
  }

  sub shutdown {
    return;
  }

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=cut

=head2 import

  IMPORT(Str $into, Any @args) (Str | Object)

The IMPORT method is a class building lifecycle hook which dispatches the
L</EXPORT> lifecycle hook whenever the L</ROLE> or L</TEST> hooks are used.

I<Since C<0.01>>

=over 4

=item IMPORT example 1

  package Admin;

  use base 'Mars::Kind';

  our $USES = 0;

  sub shutdown {
    return;
  }

  sub EXPORT {
    ['shutdown']
  }

  sub IMPORT {
    my ($self, $into) = @_;

    $self->SUPER::IMPORT($into);

    $USES++;

    return $self;
  }

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

=back

=cut

=head2 meta

  META() (Meta)

The META method return a L<Mars::Meta> object which describes the invocant's
configuration.

I<Since C<0.01>>

=over 4

=item META example 1

  package User;

  use base 'Mars::Kind';

  package main;

  my $meta = User->META;

  # bless({name => 'User'}, 'Mars::Meta')

=back

=cut

=head2 name

  NAME() (Str)

The NAME method is a class building lifecycle hook which returns the name of
the package.

I<Since C<0.01>>

=over 4

=item NAME example 1

  package User;

  use base 'Mars::Kind';

  package main;

  my $name = User->NAME;

  # "User"

=back

=over 4

=item NAME example 2

  package User;

  use base 'Mars::Kind';

  package main;

  my $name = User->BLESS->NAME;

  # "User"

=back

=cut

=head2 role

  ROLE(Str $name) (Str | Object)

The ROLE method is a class building lifecycle hook which consumes the role
provided, automatically invoking the role's L</IMPORT> hook. B<Note:> Unlike
the L</TEST> and L</WITH> hooks, this hook doesn't invoke the L</AUDIT> hook.

I<Since C<0.01>>

=over 4

=item ROLE example 1

  package Admin;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  package main;

  my $admin = User->DOES('Admin');

  # 1

=back

=over 4

=item ROLE example 2

  package Create;

  use base 'Mars::Kind';

  package Delete;

  use base 'Mars::Kind';

  package Manage;

  use base 'Mars::Kind';

  Manage->ROLE('Create');
  Manage->ROLE('Delete');

  package User;

  use base 'Mars::Kind';

  User->ROLE('Manage');

  package main;

  my $create = User->DOES('Create');

  # 1

=back

=cut

=head2 subs

  SUBS() (ArrayRef)

The SUBS method returns the routines defined on the package and consumed from
roles, but not inherited by superclasses.

I<Since C<0.01>>

=over 4

=item SUBS example 1

  package Example;

  use base 'Mars::Kind';

  package main;

  my $subs = Example->SUBS;

  # [...]

=back

=cut

=head2 test

  TEST(Str $name) (Str | Object)

The TEST method is a class building lifecycle hook which consumes the role
provided, automatically invoking the role's L</IMPORT> hook as well as the
L</AUDIT> hook if defined.

I<Since C<0.01>>

=over 4

=item TEST example 1

  package Admin;

  use base 'Mars::Kind';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  sub AUDIT_BUILD {
    my ($self, $data) = @_;
    die "Attribute 'startup' can't be undefined" if !$self->startup;
    die "Attribute 'shutdown' can't be undefined" if !$self->shutdown;
  }

  package User;

  use base 'Mars::Kind';

  User->ATTR('startup');
  User->ATTR('shutdown');

  User->TEST('Admin');

  sub BUILD {
    my ($self, $data) = @_;
    # Using AUDIT_BUILD as a callback
    $self->Admin::AUDIT_BUILD($data);
  }

  package main;

  my $user = User->BLESS(startup => 'hello');

  # Exception! Attribute 'shutdown' can't be undefined

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut