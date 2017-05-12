package Jmespath::TreeInterpreter;
use parent 'Jmespath::Visitor';
use strict;
use warnings;
use Try::Tiny;
use List::Util qw(unpairs);
use Scalar::Util qw(looks_like_number);
use JSON;
use Jmespath::Expression;
use Jmespath::Functions qw(:all);
use Jmespath::AttributeException;
use Jmespath::IndexException;
use Jmespath::UnknownFunctionException;


my $COMPARATOR_FUNC = { 'le' => 'le',
                        'ne' => 'ne',
                        'lt' => 'lt',
                        'lte' => 'lte',
                        'eq' => 'eq',
                        'gt' => 'gt',
                        'gte' => 'gte' };

my $MAP_TYPE = 'HASH';

my $OPTIONS_DEFAULT = { hash_cls => undef,
                        custom_functions => undef };

sub new {
  my ($class, $options) = @_;
  my $self = $class->SUPER::new($options);
  if ( not defined $options) { $options = $OPTIONS_DEFAULT; }
  $self->{_hash_cls} = $options->{ hash_cls }
    if defined $options->{hash_cls};
  $self->{_functions} = eval { 'use ' . $options->{custom_functions} }
    if defined $options->{custom_functions};

  return $self;
}

sub visit {
  my ($self, $node, $args) = @_;
  my $node_type = $node->{type};
  my $result;
  try {
    my $method = \&{'visit_' . $node->{type}};
    $result = &$method( $self, $node, $args );
  } catch {
    $_->throw;
  };
  return $result;
}

sub default_visit {
  my ($self, $node, @args) = @_;
  Jmespath::NotImplementedException->new($node->{type})->throw;
  return;
}

=item visit_subexpression(node, value)

Drills down into a subexpression in the AST graph.

=cut

sub visit_subexpression {
  my ($self, $node, $value) = @_;
  my $result = $value;
  foreach my $node (@{$node->{children}}) {
    $result = $self->visit($node, $result);
  }
  return $result;
}

=item visit_field(node, value)

Returns the value of a field in the JSON data.

value : the JSON data
node : the AST node being evaluated.

=cut

sub visit_field {
  my ($self, $node, $value) = @_;
  my $result;
  try {
    $result = $value->{$node->{value}};
  } catch {
    # when the field cannot be looked up, then the spec defines the
    # return value as undef.
    return;
  };
  return $result;
}

sub visit_comparator {
  my ($self, $node, $value) = @_;

  my $comparator_func = \&{'jp_' . $node->{value}};
  if ( not defined &$comparator_func ) {
    Jmespath::UnknownFunctionException
        ->new({ message => 'unknown-function: Unknown function: ' . $comparator_func })
        ->throw;
  }

  return &$comparator_func( $self->visit( @{$node->{children}}[0], $value ),
                            $self->visit( @{$node->{children}}[1], $value ) );
}

sub visit_current {
  my ( $self, $node, $value ) = @_;
  return $value;
}

sub visit_expref {
  my ( $self, $node, $value ) = @_;
  return Jmespath::Expression->new($node->{children}[0], $self);
}

sub visit_function_expression {
  my ($self, $node, $value) = @_;
  my $function = \&{'jp_' . $node->{value}};
  if ( not defined &$function ) {
    Jmespath::UnknownFunctionException
        ->new({ message => 'unknown-function: Unknown function: ' . $function })
        ->throw;
  }

  my $resolved_args = [];
  foreach my $child ( @{$node->{ children}} ) {
    my $current = $self->visit($child, $value);
    push  @{$resolved_args}, $current;
  }

  return &$function(@$resolved_args);
}

sub visit_filter_projection {
  my ($self, $node, $value) = @_;
  my $base = $self->visit( @{$node->{children}}[0], $value);
  return if ref($base) ne 'ARRAY';
  return if scalar @$base == 0;

  my $comparator_node = @{ $node->{children} }[2];
  my $collected = [];
#  use Data::Dumper;
  foreach my $element (@$base) {
#    print Dumper $comparator_node;
#    print Dumper $element;
    my $cnode_result = $self->visit($comparator_node, $element);
#    print "cnode_result: $cnode_result\n";
    if ( $self->_is_true($cnode_result) ) {
      my $current = $self->visit(@{$node->{children}}[1], $element);
      if (defined $current) {
        push  @{$collected}, $current;
      }
    }
  }
  return $collected;
}

sub visit_flatten {
  my ($self, $node, $value) = @_;
  my $base = $self->visit(@{$node->{'children'}}[0], $value);

  return if ref($base) ne 'ARRAY';

  my $merged_list = [];
  foreach my $element (@$base) {
    if (ref($element) eq 'ARRAY') {
      push  @$merged_list, @$element;
    }
    else {
      push @$merged_list, $element;
    }
  }
  return $merged_list;
}

sub visit_identity {
  my ($self, $node, $value) = @_;
  return if not defined $value;
  # SHEER NEGATIVE ENERGY HACKERY - FORCE NUMBERS TO BE NUMBERS
  # THANK YOU JSON.PM
  $value = 1 * $value if $value =~ /^[-][0-9]+$/;
  return $value;
}

sub visit_index {
  my ($self, $node, $value) = @_;
  return if ref($value) ne 'ARRAY';
  my $result;
  try {
    $result = $value->[ $node->{value} ];
  } catch {
    Jmespath::IndexException->new({ message => 'Invalid index' })->throw;
  };
  return $result;
}

sub visit_index_expression {
  my ($self, $node, $value) = @_;
  my $result = $value;
  foreach my $node (@{$node->{children}}) {
    $result = $self->visit($node, $result);
  }
  return $result;
}


# Rules:
#

sub visit_slice {
  my ($self, $node, $value) = @_;

  # Rule 08: If the element being sliced is an array and yields no
  #       results, the result MUST be an empty array.
  my $selected = [];
  my ($start, $stop);

  # Rule 05: If the given step is omitted, it it assumed to be 1.
  my $step = defined $node->{children}->[2] ? $node->{children}->[2] : 1;

  # Rule 07: If the element being sliced is not an array, the result is null.
  return if ref($value) ne 'ARRAY';

  # Rule 06: If the given step is 0, an error MUST be raised.
  if ($step == 0) {
    Jmespath::ValueException->new(message => 'Invalid slice expression')->throw;
  }
  if (scalar @{$node->{children}} > 3) {
    Jmespath::ValueException->new(message => 'Invalid slice expression')->throw;
  }

  # Rule 02: If no start position is given, it is assumed to be 0 if
  #          the given step is greater than 0 or the end of the array
  #          if the given step is less than 0.
  if (not defined $node->{children}->[0] and $step > 0) {
    $start = 0;
  }
  elsif (not defined $node->{children}->[0] and $step < 0) {
    $start = scalar(@$value);
  }
  elsif ( $node->{children}->[0] < 0) {
    $start = scalar(@$value) + $node->{children}->[0];
  }
  else {
    $start = $node->{children}->[0];
  }

  # Rule 01: If a negative start position is given, it is calculated as the
  #          total length of the array plus the given start position.
  # if ($start < 0) {
  #   $start = scalar(@$value) + $start;
  # }

  # Rule 04: If no stop position is given, it is assumed to be the
  #          length of the array if the given step is greater than 0
  #          or 0 if the given step is less than 0.
  if (not defined $node->{children}->[1] and $step > 0) {
    $stop = scalar(@$value);
  }
  elsif (not defined $node->{children}->[1] and $step < 0) {
    $stop = -1;
  }
  # Rule 03: If a negative stop position is given, it is calculated as
  #          the total length of the array plus the given stop
  #          position.
  elsif ($node->{children}->[1] < 0 and $step < 0) {
    $stop = scalar(@$value) + $node->{children}->[1];
  }
  elsif ($node->{children}->[1] < 0 and $step > 0) {
    $stop = scalar(@$value) + $node->{children}->[1];
  }
  else {
    $stop = $node->{children}->[1];
  }

  if ($step > 0) {
    for ( my $idx = $start; $idx < $stop; $idx += $step ) {
      push @$selected, @{$value}[$idx];
      last if $idx == scalar(@$value) - 1
    }
  }
  else {
    for ( my $idx = $start; $idx > $stop; $idx += $step ) {
      push @$selected, @{$value}[$idx];
      last if $idx == 0;
    }
  }
  return $selected;
}

sub visit_key_val_pair {
  my ($self, $node, $value) = @_;
  return $self->visit(@{$node->{children}}[0], $value);
}

sub visit_literal {
  my ($self, $node, $value) = @_;
  return $node->{value};
}

sub visit_multi_select_hash {
  my ($self, $node, $value) = @_;
  return if not defined $value;
  my %merged;
  foreach my $child (@{$node->{children}}) {
    my $result = $self->visit($child, $value);
    return if not defined $child->{value};
    %merged = (%merged,(  $child->{value} , $result ));
  }
  return \%merged;
}

sub visit_multi_select_list {
  my ($self, $node, $value) = @_;
  return if not defined $value;
  return if scalar @{$node->{children}} == 0;

  my $collected = [];
  foreach my $child ( @{$node->{children}}) {
    my $result = $self->visit($child, $value);
    my $to_collect = defined $result ? $self->visit($child, $value) : undef;
    push @$collected, $to_collect;
  }
  return $collected;
}

sub visit_or_expression {
  my ($self, $node, $value) = @_;
  my $matched = $self->visit( @{$node->{children}}[0], $value );
  if ( $self->_is_false($matched)) {
    $matched = $self->visit(@{$node->{children}}[1], $value);
  }
  return $matched;
}

sub visit_and_expression {
  my ($self, $node, $value) = @_;
  my $matched = $self->visit(@{$node->{children}}[0], $value);
  # return if the left side eval is found to be false
  return $matched if $self->_is_false($matched);
  # if this isn't true then the whole evaluation is false
  $matched = $self->visit(@{$node->{children}}[1], $value);
  return $matched;
}

sub visit_not_expression {
  my ($self, $node, $value) = @_;
  my $original_result = $self->visit(@{$node->{children}}[0], $value);
  return JSON::true if $self->_is_false($original_result) == 1;
  return JSON::false;
}

sub visit_pipe {
  my ($self, $node, $value) = @_;
  my $result = $value;
  foreach my $node ( @{$node->{children}}) {
    $result = $self->visit($node, $result);
  }
  return $result;
}

sub visit_projection {
  my ($self, $node, $value) = @_;
  my $base = $self->visit(@{$node->{children}}[0], $value);
  return if ref($base) ne 'ARRAY';

  my $collected = [];
  foreach my $element (@$base) {
    my $current = $self->visit(@{$node->{children}}[1], $element);
    push (@$collected, $current) if defined $current;
  }
  return $collected;
}

sub visit_value_projection {
  my ($self, $node, $value) = @_;
  my $base = $self->visit(@{$node->{children}}[0], $value);
  my @basekeys;
  try {
    @basekeys = map { $base->{ $_ } } sort keys %$base ;
  } catch {
    return;
  };
  return if scalar @basekeys == 0;
  my $collected = [];
  foreach my $element (@basekeys) {
    my $current = $self->visit(@{$node->{children}}[1], $element);
    push( @$collected, $current ) if defined $current;
  }
  return $collected;
}

sub _is_false {
  my ($self, $value) = @_;
  return 1 if not defined $value;
#  return 1 if JSON::is_bool($value) and $value == JSON::false;
#  return 0 if JSON::is_bool($value) and $value == JSON::true;
  return 1 if ref($value) eq 'JSON::PP::Boolean' and $value == JSON::false;
  return 0 if ref($value) eq 'JSON::PP::Boolean' and $value == JSON::true;
  return 1 if ref($value) eq 'ARRAY'  and scalar @$value == 0;
  return 1 if ref($value) eq 'HASH'   and scalar keys %$value == 0;
  return 1 if ref($value) eq 'SCALAR' and $value eq '';
  return 1 if $value eq '';
  return 0;
}

sub _is_true {
  return ! shift->_is_false(shift);
}

1;

__END__

=head1 NAME

Jmespath::TreeInterpreter

