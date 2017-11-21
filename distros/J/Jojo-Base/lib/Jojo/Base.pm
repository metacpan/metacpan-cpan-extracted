
package Jojo::Base;
$Jojo::Base::VERSION = '0.6.0';
# ABSTRACT: Mojo::Base + lexical "has"
use 5.018;
use strict;
use warnings;
use utf8;
use feature      ();
use experimental ();

BEGIN {
  require Mojo::Base;
  our @ISA = qw(Mojo::Base);
}

use Carp       ();
use Mojo::Util ();
use Sub::Inject 0.2.0 ();

use constant ROLES =>
  !!(eval { require Jojo::Role; Jojo::Role->VERSION('0.4.0'); 1 });

use constant SIGNATURES => ($] >= 5.020);

our %EXPORT_TAGS;
our %EXPORT_GEN;

sub import {
  my $class = shift;
  return unless my $flag = shift;
  my $caller = caller;

  # Base
  my $base;
  if ($flag eq '-base') { $base = $class }

  # Strict
  elsif ($flag eq '-strict') { }

  # Role
  elsif ($flag eq '-role') {
    Carp::croak 'Jojo::Role 0.4.0+ is required for roles' unless ROLES;
    Jojo::Role->_become_role($caller);
  }

  # Module
  elsif (($base = $flag) && ($flag = '-base') && !$base->can('new')) {
    require(Mojo::Util::class_to_path($base));
  }

  # Jojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.18');
  experimental->import('lexical_subs');

  # Signatures (Perl 5.20+)
  if ((shift || '') eq '-signatures') {
    Carp::croak 'Subroutine signatures require Perl 5.20+' unless SIGNATURES;
    experimental->import('signatures');
  }

  # ISA
  if ($base) {
    no strict 'refs';
    push @{"${caller}::ISA"}, $base;
  }

  my @exports = @{$EXPORT_TAGS{$flag} // []};
  if (@exports) {
    @_ = $class->_generate_subs($caller, @exports);
    goto &Sub::Inject::sub_inject;
  }
}

sub role_provider {'Jojo::Role'}

sub with_roles {
  Carp::croak 'Jojo::Role 0.4.0+ is required for roles' unless ROLES;
  my ($self, @roles) = @_;

  return Jojo::Role->create_class_with_roles($self, @roles)
    unless my $class = Scalar::Util::blessed $self;

  return Jojo::Role->apply_roles_to_object($self, @roles);
}

BEGIN {
  %EXPORT_TAGS = (-base => [qw(has with)], -role => [qw(has)], -strict => [],);

  %EXPORT_GEN = (
    has => sub {
      my (undef, $target) = @_;
      return sub { Mojo::Base::attr($target, @_) }
    },
    with => sub {    # dummy
      return sub { Carp::croak 'Jojo::Role 0.4.0+ is required for roles' }
    },
  );

  return unless ROLES;

  push @{$EXPORT_TAGS{-role}}, @{$Jojo::Role::EXPORT_TAGS{-role}};

  $EXPORT_GEN{$_} = $Jojo::Role::EXPORT_GEN{$_}
    for @{$Jojo::Role::EXPORT_TAGS{-role}};
}

sub _generate_subs {
  my ($class, $target) = (shift, shift);
  return map { my $cb = $EXPORT_GEN{$_}; $_ => $class->$cb($target) } @_;
}

1;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod   package Cat {
#pod     use Jojo::Base -base;    # requires perl 5.18+
#pod
#pod     has name => 'Nyan';
#pod     has ['age', 'weight'] => 4;
#pod   }
#pod
#pod   package Tiger {
#pod     use Jojo::Base 'Cat';
#pod
#pod     has friend => sub { Cat->new };
#pod     has stripes => 42;
#pod   }
#pod
#pod   package main;
#pod   use Jojo::Base -strict;
#pod
#pod   my $mew = Cat->new(name => 'Longcat');
#pod   say $mew->age;
#pod   say $mew->age(3)->weight(5)->age;
#pod
#pod   my $rawr = Tiger->new(stripes => 38, weight => 250);
#pod   say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Jojo::Base> works kind of like L<Mojo::Base> but C<has> is imported
#pod as lexical subroutine.
#pod
#pod L<Jojo::Base>, like L<Mojo::Base>, is a simple base class designed
#pod to be effortless and powerful.
#pod
#pod   # Enables "strict", "warnings", "utf8" and Perl 5.18 and "lexical_subs" features
#pod   use Jojo::Base -strict;
#pod   use Jojo::Base -base;
#pod   use Jojo::Base 'SomeBaseClass';
#pod   use Jojo::Base -role;
#pod
#pod All four forms save a lot of typing. Note that role support depends on
#pod L<Jojo::Role> (0.4.0+).
#pod
#pod   # use Jojo::Base -strict;
#pod   use strict;
#pod   use warnings;
#pod   use utf8;
#pod   use feature ':5.18';
#pod   use experimental 'lexical_subs';
#pod   use IO::Handle ();
#pod
#pod   # use Jojo::Base -base;
#pod   use strict;
#pod   use warnings;
#pod   use utf8;
#pod   use feature ':5.18';
#pod   use experimental 'lexical_subs';
#pod   use IO::Handle ();
#pod   push @ISA, 'Jojo::Base';
#pod   state sub has { ... }    # attributes
#pod   state sub with { ... }   # role composition
#pod
#pod   # use Jojo::Base 'SomeBaseClass';
#pod   use strict;
#pod   use warnings;
#pod   use utf8;
#pod   use feature ':5.18';
#pod   use experimental 'lexical_subs';
#pod   use IO::Handle ();
#pod   require SomeBaseClass;
#pod   push @ISA, 'SomeBaseClass';
#pod   state sub has { ... }    # attributes
#pod   state sub with { ... }   # role composition
#pod
#pod   # use Jojo::Base -role;
#pod   use strict;
#pod   use warnings;
#pod   use utf8;
#pod   use feature ':5.18';
#pod   use experimental 'lexical_subs';
#pod   use IO::Handle ();
#pod   use Jojo::Role;
#pod   state sub has { ... }    # attributes
#pod
#pod On Perl 5.20+ you can also append a C<-signatures> flag to all four forms and
#pod enable support for L<subroutine signatures|perlsub/"Signatures">.
#pod
#pod   # Also enable signatures
#pod   use Jojo::Base -strict, -signatures;
#pod   use Jojo::Base -base, -signatures;
#pod   use Jojo::Base 'SomeBaseClass', -signatures;
#pod   use Jojo::Base -role, -signatures;
#pod
#pod This will also disable experimental warnings on versions of Perl where this
#pod feature was still experimental.
#pod
#pod =head2 DIFFERENCES FROM C<Mojo::Base>
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod All functions are exported as lexical subs
#pod
#pod =item *
#pod
#pod Role support depends on L<Jojo::Role> instead of L<Role::Tiny>
#pod
#pod =item *
#pod
#pod C<with> is exported alongside C<has> (when L<Jojo::Role> is available)
#pod
#pod =item *
#pod
#pod Feature bundle for Perl 5.18 is enabled by default, instead of 5.10
#pod
#pod =item *
#pod
#pod Support for L<lexical subroutines|perlsub/"Lexical Subroutines"> is enabled
#pod by default
#pod
#pod =back
#pod
#pod =head1 FUNCTIONS
#pod
#pod L<Jojo::Base> implements the following functions, which can be imported with
#pod the C<-base> flag, or by setting a base class.
#pod
#pod =head2 has
#pod
#pod   has 'name';
#pod   has ['name1', 'name2', 'name3'];
#pod   has name => 'foo';
#pod   has name => sub {...};
#pod   has ['name1', 'name2', 'name3'] => 'foo';
#pod   has ['name1', 'name2', 'name3'] => sub {...};
#pod
#pod Create attributes for hash-based objects, just like the L<Mojo::Base/"attr"> method.
#pod
#pod =head2 with
#pod
#pod   with 'SubClass::Role::One';
#pod   with '+One', '+Two';
#pod
#pod Composes the current package with one or more L<Jojo::Role> roles.
#pod For roles following the naming scheme C<MyClass::Role::RoleName> you
#pod can use the shorthand C<+RoleName>. Note that role support depends on
#pod L<Jojo::Role> (0.4.0+).
#pod
#pod It works with L<Jojo::Role> or L<Role::Tiny> roles.
#pod
#pod =head1 METHODS
#pod
#pod L<Jojo::Base> inherits all methods from L<Mojo::Base> and implements
#pod the following new ones.
#pod
#pod =head2 with_roles
#pod
#pod   my $new_class = SubClass->with_roles('SubClass::Role::One');
#pod   my $new_class = SubClass->with_roles('+One', '+Two');
#pod   $object       = $object->with_roles('+One', '+Two');
#pod
#pod Create a new class with one or more roles. If called on a class
#pod returns the new class, or if called on an object reblesses the object into the
#pod new class. For roles following the naming scheme C<MyClass::Role::RoleName> you
#pod can use the shorthand C<+RoleName>. Note that role support depends on
#pod L<Jojo::Role> (0.4.0+).
#pod
#pod   # Create a new class with the role "SubClass::Role::Foo" and instantiate it
#pod   my $new_class = SubClass->with_roles('+Foo');
#pod   my $object    = $new_class->new;
#pod
#pod It works with L<Jojo::Role> or L<Role::Tiny> roles.
#pod
#pod =head1 CAVEATS
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod L<Jojo::Base> requires perl 5.18 or newer
#pod
#pod =item *
#pod
#pod Because a lexical sub does not behave like a package import,
#pod some code may need to be enclosed in blocks to avoid warnings like
#pod
#pod     "state" subroutine &has masks earlier declaration in same scope at...
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojo::Base>, L<Jojo::Role>.
#pod
#pod =head1 ACKNOWLEDGMENTS
#pod
#pod Thanks to Sebastian Riedel and others, the authors
#pod and copyright holders of L<Mojo::Base>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Jojo::Base - Mojo::Base + lexical "has"

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

  package Cat {
    use Jojo::Base -base;    # requires perl 5.18+

    has name => 'Nyan';
    has ['age', 'weight'] => 4;
  }

  package Tiger {
    use Jojo::Base 'Cat';

    has friend => sub { Cat->new };
    has stripes => 42;
  }

  package main;
  use Jojo::Base -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

  my $rawr = Tiger->new(stripes => 38, weight => 250);
  say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

=head1 DESCRIPTION

L<Jojo::Base> works kind of like L<Mojo::Base> but C<has> is imported
as lexical subroutine.

L<Jojo::Base>, like L<Mojo::Base>, is a simple base class designed
to be effortless and powerful.

  # Enables "strict", "warnings", "utf8" and Perl 5.18 and "lexical_subs" features
  use Jojo::Base -strict;
  use Jojo::Base -base;
  use Jojo::Base 'SomeBaseClass';
  use Jojo::Base -role;

All four forms save a lot of typing. Note that role support depends on
L<Jojo::Role> (0.4.0+).

  # use Jojo::Base -strict;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();

  # use Jojo::Base -base;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();
  push @ISA, 'Jojo::Base';
  state sub has { ... }    # attributes
  state sub with { ... }   # role composition

  # use Jojo::Base 'SomeBaseClass';
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();
  require SomeBaseClass;
  push @ISA, 'SomeBaseClass';
  state sub has { ... }    # attributes
  state sub with { ... }   # role composition

  # use Jojo::Base -role;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.18';
  use experimental 'lexical_subs';
  use IO::Handle ();
  use Jojo::Role;
  state sub has { ... }    # attributes

On Perl 5.20+ you can also append a C<-signatures> flag to all four forms and
enable support for L<subroutine signatures|perlsub/"Signatures">.

  # Also enable signatures
  use Jojo::Base -strict, -signatures;
  use Jojo::Base -base, -signatures;
  use Jojo::Base 'SomeBaseClass', -signatures;
  use Jojo::Base -role, -signatures;

This will also disable experimental warnings on versions of Perl where this
feature was still experimental.

=head2 DIFFERENCES FROM C<Mojo::Base>

=over 4

=item *

All functions are exported as lexical subs

=item *

Role support depends on L<Jojo::Role> instead of L<Role::Tiny>

=item *

C<with> is exported alongside C<has> (when L<Jojo::Role> is available)

=item *

Feature bundle for Perl 5.18 is enabled by default, instead of 5.10

=item *

Support for L<lexical subroutines|perlsub/"Lexical Subroutines"> is enabled
by default

=back

=head1 FUNCTIONS

L<Jojo::Base> implements the following functions, which can be imported with
the C<-base> flag, or by setting a base class.

=head2 has

  has 'name';
  has ['name1', 'name2', 'name3'];
  has name => 'foo';
  has name => sub {...};
  has ['name1', 'name2', 'name3'] => 'foo';
  has ['name1', 'name2', 'name3'] => sub {...};

Create attributes for hash-based objects, just like the L<Mojo::Base/"attr"> method.

=head2 with

  with 'SubClass::Role::One';
  with '+One', '+Two';

Composes the current package with one or more L<Jojo::Role> roles.
For roles following the naming scheme C<MyClass::Role::RoleName> you
can use the shorthand C<+RoleName>. Note that role support depends on
L<Jojo::Role> (0.4.0+).

It works with L<Jojo::Role> or L<Role::Tiny> roles.

=head1 METHODS

L<Jojo::Base> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head2 with_roles

  my $new_class = SubClass->with_roles('SubClass::Role::One');
  my $new_class = SubClass->with_roles('+One', '+Two');
  $object       = $object->with_roles('+One', '+Two');

Create a new class with one or more roles. If called on a class
returns the new class, or if called on an object reblesses the object into the
new class. For roles following the naming scheme C<MyClass::Role::RoleName> you
can use the shorthand C<+RoleName>. Note that role support depends on
L<Jojo::Role> (0.4.0+).

  # Create a new class with the role "SubClass::Role::Foo" and instantiate it
  my $new_class = SubClass->with_roles('+Foo');
  my $object    = $new_class->new;

It works with L<Jojo::Role> or L<Role::Tiny> roles.

=head1 CAVEATS

=over 4

=item *

L<Jojo::Base> requires perl 5.18 or newer

=item *

Because a lexical sub does not behave like a package import,
some code may need to be enclosed in blocks to avoid warnings like

    "state" subroutine &has masks earlier declaration in same scope at...

=back

=head1 SEE ALSO

L<Mojo::Base>, L<Jojo::Role>.

=head1 ACKNOWLEDGMENTS

Thanks to Sebastian Riedel and others, the authors
and copyright holders of L<Mojo::Base>.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Adriano Ferreira.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
