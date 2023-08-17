use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Util::MarpaTrace;

use Class::Load qw/is_class_loaded/;

# ABSTRACT: Marpa Trace Wrapper

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

sub BEGIN {
  #
  ## Some Log implementation specificities
  #
  Log::Log4perl->wrapper_register(__PACKAGE__) if (is_class_loaded('Log::Log4perl'))
}

sub TIEHANDLE {
  bless {}, $_[0]
}

sub PRINT {
  no warnings 'once';
  my $self = $MarpaX::Java::ClassFile::Role::Parser::SELF;
  #
  # This is supported only if this localized variable is set
  #
  if ($self) {
    #
    # We do not want to be perturbed by automatic thingies coming from $\
    #
    local $\ = undef;
    map { $self->tracef('%s', $_) } split(/\n/, join('', @_[1..$#_]));
  }
  1
}

sub PRINTF {
  $_[0]->PRINT(sprintf(shift, @_[1..$#_]));
  1
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Util::MarpaTrace - Marpa Trace Wrapper

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
