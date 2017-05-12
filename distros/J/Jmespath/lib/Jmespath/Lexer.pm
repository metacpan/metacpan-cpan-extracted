package Jmespath::Lexer;
use strict;
use warnings;
use Jmespath::LexerException;
use Jmespath::EmptyExpressionException;
use JSON;
use String::Util qw(trim);
use List::Util qw(any);
use Try::Tiny;
use utf8;
use feature 'unicode_strings';

our $START_IDENTIFIER = ['A'..'Z','a'..'z','_'];
our $VALID_IDENTIFIER = ['A'..'Z','a'..'z',0..9,'_'];
our $VALID_NUMBER = [0..9];
our $WHITESPACE = [' ', "\t", "\n", "\r"];
our $SIMPLE_TOKENS = { '.' => 'dot',
                       '*' => "star",
                       ']' => 'rbracket',
                       ',' => 'comma',
                       ':' => 'colon',
                       '@' => 'current',
                       '(' => 'lparen',
                       ')' => 'rparen',
                       '{' => 'lbrace',
                       '}' => 'rbrace', };
our $BACKSLASH = "\\";

sub new {
  my ( $class ) = @_;
  my $self = bless {}, $class;
  $self->{STACK} = [];
  return $self;
}

sub stack {
  my $self = shift;
  return $self->{STACK};
}

sub tokenize {
  my ( $self, $expression ) = @_;
  Jmespath::EmptyExpressionError->new->throw
      if not defined $expression;
  $self->{STACK} = [];
  $self->{_position} = 0;
  $self->{_expression} = $expression;
  @{$self->{_chars}} = split //, $expression;
  $self->{_current} = @{$self->{_chars}}[$self->{_position}];
  $self->{_length} = length $expression;

  while (defined $self->{_current}) {
    if    ( any { $_ eq $self->{_current} } keys %$SIMPLE_TOKENS ) {
      push  @{$self->{STACK}},
        { type  => $SIMPLE_TOKENS->{ $self->{_current} },
          value => $self->{_current},
          start => $self->{_position},
          end   => $self->{_position} + 1 };
      $self->_next;
    }

    elsif ( any { $_ eq $self->{_current} } @$START_IDENTIFIER ) {
      my $start = $self->{_position};
      my $buff = $self->{_current};
      my $next;
      while ( $self->_has_identifier( $self->_next, $VALID_IDENTIFIER )) {
        $buff .= $self->{_current};
      }
      push @{$self->{STACK}},
        { type  => 'unquoted_identifier',
          value => $buff,
          start => $start,
          end   => $start + length $buff };
    }

    elsif ( any { $_ eq $self->{_current} } @$WHITESPACE ) {
      $self->_next;
    }

    elsif ( $self->{_current} eq q/[/ ) {
      my $start = $self->{_position};
      my $next_char = $self->_next;
      # use Data::Dumper;
      # print Dumper $next_char;
      # if not defined $next_char;
      if (not defined $next_char) {
        Jmespath::LexerException->new( lexer_position => $start,
                                       lexer_value => $self->{_current},
                                       message => "Unexpected end of expression" )->throw;
      }
      elsif ( $next_char eq q/]/ ) {
        $self->_next;
        push @{$self->{STACK}},
          { type  => 'flatten',
            value => '[]',
            start => $start,
            end   => $start + 2 };
      }
      elsif ( $next_char eq q/?/ ) {
        $self->_next;
        push @{$self->{STACK}},
          { type  => 'filter',
            value => '[?',
            start => $start,
            end   => $start + 2 };
      }

      else {
        push @{$self->{STACK}},
          { type  => 'lbracket',
            value => '[',
            start => $start,
            end   => $start + 1 };
      }
    }

    elsif ( $self->{_current} eq q/'/ ) {
      push @{$self->{STACK}},
        $self->_consume_raw_string_literal;
    }

    elsif ( $self->{_current} eq q/|/ ) {
      push @{$self->{STACK}},
        $self->_match_or_else('|', 'or', 'pipe');
    }

    elsif ( $self->{_current} eq q/&/ ) {
      push @{$self->{STACK}},
        $self->_match_or_else('&', 'and', 'expref');
    }

    elsif ( $self->{_current} eq q/`/ ) {
      push @{$self->{STACK}},
        $self->_consume_literal;
    }

    elsif ( any {$_ eq $self->{_current} } @$VALID_NUMBER ) {
      my $start = $self->{_position};
      my $buff = $self->_consume_number;
      push @{$self->{STACK}},
        { type  => 'number',
          value => $buff,
          start => $start,
          end   => $start + length $buff };
    }

    # negative number
    elsif ( $self->{_current} eq q/-/ ) {
      my $start = $self->{_position};
      my $buff = $self->_consume_number;
      if (length $buff > 1) {
        push @{$self->{STACK}},
        { type  => 'number',
          value => $buff,
          start => $start,
          end   => $start + length $buff };
      }
      else {
        Jmespath::LexerException->new( lexer_position => $start,
                                       lexer_value => $buff,
                                       message => "Unknown token '$buff'" )->throw;
      }
    }

    elsif ( $self->{_current} eq q/"/ ) {
      push @{$self->{STACK}}, $self->_consume_quoted_identifier;
    }

    elsif ( $self->{_current} eq q/</ ) {
      push @{$self->{STACK}}, $self->_match_or_else('=', 'lte', 'lt');
    }

    elsif ( $self->{_current} eq q/>/ ) {
      push @{$self->{STACK}}, $self->_match_or_else('=', 'gte', 'gt');
    }

    elsif ( $self->{_current} eq q/!/ ) {
      push @{$self->{STACK}}, $self->_match_or_else('=', 'ne', 'not');
    }

    elsif ( $self->{_current} eq q/=/ ) {
      if ($self->_next eq '=') {
        push @{$self->{STACK}},
          { type  => 'eq',
            value => '==',
            start => $self->{_position} - 1,
            end   => $self->{_position} };
        $self->_next;
      }
      else {
        Jmespath::LexerException->new( lexer_position => $self->{_position} - 1,
                                       lexer_value => '=',
                                       message => 'Unknown token =' )->throw;
      }
    }
    else {
      Jmespath::LexerException->new( lexer_position => $self->{_position},
                                     lexer_value => $self->{_current},
                                     message => 'Unknown token ' . $self->{_current})->throw;
    }
  }
  push @{$self->{STACK}},
    { type  => 'eof',
      value => '',
      start => $self->{_length},
      end   => $self->{_length} };
  return $self->{STACK};
}

sub _consume_number {
  my ($self) = @_;
  my $start = $self->{_position};
  my $buff = $self->{_current};
  while ( $self->_has_identifier( $self->_next, $VALID_NUMBER)) {
    $buff .= $self->{_current};
  }
  return $buff;
}

sub _has_identifier {
  my ($self, $value, $identifier) = @_;
  return 0 if not defined $value;
  return 1 if any { $_ eq $value  } @$identifier;
  return 0;
}

sub _next {
  my ($self) = @_;
  if ( $self->{_position} == $self->{_length} - 1 ) {
    $self->{_current} = undef;
  }
  else {
    $self->{_position} += 1;
    $self->{_current} = @{$self->{_chars}}[$self->{_position}];
  }
  return $self->{_current};
}

sub _consume_until {
  my ($self, $delimiter) = @_;
  my $start = $self->{_position};
  my $buff = '';
  $self->_next;
  while ($self->{_current} ne $delimiter ) {
    if ($self->{_current} eq $BACKSLASH) {
      $buff .= $BACKSLASH;
      # Advance to escaped character.
      $self->_next;
    }
    $buff .= $self->{_current};
    $self->_next;
    if (not defined $self->{_current}) {
      Jmespath::LexerException
          ->new( lexer_position => $start,
                 lexer_value => $self->{_expression},
                 message => "Unclosed delimiter $delimiter" )
          ->throw;
    }
  }
  $self->_next;
  return $buff;
}

sub _consume_literal {
  my ($self) = @_;
  my $start = $self->{_position};
  my $lexeme = $self->_consume_until('`');
  $lexeme  =~ s/\\`/`/;
  my $parsed_json;
  try {
    $parsed_json = JSON->new->allow_nonref->decode($lexeme);
  } catch {
    try {
      $parsed_json = JSON->new->allow_nonref->decode('"' . trim($lexeme) . '"');
    } catch {
      Jmespath::LexerException->new( lexer_position => $start,
                                     lexer_value => $self->{_expression},
                                     message => "Bad token $lexeme" )->throw;
    };
  };

  my $token_len = $self->{_position} - $start;
  return { type  => 'literal',
           value => $parsed_json,
           start => $start,
           end   => $token_len, };
}

sub _consume_quoted_identifier {
  my ( $self ) = @_;
  my $start = $self->{_position};
  my $lexeme = '"' . $self->_consume_until('"') . '"';
  my $error = "error consuming quoted identifier";
  my $decoded_lexeme;

  try {
    $decoded_lexeme = JSON->new->allow_nonref->decode($lexeme);
  } catch {
    Jmespath::LexerException->new( lexer_position => $start,
                                   expression => $lexeme,
                                   message => $error )->throw;
  };
  return { type => 'quoted_identifier',
           value => $decoded_lexeme,
           start => $start,
           end   => $self->{ _position } - $start,
         };
}

sub _consume_raw_string_literal {
  my ( $self ) = @_;
  my $start = $self->{ _position };
  my $lexeme = $self->_consume_until("'"); $lexeme =~ s/\\\'/\'/g;
  my $token_len = $self->{_position} - $start;
  return { 'type' => 'literal',
           'value' => $lexeme,
           'start' => $start,
           'end' => $token_len,
         };
}


sub _match_or_else {
  my ( $self, $expected, $match_type, $else_type) = @_;
  my $start = $self->{_position};
  my $current = $self->{_current};
  my $next_char = $self->_next;
  if ( not defined $next_char or
       $next_char ne $expected ) {
    return { 'type' => $else_type,
             'value' => $current,
             'start' => $start,
             'end' => $start,
           };
  }

  $self->_next();
  return { 'type' => $match_type,
           'value' => $current . $next_char,
           'start' => $start,
           'end' => $start + 1,
         };
}


1;
