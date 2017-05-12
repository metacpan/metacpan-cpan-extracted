package Jmespath::Parser;
use strict;
use warnings;
use Jmespath;
use Jmespath::Lexer;
use Jmespath::Ast;
use Jmespath::Visitor;
use Jmespath::ParsedResult;
use Jmespath::IncompleteExpressionException;
use List::Util qw(any);
use Try::Tiny;

my $BINDING_POWER = { 'eof' => 0,
                      'unquoted_identifier' => 0,
                      'quoted_identifier' => 0,
                      'literal' => 0,
                      'rbracket' => 0,
                      'rparen' => 0,
                      'comma' => 0,
                      'rbrace' => 0,
                      'number' => 0,
                      'current' => 0,
                      'expref' => 0,
                      'colon' => 0,
                      'pipe' => 1,
                      'or' => 2,
                      'and' => 3,
                      'eq' => 5,
                      'gt' => 5,
                      'lt' => 5,
                      'gte' => 5,
                      'lte' => 5,
                      'ne' => 5,
                      'flatten' => 9,
                      # Everything above stops a projection.
                      'star' => 20,
                      'filter' => 21,
                      'dot' => 40,
                      'not' => 45,
                      'lbrace' => 50,
                      'lbracket' => 55,
                      'lparen' => 60 };

# The maximum binding power for a token that can stop
# a projection.
my $PROJECTION_STOP = 10;
# The _MAX_SIZE most recent expressions are cached in
# _CACHE hash.
my $CACHE = {};
my $MAX_SIZE = 128;

sub new {
  my ( $class, $lookahead ) = @_;
  my $self = bless {}, $class;
  $lookahead = 2 if not defined $lookahead;
  $self->{ tokenizer } = undef;
  $self->{ tokens } = [ undef ] * $lookahead;
  $self->{ buffer_size } = $lookahead;
  $self->{ index } = 0;
  return $self;
}

sub parse {
  my ($self, $expression) = @_;

  my $cached = $self->{_CACHE}->{$expression};
  return $cached if defined $cached;

  my $parsed_result = $self->_do_parse($expression);

  $self->{_CACHE}->{expression} = $parsed_result;
  if (scalar keys %{$self->{_CACHE}} > $MAX_SIZE) {
    $self->_free_cache_entries;
  }
  return $parsed_result;
}

sub _do_parse {
  my ( $self, $expression ) = @_;
  my $parsed;
  try {
    $parsed = $self->_parse($expression);
  } catch {
    if ($_->isa('Jmespath::LexerException')) {
      $_->expression($self->{_expression});
      $_->throw;
    }
    elsif ($_->isa('Jmespath::IncompleteExpressionException')) {
      $_->expression($self->{_expression});
      $_->throw;
    }
    elsif ($_->isa('Jmespath::ParseException')) {
      $_->expression($self->{_expression});
      $_->throw;
    }
    else {
      $_->throw;
    }
  };
  return $parsed;
}

sub _parse {
  my ( $self, $expression ) = @_;
  $self->{_expression} = $expression;
  $self->{_index}      = 0;
  $self->{_tokens}     = Jmespath::Lexer->new->tokenize($expression);

  my $parsed = $self->_expression(0); #binding_power = 0
  if ($self->_current_token_type ne 'eof') {
    my $t = $self->_lookahead_token(0);
    return Jmespath::ParseException->new(lex_position => $t->{start},
                                         token_value => $t->{value},
                                         token_type => $t->{type},
                                         message => "Unexpected token: " . $t->{value})->throw;
  }

  return Jmespath::ParsedResult->new($expression, $parsed);
}


sub _expression {
  my ( $self, $binding_power ) = @_;
  $binding_power = defined $binding_power ? $binding_power : 0;

  # Get the current token under evaluation
  my $left_token = $self->_lookahead_token(0);

  # Advance the token index
  $self->_advance;

  my $nud_function = \&{'_token_nud_' . $left_token->{type}};
  if ( not defined &$nud_function ) { $self->_error_nud_token($left_token); }

  my $left_ast = &$nud_function($self, $left_token);
  my $current_token = $self->_current_token_type;

  while ( $binding_power < $BINDING_POWER->{$current_token} ) {
    my $led = \&{'_token_led_' . $current_token};

    if (not defined &$led) {
      $self->_error_led_token($self->_lookahead_token(0));
    }
    else {
      $self->_advance;
      $left_ast = &$led($self, $left_ast);
      $current_token = $self->_current_token_type;
    }
  }
  return $left_ast;
}

sub _token_nud_literal {
  my ($self, $token) = @_;
  return Jmespath::Ast->literal($token->{value});
}

sub _token_nud_unquoted_identifier {
  my ($self, $token) = @_;
  return Jmespath::Ast->field($token->{value});
}

sub _token_nud_quoted_identifier {
  my ($self, $token) = @_;

  my $field = Jmespath::Ast->field($token->{value});

  # You can't have a quoted identifier as a function name.
  if ( $self->_current_token_type eq 'lparen' ) {
    my $t = $self->_lookahead_token(0);
    Jmespath::ParseException
        ->new( lex_position => 0,
               token_value => $t->{value},
               token_type => $t->{type},
               message => 'Quoted identifier not allowed for function names.')
        ->throw;
  }
  return $field;
}

sub _token_nud_star {
  my ($self, $token) = @_;
  my $left = Jmespath::Ast->identity;
  my $right;
  if ( $self->_current_token_type eq 'rbracket' ) {
    $right = Jmespath::Ast->identity;
  }
  else {
    $right = $self->_parse_projection_rhs( $BINDING_POWER->{ star } );
  }
  return Jmespath::Ast->value_projection($left, $right);
}

sub _token_nud_filter {
  my ($self, $token) = @_;
  return $self->_token_led_filter(Jmespath::Ast->identity);
}

sub _token_nud_lbrace {
  my ($self, $token) = @_;
  return $self->_parse_multi_select_hash;
}

sub _token_nud_lparen {
  my ($self, $token) = @_;
  my $expression = $self->_expression;
  $self->_match('rparen');
  return $expression;
}

sub _token_nud_flatten {
  my ($self, $token) = @_;
  my $left = Jmespath::Ast->flatten(Jmespath::Ast->identity);
  my $right = $self->_parse_projection_rhs( $BINDING_POWER->{ flatten } );
  return Jmespath::Ast->projection($left, $right);
}

sub _token_nud_not {
  my ($self, $token) = @_;
  my $expr = $self->_expression( $BINDING_POWER->{ not } );
  return Jmespath::Ast->not_expression($expr);
}

sub _token_nud_lbracket {
  my ($self, $token) = @_;
  if (any { $_ eq $self->_current_token_type } qw(number colon)) {
    my $right = $self->_parse_index_expression;
    return $self->_project_if_slice(Jmespath::Ast->identity, $right);
  }
  elsif ($self->_current_token_type eq 'star' and
         $self->_lookahead(1) eq 'rbracket') {
    $self->_advance;
    $self->_advance;
    my $right = $self->_parse_projection_rhs( $BINDING_POWER->{ star } );
    return Jmespath::Ast->projection(Jmespath::Ast->identity, $right);
  }
  else {
    return $self->_parse_multi_select_list;
  }
}

sub _parse_index_expression {
  my ($self) = @_;
  # We're here:
  # [<current>
  #  ^
  #  | current token
  if ($self->_lookahead(0) eq 'colon' or
      $self->_lookahead(1) eq 'colon') {
    return $self->_parse_slice_expression;
  }
  else {
    #parse the syntax [number]
    my $node = Jmespath::Ast->index_of($self->_lookahead_token(0)->{value});
    $self->_advance;
    $self->_match('rbracket');
    return $node;
  }
}

sub _parse_slice_expression {
  my ($self) = @_;
  # [start:end:step]
  # Where start, end, and step are optional.
  # The last colon is optional as well.
  my @parts = (undef, undef, undef);
  my $index = 0;
  my $current_token = $self->_current_token_type;
  while ($current_token ne 'rbracket' and $index < 3) {
    if ($current_token eq 'colon') {
      $index += 1;
      if ( $index == 3 ) {
        $self->_raise_parse_error_for_token($self->_lookahead_token(0),
                                            'syntax error');
      }
      $self->_advance;
    }
    elsif ($current_token eq 'number') {
      $parts[$index] = $self->_lookahead_token(0)->{value};
      $self->_advance;
    }
    else {
      $self->_raise_parse_error_for_token( $self->_lookahead_token(0),
                                           'syntax error');
      $current_token = $self->_current_token_type;
    }
    $current_token = $self->_current_token_type;
  }
  $self->_match('rbracket');
  return Jmespath::Ast->slice(@parts);
}

sub _token_nud_current {
  my ($self, $token) = @_;
  return Jmespath::Ast->current_node;
}

sub _token_nud_expref {
  my ($self, $token) = @_;
  my $expression = $self->_expression( $BINDING_POWER->{ expref } );
  return Jmespath::Ast->expref($expression);
}

sub _token_led_dot {
  my ($self, $left) = @_;

  if ($self->_current_token_type ne 'star') {

    # Begin the evaluation of the subexpression.
    my $right = $self->_parse_dot_rhs( $BINDING_POWER->{ dot } );

    if ($left->{type} eq 'subexpression') {
      push  @{$left->{children}}, $right;
      return $left;
    }

    # We have identified a subexpression, but the current AST is not a
    # subexpression.  Convert to a subexpression here.
    return Jmespath::Ast->subexpression([$left, $right]);
  }
  $self->_advance;
  my $right = $self->_parse_projection_rhs( $BINDING_POWER->{ dot } );
  return Jmespath::Ast->value_projection($left, $right);
}

sub _token_led_pipe {
  my ($self, $left) = @_;
  my $right = $self->_expression( $BINDING_POWER->{ pipe } );
  return Jmespath::Ast->pipe_oper($left, $right);
}

sub _token_led_or {
  my ($self, $left) = @_;
  my $right = $self->_expression( $BINDING_POWER->{ or } );
  return Jmespath::Ast->or_expression($left, $right);
}

sub _token_led_and {
  my ($self, $left) = @_;
  my $right = $self->_expression( $BINDING_POWER->{ and } );
  return Jmespath::Ast->and_expression($left, $right);
}

sub _token_led_lparen {
  my ($self, $left) = @_;
  if ( $left->{type} ne 'field' ) {
    #  0 - first func arg or closing paren.
    # -1 - '(' token
    # -2 - invalid function "name".
    my $prev_t = $self->_lookahead_token(-2);
    my $message = "Invalid function name '" . $prev_t->{value} ."'";
    Jmespath::ParseException
        ->new( lex_position => $prev_t->{start},
               token_value => $prev_t->{value},
               token_type => $prev_t->{type},
               message => $message)
        ->throw;
  }
  my $name = $left->{value};
  my $args = [];
  while (not $self->_current_token_type eq 'rparen') {
    my $expression = $self->_expression;
    if ( $self->_current_token_type eq 'comma') {
      $self->_match('comma');
    }
    push @$args, $expression;
  }
  $self->_match('rparen');
  return Jmespath::Ast->function_expression($name, $args);
}

sub _token_led_filter {
  my ($self, $left) = @_;
  my $right;
  my $condition = $self->_expression(0);
  $self->_match('rbracket');
  if ( $self->_current_token_type eq 'flatten' ) {
    $right = Jmespath::Ast->identity;
  }
  else {
    $right = $self->_parse_projection_rhs( $BINDING_POWER->{ filter } );
  }

  return Jmespath::Ast->filter_projection($left, $right, $condition);
}

sub _token_led_eq {
  my ($self, $left) = @_;
  return $self->_parse_comparator($left, 'eq');
}

sub _token_led_ne {
  my ($self, $left) = @_;
  return $self->_parse_comparator($left, 'ne');
}

sub _token_led_gt {
  my ($self, $left) = @_;
  return $self->_parse_comparator($left, 'gt');
}

sub _token_led_gte {
  my ($self, $left) = @_;
  return $self->_parse_comparator($left, 'gte');
}

sub _token_led_lt {
  my ($self, $left) = @_;
  return $self->_parse_comparator($left, 'lt');
}

sub _token_led_lte {
  my ($self, $left) = @_;
  return $self->_parse_comparator($left, 'lte');
}

sub _token_led_flatten {
  my ($self, $left) = @_;
  $left = Jmespath::Ast->flatten($left);
  my $right = $self->_parse_projection_rhs( $BINDING_POWER->{ flatten } );
  return Jmespath::Ast->projection($left, $right);
}

sub _token_led_lbracket {
  my ($self, $left) = @_;
  my $token = $self->_lookahead_token(0);
  if ( any { $_ eq $token->{type}} qw(number colon) ) {
    my $right = $self->_parse_index_expression();
    if ($left->{type} eq 'index_expression') {
      push @{$left->{children}}, $right;
      return $left;
    }
    return $self->_project_if_slice($left, $right);
  }
  else {
    $self->_match('star');
    $self->_match('rbracket');
    my $right = $self->_parse_projection_rhs( $BINDING_POWER->{ star } );
    return Jmespath::Ast->projection($left, $right);
  }
}

sub _project_if_slice {
  my ($self, $left, $right) = @_;
  my $index_expr = Jmespath::Ast->index_expression([$left, $right]);
  if ( $right->{type} eq 'slice' ) {
    return Jmespath::Ast->projection( $index_expr,
                                      $self->_parse_projection_rhs($BINDING_POWER->{star}));
  }

  return $index_expr;
}

sub _parse_comparator {
  my ($self, $left, $comparator) = @_;
  my $right = $self->_expression( $BINDING_POWER->{ $comparator } );
  return Jmespath::Ast->comparator($comparator, $left, $right);
}

sub _parse_multi_select_list {
  my ($self) = @_;
  my $expressions = [];
  my $result;
  try {
    while (1) {
      my $expression = $self->_expression;
      push @$expressions, $expression;
      last if ($self->_current_token_type eq 'rbracket');
      $self->_match('comma');
    }
    $self->_match('rbracket');
    $result = Jmespath::Ast->multi_select_list($expressions);
  } catch {
    $_->throw;
  };
  return $result;
}


sub _parse_multi_select_hash {
  my ($self) = @_;
  my @pairs;
  while (1) {
    my $key_token = $self->_lookahead_token(0);
    # Before getting the token value, verify it's
    # an identifier.
    $self->_match_multiple_tokens( [ 'quoted_identifier', 'unquoted_identifier' ]);
    my $key_name = $key_token->{ value };
    $self->_match('colon');
    my $value = $self->_expression(0);
    my $node = Jmespath::Ast->key_val_pair( $key_name,
                                            $value );
    push @pairs, $node;
    if ( $self->_current_token_type eq 'comma' ) {
      $self->_match('comma');
    }
    elsif ( $self->_current_token_type eq 'rbrace' ) {
      $self->_match('rbrace');
      last;
    }
  }
  return Jmespath::Ast->multi_select_hash(\@pairs);
}

sub _parse_projection_rhs {
  my ($self, $binding_power) = @_;
  if ( $BINDING_POWER->{ $self->_current_token_type } < $PROJECTION_STOP) {
    return Jmespath::Ast->identity();
  }
  elsif ($self->_current_token_type eq 'lbracket') {
    return $self->_expression( $binding_power );
  }
  elsif ($self->_current_token_type eq 'filter') {
    return $self->_expression( $binding_power );
  }
  elsif ($self->_current_token_type eq 'dot') {
    $self->_match('dot');
    return $self->_parse_dot_rhs($binding_power);
  }

  $self->_raise_parse_error_for_token($self->_lookahead_token(0),
                                      'syntax error');
  return;
}

sub _parse_dot_rhs {
  my ($self, $binding_power) = @_;
  # From the grammar:
  # expression '.' ( identifier /
  #                  multi-select-list /
  #                  multi-select-hash /
  #                  function-expression /
  #                  *
  # In terms of tokens that means that after a '.',
  # you can have:
  #  my $lookahead = $self->_current_token_type;

  # What token do we have next in the index
  my $lookahead = $self->_current_token_type;

  # Common case "foo.bar", so first check for an identifier.
  if ( any { $_ eq $lookahead } qw(quoted_identifier unquoted_identifier star) ) {
    return $self->_expression( $binding_power );
  }
  elsif ( $lookahead eq 'lbracket' ) {
    $self->_match('lbracket');
    return $self->_parse_multi_select_list;
  }
  elsif ( $lookahead eq 'lbrace' ) {
    $self->_match('lbrace');
    return $self->_parse_multi_select_hash;
  }

  my $t = $self->_lookahead_token(0);
  my @allowed = qw(quoted_identifier unquoted_identified lbracket lbrace);
  my $msg = 'Expecting: ' . join(' ', @allowed) . ', got: ' . $t->{ type };
  $self->_raise_parse_error_for_token( $t, $msg )->throw;
  return;
}

sub _error_nud_token {
  my ($self, $token) = @_;
  if ( $token->{type} eq 'eof' ) {
    Jmespath::IncompleteExpressionException->new( lex_expression => $token->{ start },
                                                  token_value => $token->{ value },
                                                  token_type => $token->{ type } )->throw;
  }
  $self->_raise_parse_error_for_token($token, 'invalid token');
  return;
}

sub _error_led_token {
  my ($self, $token) = @_;
  $self->_raise_parse_error_for_token($token, 'invalid token');
  return;
}

sub _match {
  my ($self, $token_type) = @_;
  if ($self->_current_token_type eq $token_type ) {
    $self->_advance();
  }
  else {
    $self->_raise_parse_error_maybe_eof( $token_type,
                                         $self->_lookahead_token(0) )->throw;
  }
  return;
}

sub _match_multiple_tokens {
  my ( $self, $token_types ) = @_;

  if ( not any { $_ eq $self->_current_token_type } @$token_types ) {
    $self->_raise_parse_error_maybe_eof( $token_types,
                                         $self->_lookahead_token(0) );
  }

  $self->_advance();
  return;
}

sub _advance {
  my ($self) = @_;
  $self->{ _index } += 1;
  return;
}

sub _current_token_type {
  my ($self) = @_;
  return @{ $self->{ _tokens } }[ $self->{_index} ]->{type};
}

# _lookahead
#
# retrieve the type of the token at position current + n.
sub _lookahead {
  my ($self, $number) = @_;
  $number = defined $number ? $number : 1;
  return @{ $self->{ _tokens } }[ $self->{_index} + $number ]->{type};
}

sub _lookahead_token {
  my ($self, $number) = @_;

  my $lookahead = @{$self->{ _tokens }}[ $self->{_index} + $number ];

  return $lookahead;
}

sub _raise_parse_error_for_token {
  my ($self, $token, $reason) = @_;
  my $lex_position = $token->{ start };
  my $actual_value = $token->{ value };
  my $actual_type = $token->{ type };

  Jmespath::ParseException->new( lex_position => $lex_position,
                                 token_value => $actual_value,
                                 token_type => $actual_type,
                                 message => $reason )->throw;
  return;
}

sub _raise_parse_error_maybe_eof {
  my ($self, $expected_type, $token) = @_;
  my $lex_position = $token->{ start };
  my $actual_value = $token->{ value };
  my $actual_type  = $token->{ type };

  if ( $actual_type eq 'eof' ) {
    Jmespath::IncompleteExpressionException
        ->new( lex_position => $lex_position,
               token_value => $actual_value,
               token_type => $actual_type )
        ->throw;
  }

  my $message = "Expecting: $expected_type, got: $actual_type";

  Jmespath::ParseException
      ->new( lex_position => $lex_position,
             token_value => $actual_value,
             token_type => $actual_type,
             message => $message )
      ->throw;
  return;
}

sub _free_cache_entries {
  my ($self) = @_;
  my $key = $self->{_CACHE}{(keys %{$self->{_CACHE}})[rand keys %{$self->{_CACHE}}]};
  delete $self->{ _CACHE }->{ $key };
  return;
}

sub purge {
  my ($self, $cls) = @_;
  $cls->_CACHE->clear();
  return;
}

1;
