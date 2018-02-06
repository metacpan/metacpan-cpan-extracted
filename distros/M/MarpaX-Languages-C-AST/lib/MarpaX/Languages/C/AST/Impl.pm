use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Impl;

# ABSTRACT: Implementation of Marpa's interface

# use MarpaX::Languages::C::AST::Util qw/traceAndUnpack/;
use Marpa::R2 2.081001;
use Carp qw/croak/;
use MarpaX::Languages::C::AST::Impl::Logger;

our $VERSION = '0.48'; # VERSION

our $MARPA_TRACE_FILE_HANDLE;
our $MARPA_TRACE_BUFFER;

sub BEGIN {
    #
    ## We do not want Marpa to pollute STDERR
    #
    ## Autovivify a new file handle
    #
    open($MARPA_TRACE_FILE_HANDLE, '>', \$MARPA_TRACE_BUFFER);
    if (! defined($MARPA_TRACE_FILE_HANDLE)) {
      croak "Cannot create temporary file handle to tie Marpa logging, $!\n";
    } else {
      if (! tie ${$MARPA_TRACE_FILE_HANDLE}, 'MarpaX::Languages::C::AST::Impl::Logger') {
        croak "Cannot tie $MARPA_TRACE_FILE_HANDLE, $!\n";
        if (! close($MARPA_TRACE_FILE_HANDLE)) {
          croak "Cannot close temporary file handle, $!\n";
        }
        $MARPA_TRACE_FILE_HANDLE = undef;
      }
    }
}


sub new {

  my ($class, $grammarOptionsHashp, $recceOptionsHashp) = @_;

  my $self  = {
      _cacheRule => {}
  };
  $self->{grammar} = Marpa::R2::Scanless::G->new($grammarOptionsHashp);
  if (defined($recceOptionsHashp)) {
      $recceOptionsHashp->{grammar} = $self->{grammar};
  } else {
      $recceOptionsHashp = {grammar => $self->{grammar}};
  }
  $recceOptionsHashp->{trace_terminals} = $ENV{MARPA_TRACE_TERMINALS} || $ENV{MARPA_TRACE} || 0;
  $recceOptionsHashp->{trace_values} = $ENV{MARPA_TRACE_VALUES} || $ENV{MARPA_TRACE} || 0;
  $recceOptionsHashp->{trace_file_handle} = $MARPA_TRACE_FILE_HANDLE;
  $self->{recce} = Marpa::R2::Scanless::R->new($recceOptionsHashp);
  bless($self, $class);

  return $self;
}


sub value {
  return $_[0]->{recce}->value(@_[1..$#_]);
}


sub read {
  return $_[0]->{recce}->read(@_[1..$#_]);
}


sub resume {
  return $_[0]->{recce}->resume(@_[1..$#_]);
}


sub last_completed {
  return $_[0]->{recce}->last_completed(@_[1..$#_]);
}


sub last_completed_range {
  return $_[0]->{recce}->last_completed_range(@_[1..$#_]);
}


sub range_to_string {
  return $_[0]->{recce}->range_to_string(@_[1..$#_]);
}


sub event {
  return $_[0]->{recce}->event(@_[1..$#_]);
}


sub pause_lexeme {
  return $_[0]->{recce}->pause_lexeme(@_[1..$#_]);
}


sub pause_span {
  return $_[0]->{recce}->pause_span(@_[1..$#_]);
}


sub literal {
  return $_[0]->{recce}->literal(@_[1..$#_]);
}


sub line_column {
  return $_[0]->{recce}->line_column(@_[1..$#_]);
}


sub substring {
  return $_[0]->{recce}->substring(@_[1..$#_]);
}


sub lexeme_read {
  return $_[0]->{recce}->lexeme_read(@_[1..$#_]);
}


sub lexeme_alternative {
  return $_[0]->{recce}->lexeme_alternative(@_[1..$#_]);
}


sub lexeme_complete {
  return $_[0]->{recce}->lexeme_complete(@_[1..$#_]);
}


sub current_g1_location {
  return $_[0]->{recce}->current_g1_location(@_[1..$#_]);
}


sub g1_location_to_span {
  return $_[0]->{recce}->g1_location_to_span(@_[1..$#_]);
}


sub terminals_expected {
  return $_[0]->{recce}->terminals_expected(@_[1..$#_]);
}


sub show_progress {
  return $_[0]->{recce}->show_progress(@_[1..$#_]);
}


sub start_symbol_id {
  return $_[0]->{grammar}->start_symbol_id(@_[1..$#_]);
}


sub rule_ids {
  return $_[0]->{grammar}->rule_ids(@_[1..$#_]);
}


sub symbol_name {
  return $_[0]->{grammar}->symbol_name(@_[1..$#_]);
}


sub rule_name {
  return $_[0]->{grammar}->rule_name(@_[1..$#_]);
}


sub rule_expand {
  return $_[0]->{grammar}->rule_expand(@_[1..$#_]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Impl - Implementation of Marpa's interface

=head1 VERSION

version 0.48

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::C::AST::Impl;

    my $marpaImpl = MarpaX::Languages::C::AST::Impl->new();

=head1 DESCRIPTION

This modules implements all needed Marpa calls using its Scanless interface. Please be aware that logging is done via Log::Any.

=head1 SUBROUTINES/METHODS

=head2 new($class, $grammarOptionsHashp, $recceOptionsHashp)

Instantiate a new object. Takes as parameter two references to hashes: the grammar options, the recognizer options. In the recognizer, there is a grammar internal option that will be forced to the grammar object. If the environment variable MARPA_TRACE_TERMINALS is set to a true value, then internal Marpa trace on terminals is activated. If the environment MARPA_TRACE_VALUES is set to a true value, then internal Marpa trace on values is activated. If the environment variable MARPA_TRACE is set to a true value, then both terminals and values internal Marpa traces are activated.

=head2 value($self)

Returns Marpa's recognizer's value.

=head2 read($self, $inputp)

Returns Marpa's recognizer's read. Argument is a reference to input.

=head2 resume($self)

Returns Marpa's recognizer's resume.

=head2 last_completed($self, $symbol)

Returns Marpa's recognizer's last_completed for symbol $symbol.

=head2 last_completed_range($self, $symbol)

Returns Marpa's recognizer's last_completed_range for symbol $symbol.

=head2 range_to_string($self, $start, $end)

Returns Marpa's recognizer's range_to_string for a start value of $start and an end value of $end.

=head2 event($self, $eventNumber)

Returns Marpa's recognizer's event for event number $eventNumber.

=head2 pause_lexeme($self)

Returns Marpa's recognizer's pause_lexeme.

=head2 pause_span($self)

Returns Marpa's recognizer's pause_span.

=head2 literal($self, $start, $length)

Returns Marpa's recognizer's literal.

=head2 line_column($self, $start)

Returns Marpa's recognizer's line_column at eventual $start location in the input stream. Default location is current location.

=head2 substring($self, $start, $length)

Returns Marpa's recognizer's substring corresponding to g1 span ($start, $length).

=head2 lexeme_read($self, $lexeme, $start, $length, $value)

Returns Marpa's recognizer's lexeme_read for lexeme $lexeme, at start position $start, length $length and value $value.

=head2 lexeme_alternative($self, $lexeme, $value)

Returns Marpa's recognizer's lexeme_alternative for lexeme $lexeme, value $value.

=head2 lexeme_complete($self, $start, $length)

Returns Marpa's recognizer's lexeme_complete at start position $start, length $length.

=head2 current_g1_location($self)

Returns Marpa's recognizer's current_g1_location.

=head2 g1_location_to_span($self, $g1)

Returns Marpa's recognizer's g1_location_to_span for a g1 location $g1.

=head2 terminals_expected($self)

Returns Marpa's recognizer's terminals_expected.

=head2 show_progress($self)

Returns Marpa's recognizer's show_progress.

=head2 start_symbol_id($self)

Returns Marpa's grammar's start_symbol_id.

=head2 rule_ids($self)

Returns Marpa's grammar's rule_ids.

=head2 symbol_name($self)

Returns Marpa's grammar's symbol_name.

=head2 rule_name($self)

Returns Marpa's grammar's rule_name.

=head2 rule_expand($self)

Returns Marpa's grammar's rule_expand.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
