use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Role::Parser;

# ABSTRACT: Parsing engine role for .class file parsing

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Moo::Role;
#
# Note: This package is part of the core of the engine. Therefore it
# optimized except the logging (when you trace this package, I assume
# you are not interested in micro-optimizations)
#
use Carp qw/croak/;
use MarpaX::Java::ClassFile::Util::MarpaTrace qw//;
use MarpaX::Java::ClassFile::Util::ProductionMode qw/prod_isa/;
use Data::Section -setup;
use Scalar::Util qw/blessed/;
use Types::Common::Numeric qw/PositiveOrZeroInt/;
use Types::Standard qw/Any ScalarRef Bool ArrayRef Str Undef ConsumerOf InstanceOf/;
use Types::Encodings qw/Bytes/;


#
# Required parameters
#
has inputRef            => ( is => 'ro',  prod_isa(ScalarRef[Bytes]),                                                  required => 1);
#
# Parameters with a default
#
has marpaRecceHook      => ( is => 'ro',  prod_isa(Bool),                                                      default => sub { 1 });
has constant_pool_count => ( is => 'ro',  prod_isa(PositiveOrZeroInt),                                         default => sub { 0 } );
has constant_pool       => ( is => 'ro',  prod_isa(ArrayRef),                                                  default => sub { [] });
has pos                 => ( is => 'rwp', prod_isa(PositiveOrZeroInt),                                         default => sub { 0 });
has exhaustion          => ( is => 'ro',  prod_isa(Str),                                                       default => sub { 'event' });
has parent              => ( is => 'ro',  prod_isa(Undef|ConsumerOf['MarpaX::Java::ClassFile::Role::Parser']), default => sub { return });
#
# Lazy parameters
#
has max                 => ( is => 'rwp', prod_isa(PositiveOrZeroInt),                                         lazy => 1, builder => 1);
has whoami              => ( is => 'ro',  prod_isa(Str),                                                       lazy => 1, builder => 1);
has ast                 => ( is => 'ro',  prod_isa(Any),                                                       lazy => 1, builder => 1);

my $MARPA_TRACE_FILE_HANDLE;
my $MARPA_TRACE_BUFFER;
my %_registrations = ();
my %_DOES_INNERGRAMMAR = ();

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
      if (! tie ${$MARPA_TRACE_FILE_HANDLE}, 'MarpaX::Java::ClassFile::Util::MarpaTrace') {
        croak "Cannot tie $MARPA_TRACE_FILE_HANDLE, $!\n";
        if (! close($MARPA_TRACE_FILE_HANDLE)) {
          croak "Cannot close temporary file handle, $!\n";
        }
        $MARPA_TRACE_FILE_HANDLE = undef;
      }
    }
}

sub _build_max {
  # my ($self) = @_;
  length(${$_[0]->inputRef})
}

sub _build_whoami {
  # my ($self, $class) = @_;
  my $whoami = (split(/::/, $_[1] // blessed($_[0])))[-1];

  return join('->', $_[0]->parent->whoami, $whoami) if (defined($_[0]->parent));
  $whoami
}

# -----------------------
# General events dispatch
# -----------------------
sub manageEvents {
  # my ($self) = @_;

  my @eventNames = map { $_->[0] } (@{$_[0]->_events});
  # $_[0]->tracef('Events: %s', \@eventNames);
  foreach (@eventNames) {
    $_[0]->tracef('--------- %s', $_);
    my $callback = $_[0]->callbacks->{$_};
    $_[0]->_croak("Unmanaged event $_") unless defined($callback);
    $_[0]->$callback
  }
}

sub _build__r {
  # my ($self) = @_;
}

sub _build_ast {
  # my ($self) = @_;
  #
  # For our marpa tied logger
  #
  no warnings 'once';
  local $MarpaX::Java::ClassFile::Role::Parser::SELF = $_[0];
  local $MarpaX::Java::ClassFile::Role::Parser::G    = $_[0]->grammar;
  #
  # It is far quicker to maintain ourself booleans for trace and debug mode
  # rather than letting logger's tracef() and debugf() handle the request.
  # Further more we do //= because these really should be constant once
  # parse is starting.
  # The following can look strange but is my way to makes sure that $[0]->log is called once per parse -;
  # even when setting localized variables.
  #
  my $IS_TRACE = $MarpaX::Java::ClassFile::Role::Parser::IS_TRACE;
  my $IS_DEBUG = $MarpaX::Java::ClassFile::Role::Parser::IS_DEBUG;
  my $IS_INFO  = $MarpaX::Java::ClassFile::Role::Parser::IS_INFO;
  my $IS_WARN  = $MarpaX::Java::ClassFile::Role::Parser::IS_WARN;
  my $IS_ERROR = $MarpaX::Java::ClassFile::Role::Parser::IS_ERROR;
  my $IS_FATAL = $MarpaX::Java::ClassFile::Role::Parser::IS_FATAL;

  local $MarpaX::Java::ClassFile::Role::Parser::IS_TRACE = $IS_TRACE // $_[0]->log->is_trace;
  local $MarpaX::Java::ClassFile::Role::Parser::IS_DEBUG = $IS_DEBUG // $_[0]->log->is_debug;
  local $MarpaX::Java::ClassFile::Role::Parser::IS_INFO  = $IS_INFO  // $_[0]->log->is_info;
  local $MarpaX::Java::ClassFile::Role::Parser::IS_WARN  = $IS_WARN  // $_[0]->log->is_warn;
  local $MarpaX::Java::ClassFile::Role::Parser::IS_ERROR = $IS_ERROR // $_[0]->log->is_error;
  local $MarpaX::Java::ClassFile::Role::Parser::IS_FATAL = $IS_FATAL // $_[0]->log->is_fatal;
  #
  # Localize recognizer
  #
  local $MarpaX::Java::ClassFile::Role::Parser::R = Marpa::R2::Scanless::R->new({
                                                                                 trace_file_handle => $MARPA_TRACE_FILE_HANDLE,
                                                                                 grammar           => $_[0]->grammar,
                                                                                 exhaustion        => $_[0]->exhaustion,
                                                                                 trace_terminals   => $MarpaX::Java::ClassFile::Role::Parser::IS_TRACE
                                                                                });

  local $MarpaX::Java::ClassFile::Role::Parser::LEX_CONTEXT = 1;
  $_[0]->_read;
  while ($_[0]->pos < $_[0]->max) { $_[0]->_resume }
  undef $MarpaX::Java::ClassFile::Role::Parser::LEX_CONTEXT;

  $_[0]->_value
}

sub exhausted {
  $_[0]->_set_max($_[0]->pos)
}

sub _read {
  # my ($self) = @_;

  $_[0]->tracef('read($inputRef, %s)', $_[0]->pos);
  eval {
    my $pos = $MarpaX::Java::ClassFile::Role::Parser::R->read($_[0]->inputRef, $_[0]->pos);
    #
    # read() MAY return zero. This happen if there is an event at
    # the very beginning of the grammar
    #
    $_[0]->_set_pos($pos) if ($pos)
  };
  $_[0]->_croak($@) if ($@);
  $_[0]->manageEvents
}

sub _events {
  # my ($self) = @_;

  $_[0]->tracef('events()');
  my $eventsRef = eval { $MarpaX::Java::ClassFile::Role::Parser::R->events };
  $_[0]->_croak($@) if ($@);
  $eventsRef
}

sub _value {
  # my ($self) = @_;

  $_[0]->tracef('ambiguity_metric()');
  my $ambiguity_metric = eval { $MarpaX::Java::ClassFile::Role::Parser::R->ambiguity_metric() };
  $_[0]->_croak($@) if ($@);
  $_[0]->_croak('Ambiguity metric is undefined') if (! defined($ambiguity_metric));
  $_[0]->_croak('Parse is ambiguous') if ($ambiguity_metric != 1);

  $_[0]->tracef('value($_[0])');
  #
  # Registration hook ?
  #
  my $marpaRecceHook = $_[0]->marpaRecceHook;
  $MarpaX::Java::ClassFile::Role::Parser::R->registrations($_registrations{ref($_[0])}) if ($marpaRecceHook && defined($_registrations{ref($_[0])}));
  my $valueRef = eval { $MarpaX::Java::ClassFile::Role::Parser::R->value($_[0]) };
  #
  # Register hooks if not already the case
  #
  $_registrations{ref($_[0])} = $MarpaX::Java::ClassFile::Role::Parser::R->registrations if ($marpaRecceHook && ! defined($_registrations{ref($_[0])}));
  $_[0]->_croak($@) if ($@);
  $_[0]->_croak('Value reference is undefined') if (! defined($valueRef));

  my $value = ${$valueRef};
  $_[0]->_croak('Value is undefined') if (! defined($value));

  $value
}

sub _resume {
  # my ($self) = @_;

  $_[0]->tracef('resume(%s)', $_[0]->pos);
  eval { $_[0]->_set_pos($MarpaX::Java::ClassFile::Role::Parser::R->resume($_[0]->pos)) };
  $_[0]->_croak($@) if ($@);
  $_[0]->manageEvents
}

sub _literal {
  # my ($self, $symbol) = @_;

  $_[0]->tracef('last_completed_span(\'%s\')', $_[1]);
  my @span = $MarpaX::Java::ClassFile::Role::Parser::R->last_completed_span($_[1]);
  $_[0]->_croak("No symbol instance for the symbol $_[1]") if (! @span);
  $_[0]->tracef('literal(%s, %s)', $span[0], $span[1]);
  $MarpaX::Java::ClassFile::Role::Parser::R->literal(@span)
}

sub _pause {
  # my ($self, $symbol) = @_;

  $_[0]->tracef('pause_span()');
  my @span = $MarpaX::Java::ClassFile::Role::Parser::R->pause_span();
  $_[0]->_croak('No pause span') if (! @span);
  $_[0]->tracef('literal(%s, %s)', $span[0], $span[1]);
  $MarpaX::Java::ClassFile::Role::Parser::R->literal(@span)
}

#
# Helpers to read a U1/U2/U4/MANAGED lexemes
#
sub _lexeme_read_helper {
  # my ($self, $lexeme_name, $lexeme_length, $ignoreEvents) = @_;

  if ($_[2]) {
    $_[0]->fatalf('Not enough bytes, pos=%d, max=%d, asking for %d', $_[0]->pos, $_[0]->max, $_[2]) if ($_[2] + $_[0]->pos > $_[0]->max);
    my $bytes = substr(${$_[0]->inputRef}, $_[0]->pos, $_[2]);
    $_[0]->lexeme_read($_[1], $_[2], $bytes, $_[3])
  } else {
    $_[0]->lexeme_read($_[1], 0, undef, $_[3])
  }
}

sub lexeme_read_u1 {
  # my ($self, $ignoreEvents) = @_;
   $_[0]->_lexeme_read_helper('U1', 1, $_[1])
 }

sub lexeme_read_u2 {
  # my ($self, $ignoreEvents) = @_;
   $_[0]->_lexeme_read_helper('U2', 2, $_[1])
 }

sub lexeme_read_u4 {
  # my ($self, $ignoreEvents) = @_;
   $_[0]->_lexeme_read_helper('U4', 4, $_[1])
 }

sub lexeme_read_managed {
  # my ($self, $lexeme_length, $ignoreEvents) = @_;
   $_[0]->_lexeme_read_helper('MANAGED', $_[1], $_[2])
 }

sub lexeme_read {
  # my ($self, $lexeme_name, $lexeme_length, $lexeme_value, $ignoreEvents) = @_;

  #
  # If the length is zero, force the read to be at position 0.
  # We will anyway explicitely re-set position and it works
  # because we always do $MarpaX::Java::ClassFile::Role::Parser::R->resume($self->pos) -;
  #
  my $_lexeme_length = $_[2] || 1;
  my $_lexeme_pos    = $_[2] ? $_[0]->pos : 0;
  $_[0]->tracef('lexeme_read(\'%s\', %s, %s, $value)', $_[1], $_lexeme_pos, $_lexeme_length);
  my $pos;
  eval {
    #
    # Do the lexeme_read in any case
    #
    $pos = $MarpaX::Java::ClassFile::Role::Parser::R->lexeme_read($_[1], $_lexeme_pos, $_lexeme_length, $_[3]) || croak sprintf('lexeme_read failure for symbol %s at position %s, length %s', $_[1], $_lexeme_pos, $_lexeme_length);
    #
    # And commit its return position unless length is 0
    # It is illegal to do a lexeme_read with a length <= 0, so it is guaranteed here
    # that position has moved
    #
    $_[0]->_set_pos($pos) if ($_[2])
  };
  $_[0]->_croak($@) if ($@);
  $_[0]->manageEvents unless ($_[4])
}

sub pauseU1 {
  # my ($self, $symbol) = @_;

  my $u1 = $_[0]->u1($_[0]->_pause);
  $_[0]->tracef('Got u1=%s', $u1);
  $u1
}

sub pauseSignedU1 {
  # my ($self, $symbol) = @_;

  my $signedU1 = $_[0]->signedU1($_[0]->_pause);
  $_[0]->tracef('Got signedU1=%s', $signedU1);
  $signedU1
}

sub pauseU2 {
  # my ($self, $symbol) = @_;

  my $u2 = $_[0]->u2($_[0]->_pause);
  $_[0]->tracef('Got u2=%s', $u2);
  $u2
}

sub pauseSignedU2 {
  # my ($self, $symbol) = @_;

  my $signedU2 = $_[0]->signedU2($_[0]->_pause);
  $_[0]->tracef('Got signedU2=%s', $signedU2);
  $signedU2
}

sub pauseU4 {
  # my ($self, $symbol) = @_;

  my $u4 = $_[0]->u4($_[0]->_pause);
  $_[0]->tracef('Got u4=%s', $u4);
  $u4
}

sub pauseSignedU4 {
  # my ($self, $symbol) = @_;

  my $signedU4 = $_[0]->signedU4($_[0]->_pause);
  $_[0]->tracef('Got signedU4=%s', $signedU4);
  $signedU4
}

sub literalU1 {
  # my ($self, $symbol) = @_;

  my $u1 = $_[0]->u1($_[0]->_literal($_[1]));
  $_[0]->tracef('Got u1=%s', $u1);
  $u1
}

sub literalSignedU1 {
  # my ($self, $symbol) = @_;

  my $signedU1 = $_[0]->signedU1($_[0]->_literal($_[1]));
  $_[0]->tracef('Got signedU1=%s', $signedU1);
  $signedU1
}

sub literalU2 {
  # my ($self, $_[1]) = @_;

  my $u2 = $_[0]->u2($_[0]->_literal($_[1]));
  $_[0]->tracef('Got u2=%s', $u2);
  $u2
}

sub literalSignedU2 {
  # my ($self, $symbol) = @_;

  my $signedU2 = $_[0]->signedU2($_[0]->_literal($_[1]));
  $_[0]->tracef('Got signedU2=%s', $signedU2);
  $signedU2
}

sub literalU4 {
  # my ($self, $symbol) = @_;

  my $u4 = $_[0]->u4($_[0]->_literal($_[1]));
  $_[0]->tracef('Got u4=%s', $u4);
  $u4
}

sub literalSignedU4 {
  # my ($self, $symbol) = @_;

  my $signedU4 = $_[0]->signedU4($_[0]->_literal($_[1]));
  $_[0]->tracef('Got signedU4=%s', $signedU4);
  $signedU4
}

sub literal {
  # my ($self, $symbol) = @_;

  $_[0]->_literal($_[1])
}

sub activate {
  # my ($self, $eventName, $status) = @_;

  $_[0]->tracef('activate(\'%s\', %s)', $_[1], $_[2]);
  $MarpaX::Java::ClassFile::Role::Parser::R->activate($_[1], $_[2])
}

#
# An inner grammar is an opaque thing, so associated
# lexeme must be MANAGED.
#
sub _inner {
  # my ($self, $innerGrammarClass, $ignoreEvent, %args) = @_;

  my $innerClass = "MarpaX::Java::ClassFile::BNF::$_[1]";
  #
  # Even if MarpaX::Java::ClassFile::Role::Parser::InnerGrammar is able to hangle size == 0
  # stand-alone, there is really no need to go throw an object creation
  # when we know that the result /will be/ []
  #
  my %args = @_[3..$#_];
  if ($_DOES_INNERGRAMMAR{$innerClass} //= $innerClass->DOES('MarpaX::Java::ClassFile::Role::Parser::InnerGrammar') ? 1 : 0) { # To make sure this is defined
    if (! $args{size}) { # ok if undef
      # $_[0]->tracef('Bypassing inner grammar %s at position %s, with%s outside event, extra arguments: %s', $innerClass, $_[0]->pos, $_[2] ? 'out' : '', { @_[3..$#_] });
      $_[0]->lexeme_read('MANAGED', 0, [], $_[2]);
      return []
    }
  }
  # $_[0]->tracef('Starting inner grammar %s at position %s, with%s outside event, extra arguments: %s', $innerClass, $_[0]->pos, $_[2] ? 'out' : '', { @_[3..$#_] });
  my $inner = $innerClass->new(parent              => $_[0],
                               constant_pool_count => $_[0]->constant_pool_count,
                               constant_pool       => $_[0]->constant_pool,
                               inputRef            => $_[0]->inputRef,
                               pos                 => $_[0]->pos,
                               log                 => $_[0]->log,
                               %args);
  my $innerGrammarValue = $inner->ast;
  $_[0]->lexeme_read('MANAGED', $inner->pos - $_[0]->pos, $innerGrammarValue, $_[2]);
  $innerGrammarValue
}
sub inner        { $_[0]->_inner($_[1], 0, @_[2..$#_]) }
sub inner_silent { $_[0]->_inner($_[1], 1, @_[2..$#_]) }

#
# Logging/croak stuff : voluntarily not optimized
#
sub _dolog {
  my ($self, $method, $format, @arguments) = @_;
  #
  # If we are in an action, we do nothing else
  # but propage the message to the log handler
  # as-is. Current and max positions are meaningul
  # only in the lexing phase, that may not use
  # another level but TRACE btw -;
  #
  if ($MarpaX::Java::ClassFile::Role::Parser::LEX_CONTEXT) {
    my $inputLength = length(${$self->inputRef});
    my $nbcharacters = length("$inputLength");
    my ($offset, $max) = ($self->pos, $self->max);

    $self->log->$method("[pos %*s->%*s] %s: $format", $nbcharacters, $offset, $nbcharacters, $self->max, $self->whoami, @arguments)
  } else {
    $self->log->$method("%s: $format", $self->whoami, @arguments)
  }
}

sub debugf {
  my ($self, $format, @arguments) = @_;

  return unless $MarpaX::Java::ClassFile::Role::Parser::IS_DEBUG;
  $self->_dolog('debugf', $format, @arguments)
}

sub infof {
  my ($self, $format, @arguments) = @_;

  return unless $MarpaX::Java::ClassFile::Role::Parser::IS_INFO;
  $self->_dolog('infof', $format, @arguments);
}

sub errorf {
  my ($self, $format, @arguments) = @_;

  return unless $MarpaX::Java::ClassFile::Role::Parser::IS_ERROR;
  $self->_dolog('errorf', $format, @arguments)
}

sub warnf {
  my ($self, $format, @arguments) = @_;

  return unless $MarpaX::Java::ClassFile::Role::Parser::IS_WARN;
  $self->_dolog('warnf', $format, @arguments)
}

sub tracef {
  my ($self, $format, @arguments) = @_;

  return unless $MarpaX::Java::ClassFile::Role::Parser::IS_TRACE;
  $self->_dolog('tracef', $format, @arguments)
}

sub fatalf {
  my ($self, $format, @arguments) = @_;

  $self->_dolog('fatalf', $format, @arguments) if ($MarpaX::Java::ClassFile::Role::Parser::IS_FATAL);
  croak sprintf($format, @arguments)
}

sub _croak {
  my ($self, $msg) = @_;

  $msg //= '';
  #
  # Should never happen that $self->_r is not set at this stage but who knows
  #
  $msg .= "\nContext:\n" . $MarpaX::Java::ClassFile::Role::Parser::R->show_progress if $MarpaX::Java::ClassFile::Role::Parser::LEX_CONTEXT;
  croak($msg)
}

with qw/MooX::Log::Any MarpaX::Java::ClassFile::Role::Parser::Actions/;

requires 'callbacks';
requires 'grammar';

#
# Marpa Hooks
#
sub BEGIN {
  #
  # Marpa internal optimisation: we do not want the closures to be rechecked every time
  # we call $r->value(). This is a static information, although determined at run-time
  # the first time $r->value() is called on a recognizer.
  #
  no warnings 'redefine';
  no strict 'subs';

  sub Marpa::R2::Recognizer::registrations {
    my $recce = shift;
    if (@_) {
      my $hash = shift;
      if (! defined($hash) ||
          ref($hash) ne 'HASH' ||
          grep {! exists($hash->{$_})} qw/
                                           NULL_VALUES
                                           REGISTRATIONS
                                           CLOSURE_BY_SYMBOL_ID
                                           CLOSURE_BY_RULE_ID
                                           RESOLVE_PACKAGE
                                           RESOLVE_PACKAGE_SOURCE
                                           PER_PARSE_CONSTRUCTOR
                                         /) {
        Marpa::R2::exception(
                             "Attempt to reuse registrations failed:\n",
                             "  Registration data is not a hash containing all necessary keys:\n",
                             "  Got : " . ((ref($hash) eq 'HASH') ? join(', ', sort keys %{$hash}) : '') . "\n",
                             "  Want: CLOSURE_BY_RULE_ID, CLOSURE_BY_SYMBOL_ID, NULL_VALUES, PER_PARSE_CONSTRUCTOR, REGISTRATIONS, RESOLVE_PACKAGE, RESOLVE_PACKAGE_SOURCE\n"
                            );
      }
      $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES] = $hash->{NULL_VALUES};
      $recce->[Marpa::R2::Internal::Recognizer::REGISTRATIONS] = $hash->{REGISTRATIONS};
      $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_SYMBOL_ID] = $hash->{CLOSURE_BY_SYMBOL_ID};
      $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_RULE_ID] = $hash->{CLOSURE_BY_RULE_ID};
      $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE] = $hash->{RESOLVE_PACKAGE};
      $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE] = $hash->{RESOLVE_PACKAGE_SOURCE};
      $recce->[Marpa::R2::Internal::Recognizer::PER_PARSE_CONSTRUCTOR] = $hash->{PER_PARSE_CONSTRUCTOR}
    }
    return {
            NULL_VALUES => $recce->[Marpa::R2::Internal::Recognizer::NULL_VALUES],
            REGISTRATIONS => $recce->[Marpa::R2::Internal::Recognizer::REGISTRATIONS],
            CLOSURE_BY_SYMBOL_ID => $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_SYMBOL_ID],
            CLOSURE_BY_RULE_ID => $recce->[Marpa::R2::Internal::Recognizer::CLOSURE_BY_RULE_ID],
            RESOLVE_PACKAGE => $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE],
            RESOLVE_PACKAGE_SOURCE => $recce->[Marpa::R2::Internal::Recognizer::RESOLVE_PACKAGE_SOURCE],
            PER_PARSE_CONSTRUCTOR => $recce->[Marpa::R2::Internal::Recognizer::PER_PARSE_CONSTRUCTOR]
           }
  }

  sub Marpa::R2::Scanless::R::registrations {
    my $slr = shift;
    my $thick_g1_recce = $slr->[Marpa::R2::Internal::Scanless::R::THICK_G1_RECCE];
    $thick_g1_recce->registrations(@_)
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Role::Parser - Parsing engine role for .class file parsing

=head1 VERSION

version 0.009

=head1 DESCRIPTION

MarpaX::Java::ClassFile::Role::Parser is the parse engine role used by L<MarpaX::Java::ClassFile::ClassFile>, please refer to the later.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
