
package Jojo::Role;
$Jojo::Role::VERSION = '0.5.0';
# ABSTRACT: Role::Tiny + lexical "with"
use 5.018;
use strict;
use warnings;
use utf8;
use feature      ();
use experimental ();

BEGIN {
  require Role::Tiny;
  Role::Tiny->VERSION('2.000006');
  our @ISA = qw(Role::Tiny);
}

use Sub::Inject 0.3.0 ();

# Aliasing of Role::Tiny symbols
BEGIN {
  *INFO           = \%Role::Tiny::INFO;
  *APPLIED_TO     = \%Role::Tiny::APPLIED_TO;
  *COMPOSED       = \%Role::Tiny::COMPOSED;
  *COMPOSITE_INFO = \%Role::Tiny::COMPOSITE_INFO;
  *ON_ROLE_CREATE = \@Role::Tiny::ON_ROLE_CREATE;

  *_getstash = \&Role::Tiny::_getstash;
}

our %INFO;
our %APPLIED_TO;
our %COMPOSED;
our %COMPOSITE_INFO;
our @ON_ROLE_CREATE;

our %EXPORT_TAGS;
our %EXPORT_GEN;


# Jojo::Role->apply_roles_to_package('Some::Package', qw(Some::Role +Other::Role));
sub apply_roles_to_package {
  my ($self, $target) = (shift, shift);
  return $self->Role::Tiny::apply_roles_to_package($target,
    map { /^\+(.+)$/ ? "${target}::Role::$1" : $_ } @_);
}

# Jojo::Role->create_class_with_roles('Some::Base', qw(Some::Role1 +Role2));
sub create_class_with_roles {
  my ($self, $target) = (shift, shift);
  return $self->Role::Tiny::create_class_with_roles($target,
    map { /^\+(.+)$/ ? "${target}::Role::$1" : $_ } @_);
}

sub import {
  my $target = caller;
  my $me     = shift;

  # Jojo modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.18');
  experimental->import('lexical_subs');

  my $flag = shift;
  if (!$flag) {
    $me->make_role($target);
    $flag = '-role';
  }

  my @exports = @{$EXPORT_TAGS{$flag} // []};
  @_ = $me->_generate_subs($target, @exports);
  goto &Sub::Inject::sub_inject;
}

sub role_provider { $_[0] }

sub make_role {
  my ($me, $target) = @_;
  return if $me->is_role($target);    # already exported into this package
  $INFO{$target}{is_role} = 1;

  # get symbol table reference
  my $stash = _getstash($target);

  # grab all *non-constant* (stash slot is not a scalarref) subs present
  # in the symbol table and store their refaddrs (no need to forcibly
  # inflate constant subs into real subs) with a map to the coderefs in
  # case of copying or re-use
  my @not_methods
    = map +(ref $_ eq 'CODE' ? $_ : ref $_ ? () : *$_{CODE} || ()),
    values %$stash;
  @{$INFO{$target}{not_methods} = {}}{@not_methods} = @not_methods;

  # a role does itself
  $APPLIED_TO{$target} = {$target => undef};
  foreach my $hook (@ON_ROLE_CREATE) {
    $hook->($target);
  }
  return;
}

BEGIN {
  %EXPORT_TAGS = (    #
    -role => [qw(after around before requires with)],
    -with => [qw(with)],
  );

  %EXPORT_GEN = (
    requires => sub {
      my (undef, $target) = @_;
      return sub {
        push @{$INFO{$target}{requires} ||= []}, @_;
        return;
      };
    },
    with => sub {
      my ($me, $target) = (shift->role_provider, shift);
      return sub {
        $me->apply_roles_to_package($target, @_);
        return;
      };
    },
  );

  # before/after/around
  foreach my $type (qw(before after around)) {
    $EXPORT_GEN{$type} = sub {
      my (undef, $target) = @_;
      return sub {
        push @{$INFO{$target}{modifiers} ||= []}, [$type => @_];
        return;
      };
    };
  }
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
#pod   package Some::Role {
#pod     use Jojo::Role;    # requires perl 5.18+
#pod
#pod     sub foo {...}
#pod     sub bar {...}
#pod     around baz => sub {...};
#pod   }
#pod
#pod   package Some::Class {
#pod     use Jojo::Role -with;
#pod     with 'Some::Role';
#pod
#pod     # bar gets imported, but not foo
#pod     sub foo {...}
#pod
#pod     # baz is wrapped in the around modifier by Class::Method::Modifiers
#pod     sub baz {...}
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Jojo::Role> works kind of like L<Role::Tiny> but C<with>, C<requires>,
#pod C<before>, C<after> and C<around> are exported
#pod as lexical subroutines.
#pod
#pod This is a companion to L<Jojo::Base>.
#pod
#pod L<Jojo::Role> may be used in two ways. First, to declare a role, which is done
#pod with
#pod
#pod     use Jojo::Base;
#pod     use Jojo::Base -role;    # Longer version
#pod
#pod Second, to compose one or more roles into a class, via
#pod
#pod     use Jojo::Base -with;
#pod
#pod =head1 IMPORTED SUBROUTINES: TAG C<-role>
#pod
#pod The C<-role> tag exports the following subroutines into the caller.
#pod
#pod =head2 after
#pod
#pod   after foo => sub { ... };
#pod
#pod Declares an
#pod L<< "after" | Class::Method::Modifiers/after method(s) => sub { ... } >>
#pod modifier to be applied to the named method at composition time.
#pod
#pod =head2 around
#pod
#pod   around => sub { ... };
#pod
#pod Declares an
#pod L<< "around" | Class::Method::Modifiers/around method(s) => sub { ... } >>
#pod modifier to be applied to the named method at composition time.
#pod
#pod =head2 before
#pod
#pod   before => sub { ... };
#pod
#pod Declares a
#pod L<< "before" | Class::Method::Modifiers/before method(s) => sub { ... } >>
#pod modifier to be applied to the named method at composition time.
#pod
#pod =head2 requires
#pod
#pod   requires qw(foo bar);
#pod
#pod Declares a list of methods that must be defined to compose the role.
#pod
#pod =head2 with
#pod
#pod   with 'Some::Role';
#pod
#pod   with 'Some::Role1', 'Some::Role2';
#pod
#pod Composes one or more roles into the current role.
#pod
#pod =head1 IMPORTED SUBROUTINES: TAG C<-with>
#pod
#pod The C<-with> tag exports the following subroutine into the caller.
#pod It is equivalent to using L<Role::Tiny::With>.
#pod
#pod =head2 with
#pod
#pod   with 'Some::Role1', 'Some::Role2';
#pod
#pod Composes one or more roles into the current class.
#pod
#pod =head1 METHODS
#pod
#pod L<Jojo::Role> inherits all methods from L<Role::Tiny> and implements the
#pod following new ones.
#pod
#pod =head2 apply_roles_to_package
#pod
#pod   Jojo::Role->apply_roles_to_package('Some::Package', qw(Some::Role +Other::Role));
#pod
#pod =head2 create_class_with_roles
#pod
#pod   Jojo::Role->create_class_with_roles('Some::Base', qw(Some::Role1 +Role2));
#pod
#pod =head2 import
#pod
#pod   Jojo::Role->import();
#pod   Jojo::Role->import(-role);
#pod   Jojo::Role->import(-with);
#pod
#pod =head2 make_role
#pod
#pod   Role::Tiny->make_role('Some::Package');
#pod
#pod Promotes a given package to a role.
#pod No subroutines are imported into C<'Some::Package'>.
#pod
#pod =head1 CAVEATS
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod L<Jojo::Role> requires perl 5.18 or newer
#pod
#pod =item *
#pod
#pod Because a lexical sub does not behave like a package import,
#pod some code may need to be enclosed in blocks to avoid warnings like
#pod
#pod     "state" subroutine &with masks earlier declaration in same scope at...
#pod
#pod =back
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Role::Tiny>, L<Jojo::Base>.
#pod
#pod =head1 ACKNOWLEDGMENTS
#pod
#pod Thanks to the authors of L<Role::Tiny>, which hold
#pod the copyright over the original code.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Jojo::Role - Role::Tiny + lexical "with"

=head1 VERSION

version 0.5.0

=head1 SYNOPSIS

  package Some::Role {
    use Jojo::Role;    # requires perl 5.18+

    sub foo {...}
    sub bar {...}
    around baz => sub {...};
  }

  package Some::Class {
    use Jojo::Role -with;
    with 'Some::Role';

    # bar gets imported, but not foo
    sub foo {...}

    # baz is wrapped in the around modifier by Class::Method::Modifiers
    sub baz {...}
  }

=head1 DESCRIPTION

L<Jojo::Role> works kind of like L<Role::Tiny> but C<with>, C<requires>,
C<before>, C<after> and C<around> are exported
as lexical subroutines.

This is a companion to L<Jojo::Base>.

L<Jojo::Role> may be used in two ways. First, to declare a role, which is done
with

    use Jojo::Base;
    use Jojo::Base -role;    # Longer version

Second, to compose one or more roles into a class, via

    use Jojo::Base -with;

=head1 IMPORTED SUBROUTINES: TAG C<-role>

The C<-role> tag exports the following subroutines into the caller.

=head2 after

  after foo => sub { ... };

Declares an
L<< "after" | Class::Method::Modifiers/after method(s) => sub { ... } >>
modifier to be applied to the named method at composition time.

=head2 around

  around => sub { ... };

Declares an
L<< "around" | Class::Method::Modifiers/around method(s) => sub { ... } >>
modifier to be applied to the named method at composition time.

=head2 before

  before => sub { ... };

Declares a
L<< "before" | Class::Method::Modifiers/before method(s) => sub { ... } >>
modifier to be applied to the named method at composition time.

=head2 requires

  requires qw(foo bar);

Declares a list of methods that must be defined to compose the role.

=head2 with

  with 'Some::Role';

  with 'Some::Role1', 'Some::Role2';

Composes one or more roles into the current role.

=head1 IMPORTED SUBROUTINES: TAG C<-with>

The C<-with> tag exports the following subroutine into the caller.
It is equivalent to using L<Role::Tiny::With>.

=head2 with

  with 'Some::Role1', 'Some::Role2';

Composes one or more roles into the current class.

=head1 METHODS

L<Jojo::Role> inherits all methods from L<Role::Tiny> and implements the
following new ones.

=head2 apply_roles_to_package

  Jojo::Role->apply_roles_to_package('Some::Package', qw(Some::Role +Other::Role));

=head2 create_class_with_roles

  Jojo::Role->create_class_with_roles('Some::Base', qw(Some::Role1 +Role2));

=head2 import

  Jojo::Role->import();
  Jojo::Role->import(-role);
  Jojo::Role->import(-with);

=head2 make_role

  Role::Tiny->make_role('Some::Package');

Promotes a given package to a role.
No subroutines are imported into C<'Some::Package'>.

=head1 CAVEATS

=over 4

=item *

L<Jojo::Role> requires perl 5.18 or newer

=item *

Because a lexical sub does not behave like a package import,
some code may need to be enclosed in blocks to avoid warnings like

    "state" subroutine &with masks earlier declaration in same scope at...

=back

=head1 SEE ALSO

L<Role::Tiny>, L<Jojo::Base>.

=head1 ACKNOWLEDGMENTS

Thanks to the authors of L<Role::Tiny>, which hold
the copyright over the original code.

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
