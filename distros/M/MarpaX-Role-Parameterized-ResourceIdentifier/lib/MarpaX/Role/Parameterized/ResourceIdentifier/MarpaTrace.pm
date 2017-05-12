use strict;
use warnings FATAL => 'all';

package MarpaX::Role::Parameterized::ResourceIdentifier::MarpaTrace;

# ABSTRACT: Marpa Trace Wrapper

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

sub BEGIN {
  #
  ## Some Log implementation specificities
  #
  my $log4perl = eval 'use Log::Log4perl; 1;' || 0; ## no critic
  if ($log4perl) {
    #
    ## Here we put know hooks for logger implementations
    #
    Log::Log4perl->wrapper_register(__PACKAGE__);
  }
}

sub TIEHANDLE {
  my $class = shift;
  my $category = $MarpaX::Role::Parameterized::ResourceIdentifier::MarpaTrace::bnf_package || __PACKAGE__;
  bless { category => $category, logger => Log::Any->get_logger(category => $category) }, $class;
}

sub PRINT {
  my $self = shift;
  #
  # We do not want to be perturbed by automatic thingies coming from $\
  #
  local $\ = undef;
  map { $self->{logger}->tracef('%s: %s', $self->{category}, $_) } split(/\n/, join('', @_));
  return 1;
}

sub PRINTF {
  shift->PRINT(sprintf(shift, @_));
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Role::Parameterized::ResourceIdentifier::MarpaTrace - Marpa Trace Wrapper

=head1 VERSION

version 0.003

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
