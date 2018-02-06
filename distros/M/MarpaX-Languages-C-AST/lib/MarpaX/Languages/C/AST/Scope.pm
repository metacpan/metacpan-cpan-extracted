use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Scope;
use MarpaX::Languages::C::AST::Util qw/whoami/;

# ABSTRACT: Scope management when translating a C source to an AST

use Log::Any qw/$log/;
use Carp qw/croak/;

our $VERSION = '0.48'; # VERSION


sub new {
  my ($class) = @_;

  my $self  = {
      _nscope => 0,
      _typedefPerScope => [ {} ],
      _enumAnyScope => {},
      _delay => [],
      _enterScopeCallback => [],
      _exitScopeCallback => [],
  };
  bless($self, $class);

  return $self;
}


sub typedefPerScope {
  my ($self) = @_;

  return $self->{_typedefPerScope};
}


sub enumAnyScope {
  my ($self) = @_;

  return $self->{_enumAnyScope};
}


sub parseEnterScope {
  my ($self) = @_;

  # $self->condExitScope();

  if ($log->is_debug) {
      $log->debugf('[%s] Duplicating scope %d to %d', whoami(__PACKAGE__), $self->{_nscope}, $self->{_nscope} + 1);
  }
  #
  # calling Clone::clone is overhead for us:
  # - user data associated to a typedef is assumed to never be modified: copying the $data itself (i.e. usually a reference) is enough
  # - We just want to make sure this is a new hash, the values inside the hash can remain identical
  #
  # Doing \%{$...} is just to make sure this is a new hash instance, with keys pointing to the same values as the origin
  #
  push(@{$self->{_typedefPerScope}}, \%{$self->{_typedefPerScope}->[$self->{_nscope}]});
  push(@{$self->{_delay}}, 0);
  $self->{_nscope}++;

  if (@{$self->{_enterScopeCallback}}) {
      my ($ref, @args) = @{$self->{_enterScopeCallback}};
      &$ref(@args);
  }

}


sub parseDelay {
  my $self = shift;
  if (@_) {
    my $value = shift;
    if ($log->is_debug) {
        $log->debugf('[%s] Setting delay flag to %d at scope %d', whoami(__PACKAGE__), $value, $self->{_nscope});
    }
    $self->{_delay}->[-1] = $value;
  }
  return $self->{_delay}->[-1];
}


sub parseScopeLevel {
  my ($self) = @_;

  return $self->{_nscope};
}


sub parseEnterScopeCallback {
  my ($self, $ref, @args) = @_;

  $self->{_enterScopeCallback} = [ $ref, @args ];
}


sub parseExitScopeCallback {
  my ($self, $ref, @args) = @_;

  $self->{_exitScopeCallback} = [ $ref, @args ];
}


sub parseExitScope {
  my ($self, $now) = @_;
  $now //= 0;

  if ($now) {
    $self->doExitScope();
  } else {
    $self->parseDelay(1);
  }
}


sub parseReenterScope {
  my ($self) = @_;

  if ($log->is_debug) {
      $log->debugf('[%s] Reenter scope at scope %d', whoami(__PACKAGE__), $self->{_nscope});
  }
  $self->parseDelay(0);

}


sub condExitScope {
  my ($self) = @_;

  if ($self->parseDelay) {
    $self->doExitScope();
  }
}


sub doExitScope {
  my ($self) = @_;

  if ($log->is_debug) {
      $log->debugf('[%s] Removing scope %d', whoami(__PACKAGE__), $self->{_nscope});
  }
  pop(@{$self->{_typedefPerScope}});
  pop(@{$self->{_delay}});
  $self->{_nscope}--;

  if (@{$self->{_exitScopeCallback}}) {
      my ($ref, @args) = @{$self->{_exitScopeCallback}};
      &$ref(@args);
  }

  if ($self->{_nscope} > 0) {
    #
    # If the parent scope was marked delayed, we close it as well:
    #
    if ($self->parseDelay) {
      if ($log->is_debug) {
        $log->debugf('[%s] Parent scope has delay flag on', whoami(__PACKAGE__));
      }
      $self->doExitScope;
    } else {
      $self->parseDelay(0);
    }
  }
}


sub parseEnterTypedef {
  my ($self, $token, $data) = @_;

  $data //= 1;

  $self->{_typedefPerScope}->[$self->{_nscope}]->{$token} = $data;

  if ($log->is_debug) {
      $log->debugf('[%s] "%s" typedef entered at scope %d', whoami(__PACKAGE__), $token, $self->{_nscope});
  }
}


sub parseEnterEnum {
  my ($self, $token, $data) = @_;

  $data //= 1;

  $self->{_enumAnyScope}->{$token} = $data;
  if ($log->is_debug) {
      $log->debugf('[%s] "%s" enum entered at scope %d', whoami(__PACKAGE__), $token, $self->{_nscope});
  }
  #
  # Enum wins from now on and forever
  #
  foreach (0..$#{$self->{_typedefPerScope}}) {
      $self->parseObscureTypedef($token, $_);
  }
}


sub parseObscureTypedef {
  my ($self, $token, $scope) = @_;

  $scope //= $self->{_nscope};
  $self->{_typedefPerScope}->[$scope]->{$token} = undef;

  if ($log->is_debug) {
      $log->debugf('[%s] "%s" eventual typedef obscured at scope %d', whoami(__PACKAGE__), $token, $scope);
  }
}


sub parseIsTypedef {
  my ($self, $token) = @_;

  my $scope = $self->{_nscope};
  my $rc = (exists($self->{_typedefPerScope}->[$scope]->{$token}) && defined($self->{_typedefPerScope}->[$scope]->{$token})) ? 1 : 0;

  if ($log->is_debug) {
      $log->debugf('[%s] "%s" at scope %d is a typedef? %s', whoami(__PACKAGE__), $token, $scope, $rc ? 'yes' : 'no');
  }

  return($rc);
}


sub parseIsEnum {
  my ($self, $token) = @_;

  my $rc = (exists($self->{_enumAnyScope}->{$token}) && $self->{_enumAnyScope}->{$token}) ? 1 : 0;

  if ($log->is_debug) {
      $log->debugf('[%s] "%s" is an enum at scope %d? %s', whoami(__PACKAGE__), $token, $self->{_nscope}, $rc ? 'yes' : 'no');
  }

  return($rc);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Scope - Scope management when translating a C source to an AST

=head1 VERSION

version 0.48

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::C::AST::Scope;

    my $cAstScopeObject = MarpaX::Languages::C::AST::Scope->new();
    $cAstScopeObject->parseEnterScope();
    $cAstScopeObject->parseEnterTypedef("myTypedef");
    $cAstScopeObject->parseEnterEnum("myEnum");
    $cAstScopeObject->parseObscureTypedef("myVariable");
    foreach (qw/myTypedef myEnum myVariable/) {
      if ($cAstScopeObject->parseIsTypedef($_)) {
        print "\"$_\" is a typedef\n";
      } elsif ($cAstScopeObject->parseIsEnum($_)) {
        print "\"$_\" is an enum\n";
      }
    }
    $cAstScopeObject->parseExitScope();

=head1 DESCRIPTION

This modules manages the scopes when translation a C source into an AST tree. This module started after reading the article:

I<Resolving Typedefs in a Multipass C Compiler> from I<Journal of C Languages Translation>, Volume 2, Number 4, written by W.M. McKeeman. A online version may be accessed at L<http://www.cs.dartmouth.edu/~mckeeman/references/JCLT/ResolvingTypedefsInAMultipassCCompiler.pdf>.

Please note that this module is logging via Log::Any.

=head1 SUBROUTINES/METHODS

=head2 new

Instance a new object. Takes no parameter.

=head2 typedefPerScope($self)

Returns the list of known typedefs per scope. At the end of processing a source code, only scope 0 still exist. The output is a reference to an array, file-level scope being at index 0. At each indice, there is a reference to a hash with typedef name as a key, value is useless.

=head2 enumAnyScope($self)

Returns the list of known enums. Enums has no scope level: as soon as the parser sees an enum, it available at any level. The output is a reference to a hash with enumeration name as a key, value is useless.

=head2 parseEnterScope($self)

Say we enter a scope.

=head2 parseDelay($self, [$value])

Returns/Set delay flag of the current (i.e. last) scope.

=head2 parseScopeLevel($self)

Returns current scope level, starting at number 0.

=head2 parseEnterScopeCallback($self, $ref, @args)

Callback method when entering a scope.

=head2 parseExitScopeCallback($self, $ref, @args)

Callback method when leaving a scope (not the delayed operation, the real leave).

=head2 parseExitScope($self, [$now])

Say we want to leave current scope. The operation is delayed unless $now flag is true.

=head2 parseReenterScope($self)

Reenter previous scope.

=head2 condExitScope($self)

Leave current scope if delay flag is set and not yet done.

=head2 doExitScope($self)

Leave current scope.

=head2 parseEnterTypedef($self, $token, $data)

Declare a new typedef with name $token, that will be visible until current scope is left. $data is an optional user-data area, defaulting to 1 if not specified.

=head2 parseEnterEnum($self, $token)

Declare a new enum with name $token, that will be visible at any scope from now on. $data is an optional user-data area, defaulting to 1 if not specified.

=head2 parseObscureTypedef($self, $token)

Obscures a typedef named $token.

=head2 parseIsTypedef($self, $token)

Return a true value if $token is a typedef.

=head2 parseIsEnum($self, $token)

Return a true value if $token is an enum.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
