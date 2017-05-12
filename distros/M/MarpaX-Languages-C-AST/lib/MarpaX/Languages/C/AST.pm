use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST;

# ABSTRACT: Translate a C source to an AST

use Log::Any qw/$log/;
use Carp qw/croak/;
use MarpaX::Languages::C::AST::Util qw/:all/;
use MarpaX::Languages::C::AST::Grammar qw//;
use MarpaX::Languages::C::AST::Impl qw//;
use MarpaX::Languages::C::AST::Scope qw//;
use MarpaX::Languages::C::AST::Callback::Events qw//;
use Regexp::Common qw/comment delimited/;

our $WS_RE = qr/[ \t\v\n\f]/;          # C.f. doAsmOpaque()
our $ASM_COMMENT_RE = qr/(?:;[^\n]*|$RE{comment}{'C++'})/;

our $VERSION = '0.47'; # VERSION


# ----------------------------------------------------------------------------------------
sub new {
  my ($class, %opts) = @_;

  my $logInfo = $opts{logInfo} || [];
  if (ref($logInfo) ne 'ARRAY') {
      croak 'logInfo must be a reference to ARRAY';
  }
  my %logInfo = ();
  map {$logInfo{$_}++} @{$logInfo};

  my $grammarName = $opts{grammarName} || 'ISO-ANSI-C-2011';

  my $grammar = MarpaX::Languages::C::AST::Grammar->new($grammarName, \%logInfo, $opts{start}, $opts{actionObject}, $opts{nonTerminalSemantic}, $opts{terminalSemantic});
  my $grammar_option = $grammar->grammar_option();
  $grammar_option->{bless_package} = 'C::AST';
  $grammar_option->{source} = \$grammar->content();
  my $recce_option = $grammar->recce_option();

  my $lexemeCallback = $opts{lexemeCallback} || '';
  my @lexemeCallbackArgs = ();
  if ($opts{lexemeCallback}) {
      if (ref($opts{lexemeCallback}) ne 'ARRAY') {
          croak 'lexemeCallback option must be an ARRAY reference';
      }
      if (! @{$opts{lexemeCallback}}) {
          croak 'lexemeCallback is a reference to an empty array';
      }
      if (ref($opts{lexemeCallback}->[0]) ne 'CODE') {
          croak 'lexemeCallback must start with a CODE reference';
      }
      @lexemeCallbackArgs = @{$opts{lexemeCallback}};
      $lexemeCallback = shift(@lexemeCallbackArgs);
  }

  my $typedef = $opts{typedef} || [];
  if (ref($typedef) ne 'ARRAY') {
      croak 'typedef must be a reference to ARRAY';
  }

  my $enum = $opts{enum} || [];
  if (ref($enum) ne 'ARRAY') {
      croak 'enum must be a reference to ARRAY';
  }

  my $lazy = $opts{lazy} || 0;

  my $self  = {
               _scope              => MarpaX::Languages::C::AST::Scope->new(),
               _grammar            => $grammar,
               _impl               => MarpaX::Languages::C::AST::Impl->new($grammar_option, $recce_option),
               _sourcep            => undef,
               _lexemeCallback     => $lexemeCallback,
               _lexemeCallbackArgs => \@lexemeCallbackArgs,
               _logInfo            => \%logInfo,
               _typedef            => $typedef,
               _enum               => $enum,
               _lazy               => $lazy,
               _start              => $opts{start}
              };

  bless($self, $class);

  $self->_init();

  return $self;
}

# ----------------------------------------------------------------------------------------

sub _init {
    my $self = shift;

    #
    # Insert known typedef and enum at the top-level scope
    #
    foreach (@{$self->{_typedef}}) {
        $self->scope->parseEnterTypedef($_, [0, length($_)]);
    }
    foreach (@{$self->{_enum}}) {
        $self->scope->parseEnterEnum($_, [0, length($_)]);
    }

    return;
}
# ----------------------------------------------------------------------------------------

sub _context {
    my $self = shift;

    my $context = $log->is_debug() ?
        sprintf("\n\nContext:\n\n%s", $self->{_impl}->show_progress()) :
        '';

    return $context;
}
# ----------------------------------------------------------------------------------------


sub parse {
  my ($self, $sourcep) = @_;

  $self->{_sourcep} = $sourcep;
  $self->{_callbackEvents} = MarpaX::Languages::C::AST::Callback::Events->new($self);

  my $max = length(${$sourcep});
  my $pos = $[;
  $self->_doPreprocessing($pos);
  eval {$pos = $self->{_impl}->read($sourcep, $pos)};
  if ($@) {
    my $origError = $@;
    #
    # The very first error could be at line 0 / column 0...
    #
    my $line_columnp = eval { lineAndCol($self->{_impl}) };
    if (! $@) {
      logCroak("%s\nLast position:\n\n%s%s", $origError, showLineAndCol(@{$line_columnp}, $self->{_sourcep}), $self->_context());
    } else {
      logCroak("%s", $origError);
    }
  }
  #
  # The following will be used by callbacks to avoid a call to lastCompleted:
  #
  # In Callback/Events.pm, it is clear that we need to retreive the lexeme value
  # in only one single case: directDeclaratorIdentifier$. This can be done
  # in a generic way using lastCompleted(), but this is cost a lot and this is not
  # needed! In fact, if you look to the grammar you will see that IDENTIFIER is
  # systematically paused before.It is only in _doPauseBeforeLexeme() that IDENTIFIER
  # can setted. so if _doPauseBeforeLexeme() is setting $self->{_lastIdentifier} value
  # everytime it is doing a lexeme_read() on IDENTIFIER, the directDeclaratorIdentifier$
  # event will be triggered and the directDeclaratorIdentifier LHS symbol value is
  # guaranteed to be what _doPauseBeforeLexeme() has used for its lexeme_read.
  #
  # This is because directDeclaratorIdentifier rule is made of only ONE rhs:
  #
  # directDeclaratorIdentifier ::= IDENTIFIER


  $self->{_lastIdentifier} = undef;
  do {
    my %lexeme = ();
    #
    # Note 1: it is very important that neither _getLexeme() or _doScope() could
    #         generate an event
    #
    $self->_getLexeme(\%lexeme);
    $self->_doScope(\%lexeme);
    $self->_doEvents();
    #
    # Note 2: Any routine below that could generate an event must call again
    #         _doEvents()
    #
    $self->_doAsmOpaque(\%lexeme, $pos, $max);
    $pos += $self->_doPauseBeforeLexeme(\%lexeme);
    $self->_doLogInfo(\%lexeme);
    $self->_doLexemeCallback(\%lexeme);
    $self->_doPreprocessing($pos);
    eval {$pos = $self->{_impl}->resume()};
    if ($@) {
        my $line_columnp = lineAndCol($self->{_impl});
        logCroak("%s\nLast position:\n\n%s%s", "$@", showLineAndCol(@{$line_columnp}, $self->{_sourcep}), , $self->_context());
    }
  } while ($pos < $max);

  return $self;
}

# ----------------------------------------------------------------------------------------

sub scope {
  my ($self) = @_;

  return $self->{_scope};
}


# ----------------------------------------------------------------------------------------
sub _show_last_expression {
  my ($self) = @_;

  my ($start, $end) = $self->{_impl}->last_completed_range('externalDeclaration');
  return 'No expression was successfully parsed' if (! defined($start));
  my $lastExpression = $self->{_impl}->range_to_string($start, $end);
  return "Last expression successfully parsed was: $lastExpression";
}
# ----------------------------------------------------------------------------------------


sub value {
  my ($self, $arrayOfValuesb) = @_;

  $arrayOfValuesb ||= 0;

  my @rc = ();

  my $valuep = $self->{_impl}->value() || logCroak('%s', $self->_show_last_expression());
  if (defined($valuep)) {
    push(@rc, $valuep);
  } else {
    logCroak('No parse tree  value.');
  }
  do {
      $valuep = $self->{_impl}->value();
      if (defined($valuep)) {
          if (! $arrayOfValuesb) {
              if ($self->{_lazy}) {
                  $log->infof('There is more than just one parse tree value, but lazy mode allow this.');
                  $valuep = undef;
              } else {
                  logCroak('There is more than just one parse tree value.');
              }
          }
          if (defined($valuep)) {
              push(@rc, $valuep);
          }
      }
  } while (defined($valuep));
  if ($arrayOfValuesb) {
    return \@rc;
  } else {
    return $rc[0];
  }
}
# ----------------------------------------------------------------------------------------
sub _doEvents {
  my $self = shift;

  my %events = ();
  my $iEvent = 0;
  while (defined($_ = $self->{_impl}->event($iEvent++))) {
    ++$events{$_->[0]};
  }

  if (%events) {
    my @events = keys %events;
    if ($log->is_debug) {
        $log->debugf('[%s] Events: %s', whoami(__PACKAGE__), \@events);
    }
    $self->{_callbackEvents}->exec(@events);
  }
}
# ----------------------------------------------------------------------------------------
sub _getLexeme {
  my ($self, $lexemeHashp) = @_;

  #
  # Get paused lexeme
  # Trustable if pause after
  # See _doPauseBeforeLexeme for the others
  #
  my $lexeme = $self->{_impl}->pause_lexeme();
  if (defined($lexeme)) {
    $lexemeHashp->{name} = $lexeme;
    ($lexemeHashp->{start}, $lexemeHashp->{length}) = $self->{_impl}->pause_span();
    ($lexemeHashp->{line}, $lexemeHashp->{column}) = $self->{_impl}->line_column($lexemeHashp->{start});
    $lexemeHashp->{value} = $self->{_impl}->literal($lexemeHashp->{start}, $lexemeHashp->{length});
  }

  return;
}
# ----------------------------------------------------------------------------------------
sub _doLogInfo {
  my ($self, $lexemeHashp) = @_;

  if (exists($lexemeHashp->{name}) && (exists($self->{_logInfo}->{$lexemeHashp->{name}}) || exists($self->{_logInfo}->{__ALL__}))) {
      if ($log->is_info) {
          $log->infof("[%8d:%3d] %-30s %s", $lexemeHashp->{line}, $lexemeHashp->{column}, $lexemeHashp->{name}, $lexemeHashp->{value});
      }
  }

  return;
}
# ----------------------------------------------------------------------------------------
sub _doLexemeCallback {
  my ($self, $lexemeHashp) = @_;

  if ($self->{_lexemeCallback} && exists($lexemeHashp->{name})) {
      my $callback = $self->{_lexemeCallback};
      &$callback(@{$self->{_lexemeCallbackArgs}}, $lexemeHashp);
  }

  return;
}
# ----------------------------------------------------------------------------------------
sub _doPreprocessing {
    my ($self, $pos) = @_;
    #
    # Until there is MarpaX::Languages::C::Preprocessor, any preprocessing line is
    # done HERE: embedding the preprocessing grammar IN C grammar is NOT the thing to do.
    # These are different grammars, different things. Try to do so, and this will cause
    # a lot of problems, you will see.
    # It has to be done in a separate phase.
    # Fortunately the C grammar is doing a pause on EVERY lexeme. So at every pause
    # (plus the very beginning), we do recognize ourself preprocessor directives.
    #
    # And if a preprocessor directive would not follow exactly a lexeme, too bad, we will
    # not catch it, letting Marpa silently discard it.
    #
    my $previous = pos(${$self->{_sourcep}});
    my $delta = 0;
    my $line = 1;
    if ($pos > $[) {
      my $line_columnp = lineAndCol($self->{_impl});
      $line = $line_columnp->[0];
    }

    pos(${$self->{_sourcep}}) = $pos;
    while (${$self->{_sourcep}} =~ m{\G(\s*^)(\#\s*(\S+)(?:\\.|[^\n])*)(\n|\Z)}smg) {
        my $start = $-[0];
        my $length = $+[0] - $-[0];
        my $match = substr(${$self->{_sourcep}}, $start, $length);
        my $pre = substr(${$self->{_sourcep}}, $-[1], $+[1] - $-[1]);
        my $preprocessorDirective = substr(${$self->{_sourcep}}, $-[2], $+[2] - $-[2]);
        my $directive = substr(${$self->{_sourcep}}, $-[3], $+[3] - $-[3]);
        my $lastChar = substr(${$self->{_sourcep}}, $-[4], $+[4] - $-[4]);
        if ($log->is_debug) {
            $log->debugf('Preprocessor: %s', $preprocessorDirective);
        }
        #
        # Last char is newline ?
        #
        if (length($lastChar) > 0) {
            #
            # We unshift so that next match will see this newline.
            # This is needed because a preprocessor directive must
          # start on a fresh new line up to EOF or another newline.
          # And we used the regexp upper to eat last newline.
            my $newPos = pos(${$self->{_sourcep}});
            $newPos--;
            pos(${$self->{_sourcep}}) = $newPos;
            $length--;
            substr($match, -1, 1, '');
        }
        #
        # Count the number of newlines we eated in $pre
        #
        $line += ($pre =~ tr/\n//);
        #
        # If this is a #line, fake a callback event PREPROCESSOR_LINE_DIRECTIVE
        #
        if ($directive eq 'line' || $directive =~ /^\d+$/) {
            my %lexeme = ();
            $lexeme{name} = 'PREPROCESSOR_LINE_DIRECTIVE';
            $lexeme{start} = $pos + $delta;
            $lexeme{length} = $length;
            $lexeme{line} = $line;
            $lexeme{column} = -1;       # we do not compute column, but send -1 instead of undef just in case
            $lexeme{value} = $match;
            $self->_doLexemeCallback(\%lexeme);
        }

        $delta += $length;
    }
    pos(${$self->{_sourcep}}) = $previous;

    return;
}
# ----------------------------------------------------------------------------------------
sub _doScope {
  my ($self, $lexemeHashp) = @_;

  #
  # Get paused lexeme
  #
  if (exists($lexemeHashp->{name})) {

    my $lexemeFormatString = "%s \"%s\" at position %d:%d";
    my @lexemeCommonInfo = ($lexemeHashp->{name}, $lexemeHashp->{value}, $lexemeHashp->{line}, $lexemeHashp->{column});
    my $is_debug = $log->is_debug;

    if (defined($self->{_callbackEvents}->topic_fired_data('fileScopeDeclarator'))) {
      if ($self->{_callbackEvents}->topic_fired_data('fileScopeDeclarator')->[0] == -1) {
        #
        # This will be for next round.
        #
          if ($is_debug) {
              $log->debugf('[%s] fileScopeDeclarator: flagging lookup required at next round.', whoami(__PACKAGE__));
          }
        $self->{_callbackEvents}->topic_fired_data('fileScopeDeclarator')->[0] = 1;

      } elsif ($self->{_callbackEvents}->topic_fired_data('fileScopeDeclarator')->[0] == 1) {
        #
        # Lookup what follows the file-scope declarator
        #
        if ($lexemeHashp->{name} ne 'COMMA' &&
            $lexemeHashp->{name} ne 'SEMICOLON' &&
            $lexemeHashp->{name} ne 'EQUAL') {
            if ($is_debug) {
                $log->debugf('[%s] fileScopeDeclarator: next lexeme is %s, flagging reenterScope.', whoami(__PACKAGE__), $lexemeHashp->{name});
            }
          $self->{_callbackEvents}->topic_fired_data('reenterScope')->[0] = 1;
        }
        #
        # Flag lookup done
        #
        if ($is_debug) {
            $log->debugf('[%s] fileScopeDeclarator: flagging lookup done.', whoami(__PACKAGE__));
        }
        $self->{_callbackEvents}->topic_fired_data('fileScopeDeclarator')->[0] = 0;
      }
    }

    if ($lexemeHashp->{name} eq 'LCURLY_SCOPE' || $lexemeHashp->{name} eq 'LPAREN_SCOPE') {
        if ($is_debug) {
            $log->debugf("[%s] $lexemeFormatString: entering scope.", whoami(__PACKAGE__), @lexemeCommonInfo);
        }
      $self->{_scope}->parseEnterScope();
    } elsif ($lexemeHashp->{name} eq 'RCURLY_SCOPE' || $lexemeHashp->{name} eq 'RPAREN_SCOPE') {
      if ($self->{_scope}->parseScopeLevel == 1) {
          if ($is_debug) {
              $log->debugf("[%s] $lexemeFormatString: delay leaving scope.", whoami(__PACKAGE__), @lexemeCommonInfo);
          }
        $self->{_scope}->parseExitScope(0);
      } else {
          if ($is_debug) {
              $log->debugf("[%s] $lexemeFormatString: immediate leaving scope.", whoami(__PACKAGE__), @lexemeCommonInfo);
          }
        $self->{_scope}->parseExitScope(1);
      }
    } else {
        if ($is_debug) {
            $log->debugf("[%s] $lexemeFormatString.", whoami(__PACKAGE__), @lexemeCommonInfo);
        }
      if ($self->{_scope}->parseScopeLevel == 1 && $self->{_scope}->parseDelay) {
        if (defined($self->{_callbackEvents}->topic_fired_data('reenterScope')) &&
            $self->{_callbackEvents}->topic_fired_data('reenterScope')->[0]) {
            if ($is_debug) {
                $log->debugf('[%s] reenterScope flag is on at scope 1.', whoami(__PACKAGE__));
            }
          $self->{_scope}->parseReenterScope();
            if ($is_debug) {
                $log->debugf('[%s] Unflagging reenterScope.', whoami(__PACKAGE__));
            }
          $self->{_callbackEvents}->topic_fired_data('reenterScope')->[0] = 0;
        } else {
            if ($is_debug) {
                $log->debugf('[%s] reenterScope flag is off at scope 1.', whoami(__PACKAGE__));
            }
          $self->{_scope}->doExitScope();
        }
      }
    }
  }

  return;
}
# ----------------------------------------------------------------------------------------
sub _doAsmOpaque {
  my ($self, $lexemeHashp, $pos, $max) = @_;

  #
  # Get paused lexeme
  #
  if (exists($lexemeHashp->{name})) {

    my $lexemeFormatString = "%s \"%s\" at position %d:%d";
    my @lexemeCommonInfo = ($lexemeHashp->{name}, $lexemeHashp->{value}, $lexemeHashp->{line}, $lexemeHashp->{column});
    my $is_debug = $log->is_debug;

    if ($lexemeHashp->{name} eq 'ANY_ASM') {
      if ($is_debug) {
        $log->debugf("[%s] $lexemeFormatString: checking for the need of ASM_OPAQUE at current position $pos", whoami(__PACKAGE__), @lexemeCommonInfo);
      }
      my $prevpos = pos(${$self->{_sourcep}});
      pos(${$self->{_sourcep}}) = $pos;
      if (${$self->{_sourcep}} =~ /\G${WS_RE}*\(/ ||
          ${$self->{_sourcep}} =~ /\G${WS_RE}+\w+${WS_RE}*\(/) {
        #
        # assume to be eventually GCC style ASM : supported in the BNF
        #
        my $style = substr(${$self->{_sourcep}}, $pos, $+[0] - $pos);
        if ($is_debug) {
          $log->debugf("[%s] $lexemeFormatString: GCC style detected %s%s...)", whoami(__PACKAGE__), @lexemeCommonInfo, $lexemeHashp->{value}, $style);
        }
      } elsif (${$self->{_sourcep}} =~ /\G${WS_RE}*\{/) {
        #
        # Opaque ASM block
        #
        my $tmpPos = $+[0];
        if ($is_debug) {
          $log->debugf("[%s] $lexemeFormatString: '{' detected.", whoami(__PACKAGE__), @lexemeCommonInfo);
        }
        #
        # We scan character per character until a matching '}'
        #
        my $found = substr(${$self->{_sourcep}}, $-[0], $+[0] - $-[0]);
        my $remain = 1;
        my $opaque = '';
        while ($tmpPos < $max) {
          pos(${$self->{_sourcep}}) = $tmpPos;
          if (${$self->{_sourcep}} =~ /\G$ASM_COMMENT_RE/) {
            #
            # Full comment in one regexp
            #
            my $posAfterComment = $+[0];
            my $comment = substr(${$self->{_sourcep}}, $tmpPos, $posAfterComment - $tmpPos);
            if ($is_debug) {
              $log->debugf("[%s] $lexemeFormatString: skipping comment %s", whoami(__PACKAGE__), @lexemeCommonInfo, $comment);
            }
            $found .= $comment;
            $tmpPos = $posAfterComment;
          } elsif (${$self->{_sourcep}} =~ /\GCOMMENT\s+([^\s])\s+/) {
            #
            # MSASM comment directive
            #
            my $delimiter = substr(${$self->{_sourcep}}, $-[1], $+[1] - $-[1]);
            pos(${$self->{_sourcep}}) = $-[1];
            if (${$self->{_sourcep}} =~ /\G(?:$RE{delimited}{-delim=>$delimiter})[^\n]*/) {
              my $posAfterComment = $+[0];
              my $comment = substr(${$self->{_sourcep}}, $tmpPos, $posAfterComment - $tmpPos);
              if ($is_debug) {
                $log->debugf("[%s] $lexemeFormatString: skipping comment %s", whoami(__PACKAGE__), @lexemeCommonInfo, $comment);
              }
              $found .= $comment;
              $tmpPos = $posAfterComment;
            } else {
              my $line_columnp = lineAndCol($self->{_impl});
              logCroak("[%s] Failed to find MSASM's COMMENT end delimiter %s.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $delimiter, showLineAndCol($lexemeHashp->{line}, $lexemeHashp->{column}, $self->{_sourcep}), $self->_context());
            }
          } elsif (${$self->{_sourcep}} =~ /\G['"]/) {
            #
            # MSASM string, no escape character
            #
            my $delimiter = substr(${$self->{_sourcep}}, $-[0], 1);
            pos(${$self->{_sourcep}}) = $-[0];
            if (${$self->{_sourcep}} =~ /\G(?:$RE{delimited}{-delim=>$delimiter})/) {
              my $posAfterString = $+[0];
              my $string = substr(${$self->{_sourcep}}, $tmpPos, $posAfterString - $tmpPos);
              if ($is_debug) {
                $log->debugf("[%s] $lexemeFormatString: skipping string %s", whoami(__PACKAGE__), @lexemeCommonInfo, $string);
              }
              $found .= $string;
              $tmpPos = $posAfterString;
            } else {
              my $line_columnp = lineAndCol($self->{_impl});
              logCroak("[%s] Failed to find MSASM's string delimiter %s.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $delimiter, showLineAndCol($lexemeHashp->{line}, $lexemeHashp->{column}, $self->{_sourcep}), $self->_context());
            }
          } else {
            my $c = substr(${$self->{_sourcep}}, $tmpPos, 1);
            if ($c eq '{') {
              ++$remain;
            } elsif ($c eq '}') {
              --$remain;
            }
            $found .= $c;
            ++$tmpPos;
            if ($remain == 0) {
              last;
            }
          }
        }
        if ($remain != 0) {
          $log->warnf("[%s] $lexemeFormatString: could not determine opaque asm statement", whoami(__PACKAGE__), @lexemeCommonInfo);
        } else {
          my $newlexeme = 'ASM_OPAQUE';
          if ($log->is_debug) {
              $log->debugf('[%s] Pushing lexeme %s "%s"', whoami(__PACKAGE__), $newlexeme, $found);
          }
          if (! defined($self->{_impl}->lexeme_read($newlexeme, $pos, length($found), $found))) {
              my $line_columnp = lineAndCol($self->{_impl});
              logCroak("[%s] Lexeme value \"%s\" cannot be associated to lexeme name %s at position %d:%d.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $found, $newlexeme, $lexemeHashp->{line}, $lexemeHashp->{column}, showLineAndCol(@{$line_columnp}, $self->{_sourcep}), $self->_context());
          }
          #
          # A lexeme_read() can generate an event
          #
          $self->_getLexeme($lexemeHashp);
          $self->_doEvents();
        }
      } elsif (${$self->{_sourcep}} =~ /\G[^\n]*/) {
        #
        # Could be an opaque ASM on a single line. If we are wrong, BNF will take over this wrong assumption
        # by invalidating the tree. Please note that this will handle eventual multiple __asm statements, all
        # on the same line -;
        #
        my $found = substr(${$self->{_sourcep}}, $-[0], $+[0] - $-[0]);
        my $newlexeme = 'ASM_OPAQUE';
        if ($log->is_debug) {
          $log->debugf('[%s] Pushing lexeme %s "%s"', whoami(__PACKAGE__), $newlexeme, $found);
        }
        if (! defined($self->{_impl}->lexeme_read($newlexeme, $pos, length($found), $found))) {
          my $line_columnp = lineAndCol($self->{_impl});
          logCroak("[%s] Lexeme value \"%s\" cannot be associated to lexeme name %s at position %d:%d.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $found, $newlexeme, $lexemeHashp->{line}, $lexemeHashp->{column}, showLineAndCol(@{$line_columnp}, $self->{_sourcep}), $self->_context());
        }
        #
        # A lexeme_read() can generate an event
        #
        $self->_getLexeme($lexemeHashp);
        $self->_doEvents();
      }
      pos(${$self->{_sourcep}}) = $prevpos;
    }
  }

  return;
}
# ----------------------------------------------------------------------------------------
sub _doPauseBeforeLexeme {
  my ($self, $lexemeHashp) = @_;

  my $delta = 0;

  #
  # Get paused lexeme
  #
  if (exists($lexemeHashp->{name})) {
      #
      # C grammar typedef/enumeration_constant/identifier ambiguity
      #
      if ($lexemeHashp->{name} eq 'TYPEDEF_NAME' ||
          $lexemeHashp->{name} eq 'ENUMERATION_CONSTANT' ||
          $lexemeHashp->{name} eq 'IDENTIFIER') {
          my @alternatives = ();
          #
          # Determine the correct lexeme
          #
          if ($self->{_lazy}) {
              if ($self->{_scope}->parseIsTypedef($lexemeHashp->{value})) {
                  @alternatives = qw/TYPEDEF_NAME IDENTIFIER/;
              } elsif ($self->{_scope}->parseIsEnum($lexemeHashp->{value})) {
                  @alternatives = qw/ENUMERATION_CONSTANT IDENTIFIER/;
              } else {
                  @alternatives = qw/TYPEDEF_NAME ENUMERATION_CONSTANT IDENTIFIER/;
              }
          } else {
              my %terminals_expected = map {$_ => 1} @{$self->{_impl}->terminals_expected()};
              if (exists($terminals_expected{TYPEDEF_NAME}) && $self->{_scope}->parseIsTypedef($lexemeHashp->{value})) {
                  push(@alternatives, 'TYPEDEF_NAME');
              } elsif (exists($terminals_expected{ENUMERATION_CONSTANT}) && $self->{_scope}->parseIsEnum($lexemeHashp->{value})) {
                  push(@alternatives, 'ENUMERATION_CONSTANT');
              } elsif (exists($terminals_expected{IDENTIFIER})) {
                  push(@alternatives, 'IDENTIFIER');
                  #
                  # Hack for the Callback framework: store in advance the IDENTIFIER, preventing
                  # a call to lastCompleted
                  #
                  $self->{_lastIdentifier} = $lexemeHashp->{value};
              }
          }
          if (! @alternatives) {
              my $line_columnp = lineAndCol($self->{_impl});
              logCroak("[%s] Lexeme value \"%s\" cannot be associated to TYPEDEF_NAME, ENUMERATION_CONSTANT nor IDENTIFIER at line %d, column %d.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $lexemeHashp->{value}, $lexemeHashp->{line}, $lexemeHashp->{column}, showLineAndCol($lexemeHashp->{line}, $lexemeHashp->{column}, $self->{_sourcep}), $self->_context());
          }
          #
          # Push the alternatives, more than one possible only if lazy mode is turned on
          #
          my @alternativesOk = ();
          my $is_debug = $log->is_debug;
          foreach (@alternatives) {
              if (defined($self->{_impl}->lexeme_alternative($_, $lexemeHashp->{value}))) {
                  push(@alternativesOk, $_);
                  if ($is_debug) {
                      $log->debugf('[%s] Pushed alternative %s "%s"', whoami(__PACKAGE__), $_, $lexemeHashp->{value});
                  }
                  if ($_ eq 'IDENTIFIER') {
                      $self->{_lastIdentifier} = $lexemeHashp->{value};
                  }
              } else {
                  if ($is_debug) {
                      $log->debugf('[%s] Failed alternative %s "%s"', whoami(__PACKAGE__), $_, $lexemeHashp->{value});
                  }
              }
          }
          if (! @alternativesOk) {
              my $line_columnp = lineAndCol($self->{_impl});
              logCroak("[%s] Lexeme value \"%s\" cannot be associated to %s at position %d:%d.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $lexemeHashp->{value}, \@alternatives, $lexemeHashp->{line}, $lexemeHashp->{column}, showLineAndCol(@{$line_columnp}, $self->{_sourcep}), $self->_context());
          }
          if (! defined($self->{_impl}->lexeme_complete($lexemeHashp->{start}, $lexemeHashp->{length}))) {
              my $line_columnp = lineAndCol($self->{_impl});
              logCroak("[%s] Lexeme value \"%s\" cannot be completed at position %d:%d.\n\nLast position:\n\n%s%s", whoami(__PACKAGE__), $lexemeHashp->{value}, $lexemeHashp->{line}, $lexemeHashp->{column}, showLineAndCol(@{$line_columnp}, $self->{_sourcep}), $self->_context());
          }
          $lexemeHashp->{name} = $alternativesOk[0];
          $delta = $lexemeHashp->{length};
          #
          # A lexeme_read() can generate an event
          #
          $self->_doEvents();
        }
    }

  return $delta;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST - Translate a C source to an AST

=head1 VERSION

version 0.47

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::C::AST;
    use Log::Log4perl qw/:easy/;
    use Log::Any::Adapter;
    use Log::Any qw/$log/;
    use Data::Dumper;
    #
    # Init log
    #
    our $defaultLog4perlConf = '
    log4perl.rootLogger              = WARN, Screen
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d %-5p %6P %m{chomp}%n
    ';
    Log::Log4perl::init(\$defaultLog4perlConf);
    Log::Any::Adapter->set('Log4perl');
    #
    # Parse C
    #
    my $cSourceCode = '
    typedef struct s1_ {int i1;} x1, y1;
    struct x1 {x1 i2;};
    x1 x;
    ';
    my $cAstObject = MarpaX::Languages::C::AST->new();
    $log->infof('%s', $cAstObject->parse(\$cSourceCode));

=head1 DESCRIPTION

This module translates C source into an AST tree. To assist further process of the AST tree, the nodes of the AST are blessed according to the C grammar you have selected. (The default is 'ISO-ANSI-C-2011'.) If you want to enable logging, be aware that this module is a Log::Any thingy.

This module implements the full syntax, as well as those specification constraints which are syntactic in nature: Associativity of nested if-then-else statements is according to the C standards, as is the treatment of names as typedefs, enums, or variable identifiers.

The C standards contain many constraints that are non-syntactic. MarpaX::Languages::C::AST does not implement these, leaving them for AST post-process. One example of a non-syntactic constraint is the requirement that labeled statements within a function be unique. Another is the requirement that declarations include at most one storage class specifier.

=head1 SUBROUTINES/METHODS

=head2 new($class, %options)

Instantiate a new object. Takes as parameter an optional hash of options that can be:

=over

=item grammarName

Name of a grammar. Default is 'ISO-ANSI-C-2011'.

=item typedef

An array reference to a list of known typedefs, injected at top scope before parsing start. This option should I<not> be used unless you pass a C source that is incomplete. Typically something that has not gone through a preprocessor. Default is [] i.e. empty list.

=item enum

An array reference to a list of known enums, injected at top scope before parsing start. Alike for typedef, this option should I<not> be used unless you pass a C source that is incomplete. Typically something that has not gone through a preprocessor. Default is [] i.e. empty list.

=item lazy

A flag saying the parser to inject automatically all allowed alternatives when the grammar reaches a TYPEDEF_NAME/ENUMERATION_CONSTANT/IDENTIFIER ambiguity. This option should be used in practice only when you are parsing a source code not pre-processed. Please note that I<if> lazy mode is on, there might be several parse tree values. In such a case, unless the option $optionalArrayOfValuesb of the value() method is true, the first of the parse tree values will be returned. If more than one alternative is accepted, the lexemeCallback (see below) will be, in order of preference, either TYPEDEF_NAME, ENUMERATION_CONSTANT or IDENTIFIER. The lazy mode can produce more than one parse tree value. The options typedef and enum (see upper) can be used to help lazy mode choose between TYPEDEF_NAME and ENUMERATION_CONSTANT, while IDENTIFIER will always be pushed as an alternative. Default is a false value.

=item start

A string giving the starting point of the grammar. This should be used when you know that the source code to parse is not a full valid source, but a portion of if. This requires knowledge of the grammar rules. Default is empty string: '', i.e. let the grammar apply its default start rule.

Please note that giving another value but 'translationUnit' will emit warnings from the grammar, saying that some rules are not reachable.

=item actionObject

Grammar specific action object.

=item nonTerminalSemantic

Grammar specific non-terminal semantic action.

=item terminalSemantic

Grammar specific terminal semantic action.

=item logInfo

Reference to an array of lexemes for which a log of level INFO will be issued.

=item lexemeCallback

Array reference containing a CODE ref and optional arguments. This callback will be trigerred like this: &$CODE(@arguments, $lexemeHashp), where $lexemeHashp is a reference to a hash describing current lexeme:

=over

=item name

Name of the lexeme. You have to refer to the grammar used to get its definition, although this is usually self-explanatory.

=item start

G1 (Marpa term) start location.

=item length

Length of the lexeme

=item line

Line number in the source being parsed.

=item column

Column number in the source being parsed.

=item value

String containing lexeme value.

=back

=back

=head2 parse($self, $sourcep)

Do the parsing. Takes as parameter the reference to a C source code. Returns $self, so that chaining with value method will be natural, i.e. parse()->value().

=head2 scope($self)

Returns the MarpaX::Languages::C::AST::Scope object.

=head2 value($self, $optionalArrayOfValuesb)

Return the blessed value. Takes as optional parameter a flag saying if the return value should be an array of all values or not. If this flag is false, the module will croak if there more than one parse tree value. If this flag is true, a reference to an array of values will be returned, even if there is a single parse tree value.

=head1 INCOMPATIBILITIES

Since version 0.30, the c2ast.pl script is named c2ast (i.e. without extension).

=head1 NOTES

C code can have inline ASM code. The GCC Inline Assembly is fully supported, any other is falling into a heuristic that should catch everything needed. CL inline assemblies have been targeted in particular.

=head1 SEE ALSO

L<Log::Any>, L<Marpa::R2>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-Languages-C-AST>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/jddurand/marpax-languages-c-ast>

  git clone git://github.com/jddurand/marpax-languages-c-ast.git

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 CONTRIBUTORS

=for stopwords Ben Bullock Ivan Baidakou Jeffrey Kegler jddurand

=over 4

=item *

Ben Bullock <benkasminbullock@gmail.com>

=item *

Ivan Baidakou <basiliscos@openmailbox.com>

=item *

Jeffrey Kegler <JKEGL@cpan.org>

=item *

Jeffrey Kegler <jkegl@cpan.org>

=item *

jddurand <jeandamiendurand@free.fr>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
