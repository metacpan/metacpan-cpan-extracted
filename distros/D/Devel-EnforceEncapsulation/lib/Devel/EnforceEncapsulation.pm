#######################################################################
#      $URL: svn+ssh://equilibrious@equilibrious.net/home/equilibrious/Mirror/medialandscape/repos/clotho/Devel-EnforceEncapsulation/lib/Devel/EnforceEncapsulation.pm $
#     $Date: 2014-03-27 18:57:41 -0500 (Thu, 27 Mar 2014) $
#   $Author: equilibrious $
# $Revision: 3356 $
########################################################################

package Devel::EnforceEncapsulation;

use warnings;
use strict;
use English qw(-no_match_vars);
use Carp;
use overload;

our $VERSION = '0.51';

sub apply_to {
   my $pkg      = shift;
   my $dest_pkg = shift;
   my $opts     = shift || {};

   $opts->{policy} ||= 'croak';
   if (!eval { $pkg->can('_deref_overload_' . $opts->{policy}) }) {
      croak "Unknown encapsulation policy '$opts->{policy}'";
   }

   ## no critic(ProhibitStringyEval,RequireCarping)
   my $fn = __PACKAGE__ . '::_deref_overload_' . $opts->{policy};
   my $overloads = join q{,}, map { "'$_' => \\&$fn" } $pkg->_ops;
   eval "{package $dest_pkg; use overload $overloads, fallback => 1;}";
   die $EVAL_ERROR if $EVAL_ERROR;
   return;
}

sub remove_from {
   my $pkg      = shift;
   my $dest_pkg = shift;

   ## no critic(ProhibitStringyEval,RequireCarping)
   my $overloads = join q{,}, map { "'$_'" } $pkg->_ops;
   eval "{package $dest_pkg; no overload $overloads, 'fallback';}";
   die $EVAL_ERROR if $EVAL_ERROR;
   return;
}

## possible callbacks to be installed via overload ##

sub _deref_overload_croak {
   my $self = shift;

   my $caller_pkg = caller;
   if (!$self->isa($caller_pkg)) {
      my $pkg = ref $self;
      croak "Illegal attempt to access $pkg internals from $caller_pkg";
   }
   return $self;
}

sub _deref_overload_carp {
   my $self = shift;

   my $caller_pkg = caller;
   if (!$self->isa($caller_pkg)) {
      my $pkg = ref $self;
      carp "Illegal attempt to access $pkg internals from $caller_pkg";
   }
   return $self;
}

# get a list of overloadable derefs ('%{}', '@{}', '${}', ...)
sub _ops {
   my $pkg = shift;

   ## no critic(ProhibitPackageVars)
   return split m/\s/xms, $overload::ops{dereferencing};
}

1;

__END__

=pod

=for stopwords  perlmonks.org  ben Jore  Signes

=head1 NAME

Devel::EnforceEncapsulation - Find access violations to blessed objects

=head1 SYNOPSIS

  package BankAccount;
  sub new {
     my $pkg = shift;
     return bless {}, $pkg;
  }
  sub balance {
     my $self = shift;
     return $self->{balance};
  }
  # ... etc. ...
  
  package main;
  Devel::EnforceEncapsulation->apply_to('BankAccount');
  my $acct = BankAccount->new();
  print $acct->balance(),"\n";  # ok
  print $acct->{balance},"\n";  # dies

=head1 LICENSE

Copyright 2014 Chris Dolan, <cpan@chrisdolan.net>
Copyright 2006 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

Encapsulation is the practice of creating subroutines to access the
properties of a class instead of accessing those properties directly.
The advantage of good encapsulation is that the author is permitted to
change the internal implementation of a class without breaking its
usage.

Object-oriented programming in Perl is most commonly implemented via
blessed hashes.  This practice makes it easy for users of a class to
violate encapsulation by simply accessing the hash values directly.
Although less common, the same applies to classes implemented via
blessed arrays, scalars, filehandles, etc.

This module is a hack to block those direct accesses.  If you try to
access a hash value of an object from it's own class, or a superclass
or subclass, all goes well.  If you try to access a hash value from
any other package, an exception is thrown.  The same applies to the
scalar value of a blessed scalar, entry in a blessed array, etc.

To be clear: this class is NOT intended for strict enforcement of
encapsulation.  If you want bullet-proof encapsulation, use inside-out
objects or the like.  Instead, this module is intended to be a
development or debugging aid in catching places where direct access is
used against classes implemented as blessed hashes.

To repeat: the encapsulation enforced here is a hack and is easily
circumvented.  Please use this module for good (finding bugs), not
evil (making life harder for downstream developers).

=head1 METHODS

=over

=item $pkg->apply_to($other_pkg);

=item $pkg->apply_to($other_pkg, {policy => 'carp'});

Add strict encapsulation to an existing C<$other_pkg>.  The encapsulation
changes only apply to instances created after the call.

The optional C<policy> argument allows you to change the response to an
illegal access.  By default the policy is C<croak>, which invokes
C<Carp::croak()>.  The alternative is C<carp> which invokes C<Carp::carp()>
instead.

=item $pkg->remove_from($other_pkg);

Remove any encapsulation previously set by C<apply_to()>.  This does not
affect instances created before this call.

=back

=head1 SEE ALSO

=head2 L<Class::Privacy>

Class::Privacy is a very similar implementation that is, in general, stricter
than this module.  The key differences:

=over

=item * D::E applies externally post-facto; C::P from inside the code.

=item * D::E allows access from sub/superclasses; C::P does not (deliberately!).

=item * D::E supports all dereferencers from overload.pm; C::P supports C<%>, C<@>, C<$>, and C<&>.

=item * D::E allows access from anything in the same package; C::P allows access only from matching package AND file.

=back

=head2 Inside-out classes

L<Class::InsideOut>, L<Object::InsideOut> and L<Class::Std> are all
implementations of "inside-out" objects, which offer a stricter
encapsulation style at the expense of a less familiar coding style.

=head1 DIAGNOSTICS

=over

=item "Illegal attempt to access %s internals from %s"

(Fatal) You tried to access a hash property directly instead of via an
accessor method.  The C<%s> values are the object and caller packages
respectively.

=back

=head1 QUALITY

We care about code quality.  This distribution complies with
the following quality metrics:

=over

=item * Perl::Critic v0.20 passes

=item * Devel::Cover test coverage at 100%

=item * Pod::Coverage at 100%

=item * Test::Spelling passes

=item * Test::Portability::Files passes

=item * Test::Kwalitee passes

=back

=head1 CAVEATS

The regression tests do not cover blessed code or glob references.

Any other issues: L<http://rt.cpan.org/Dist/Display.html?Queue=Devel-EnforceEncapsulation>

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Maintainer: Chris Dolan

=head1 CREDITS

This idea, and the original source code, came from Adrian Howard via
Curtis "Ovid" Poe on
L<http://www.perlmonks.org/?node_id=576707|perlmonks.org>.  Adrian has
authorized me to release a variant of his code under the Perl license.

Joshua ben Jore provided crucial improvements that simplified yet generalized
the implementation.  This module would not be half as useful without his
contributions.  L<http://use.perl.org/comments.pl?sid=33253&cid=50863>

Ricardo Signes contributed the C<{policy => 'carp'}> feature (with tests!).
L<http://rt.cpan.org/Ticket/Display.html?id=22024>

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 3
#   fill-column: 78
# End:
# vim: expandtab shiftwidth=3:
