package GraphQL::Houtou::XS::Parser;

use 5.014;
use strict;
use warnings;
use GraphQL::Houtou ();
use GraphQL::Houtou::Error ();
use JSON::MaybeXS ();

our $VERSION = '0.02';

BEGIN {
  GraphQL::Houtou::_bootstrap_xs();
}

package GraphQL::Houtou::Parser::Internal;

use 5.014;
use strict;
use warnings;
use GraphQL::Houtou::Error ();
use JSON::MaybeXS ();

sub _make_bool {
  return $_[0] ? JSON::MaybeXS::true() : JSON::MaybeXS::false();
}

sub _string_value {
  my ($str) = @_;
  # https://spec.graphql.org/October2021/#EscapedCharacter
  $str =~ s|\\(["\\/bfnrt])|"qq!\\$1!"|gee;
  return $str;
}

sub _block_string_value {
  my ($str) = @_;
  # https://spec.graphql.org/October2021/#BlockStringValue()
  my @lines = split(/(?:\n|\r(?!\n)|\r\n)/s, $str);
  if (1 < @lines) {
    my $common_indent;
    for my $line (@lines[1..$#lines]) {
      my $length = length($line);
      my $indent = length(($line =~ /^([\t ]*)/)[0] || '');
      if ($indent < $length && (!defined($common_indent) || $indent < $common_indent)) {
        $common_indent = $indent;
      }
    }
    if (defined $common_indent) {
      for my $line (@lines[1..$#lines]) {
        $line =~ s/^[\t ]{0,$common_indent}//;
      }
    }
  }
  my ($start, $end);
  for ($start = 0; $start < @lines && $lines[$start] =~ /^[\t ]*$/; ++$start) {}
  for ($end = $#lines; $end >= 0 && $lines[$end] =~ /^[\t ]*$/; --$end) {}
  @lines = $start <= $end ? @lines[$start..$end] : ();
  my $formatted = join("\n", @lines);
  $formatted =~ s/\\"""/"""/g;
  return $formatted;
}

sub _format_error {
  my ($source, $position, $msg) = @_;
  my ($line, $column) = _line_column($source, $position);
  my $pretext = substr(
    $source,
    $position < 50 ? 0 : $position - 50,
    $position < 50 ? $position : 50,
  );
  my $context = substr($source, $position, 50);
  $pretext =~ s/.*\n//gs;
  $context =~ s/\n/\\n/g;
  return GraphQL::Houtou::Error->new(
    locations => [ { line => $line, column => $column } ],
    message => <<EOF,
Error parsing Pegex document:
  msg:      $msg
  context:  $pretext$context
            ${\ (' ' x (length($pretext)) . '^')}
  position: $position (0 pre-lookahead)
EOF
  );
}

sub _line_column {
  my ($source, $position) = @_;
  my $line = 1;
  my $column = 1;
  my $i = 0;
  my $length = length $source;
  $position = $length if $position > $length;
  while ($i < $position) {
    my $char = substr($source, $i, 1);
    if ($char eq "\r") {
      ++$line;
      $column = 1;
      ++$i;
      ++$i if $i < $position && substr($source, $i, 1) eq "\n";
      next;
    }
    if ($char eq "\n") {
      ++$line;
      $column = 1;
      ++$i;
      next;
    }
    ++$column;
    ++$i;
  }
  return ($line, $column);
}

sub _new_lazy_array_ref {
  my ($class, $state, $ptr) = @_;
  my @items;
  tie @items, $class, $state, $ptr;
  return \@items;
}

sub _new_lazy_array_tie {
  my ($class, $state, $ptr, $kind) = @_;
  # NOTE: these keys are part of the XS fast-path contract in gql_parser_fetch_array().
  # If you rename them, update the XS reader and the contract test together.
  return bless {
    state => $state,
    ptr => $ptr,
    kind => $kind,
    data => undef,
  }, $class;
}

package GraphQL::Houtou::Parser::Internal::LazyLoc;

use 5.014;
use strict;
use warnings;

sub start {
  return $_[0][0];
}

sub as_hash {
  my ($self, $source) = @_;
  my ($line, $column) = GraphQL::Houtou::Parser::Internal::_line_column($source, $self->[0]);
  return {
    line => $line,
    column => $column,
  };
}

sub line {
  my ($self, $source) = @_;
  my ($line) = GraphQL::Houtou::Parser::Internal::_line_column($source, $self->[0]);
  return $line;
}

sub column {
  my ($self, $source) = @_;
  my (undef, $column) = GraphQL::Houtou::Parser::Internal::_line_column($source, $self->[0]);
  return $column;
}

package GraphQL::Houtou::Parser::Internal::LazyArray::Arguments;

use 5.014;
use strict;
use warnings;

sub _new {
  my ($state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_ref(__PACKAGE__, $state, $ptr);
}

sub TIEARRAY {
  my ($class, $state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_tie($class, $state, $ptr, 1);
}

sub _materialize {
  my ($self) = @_;
  return $self->{data} if $self->{data};
  $self->{data} = GraphQL::Houtou::XS::Parser::_materialize_arguments_xs(
    $self->{state},
    $self->{ptr},
  );
  return $self->{data};
}

sub FETCHSIZE {
  my ($self) = @_;
  return scalar @{ $self->_materialize };
}

sub STORESIZE {
  my ($self, $count) = @_;
  $#{ $self->_materialize } = $count - 1;
  return;
}

sub FETCH {
  my ($self, $index) = @_;
  return $self->_materialize->[$index];
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->_materialize->[$index] = $value;
  return $value;
}

sub CLEAR {
  my ($self) = @_;
  @{ $self->_materialize } = ();
  return;
}

sub PUSH {
  my ($self, @values) = @_;
  return push @{ $self->_materialize }, @values;
}

sub POP {
  my ($self) = @_;
  return pop @{ $self->_materialize };
}

sub SHIFT {
  my ($self) = @_;
  return shift @{ $self->_materialize };
}

sub UNSHIFT {
  my ($self, @values) = @_;
  return unshift @{ $self->_materialize }, @values;
}

sub EXISTS {
  my ($self, $index) = @_;
  return exists $self->_materialize->[$index];
}

sub DELETE {
  my ($self, $index) = @_;
  return delete $self->_materialize->[$index];
}

sub SPLICE {
  my $self = shift;
  return splice @{ $self->_materialize }, @_;
}

package GraphQL::Houtou::Parser::Internal::LazyArray::Directives;

use 5.014;
use strict;
use warnings;

sub _new {
  my ($state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_ref(__PACKAGE__, $state, $ptr);
}

sub TIEARRAY {
  my ($class, $state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_tie($class, $state, $ptr, 2);
}

sub _materialize {
  my ($self) = @_;
  return $self->{data} if $self->{data};
  $self->{data} = GraphQL::Houtou::XS::Parser::_materialize_directives_xs(
    $self->{state},
    $self->{ptr},
  );
  return $self->{data};
}

sub FETCHSIZE {
  my ($self) = @_;
  return scalar @{ $self->_materialize };
}

sub STORESIZE {
  my ($self, $count) = @_;
  $#{ $self->_materialize } = $count - 1;
  return;
}

sub FETCH {
  my ($self, $index) = @_;
  return $self->_materialize->[$index];
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->_materialize->[$index] = $value;
  return $value;
}

sub CLEAR {
  my ($self) = @_;
  @{ $self->_materialize } = ();
  return;
}

sub PUSH {
  my ($self, @values) = @_;
  return push @{ $self->_materialize }, @values;
}

sub POP {
  my ($self) = @_;
  return pop @{ $self->_materialize };
}

sub SHIFT {
  my ($self) = @_;
  return shift @{ $self->_materialize };
}

sub UNSHIFT {
  my ($self, @values) = @_;
  return unshift @{ $self->_materialize }, @values;
}

sub EXISTS {
  my ($self, $index) = @_;
  return exists $self->_materialize->[$index];
}

sub DELETE {
  my ($self, $index) = @_;
  return delete $self->_materialize->[$index];
}

sub SPLICE {
  my $self = shift;
  return splice @{ $self->_materialize }, @_;
}

package GraphQL::Houtou::Parser::Internal::LazyArray::VariableDefinitions;

use 5.014;
use strict;
use warnings;

sub _new {
  my ($state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_ref(__PACKAGE__, $state, $ptr);
}

sub TIEARRAY {
  my ($class, $state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_tie($class, $state, $ptr, 3);
}

sub _materialize {
  my ($self) = @_;
  return $self->{data} if $self->{data};
  $self->{data} = GraphQL::Houtou::XS::Parser::_materialize_variable_definitions_xs(
    $self->{state},
    $self->{ptr},
  );
  return $self->{data};
}

sub FETCHSIZE {
  my ($self) = @_;
  return scalar @{ $self->_materialize };
}

sub STORESIZE {
  my ($self, $count) = @_;
  $#{ $self->_materialize } = $count - 1;
  return;
}

sub FETCH {
  my ($self, $index) = @_;
  return $self->_materialize->[$index];
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->_materialize->[$index] = $value;
  return $value;
}

sub CLEAR {
  my ($self) = @_;
  @{ $self->_materialize } = ();
  return;
}

sub PUSH {
  my ($self, @values) = @_;
  return push @{ $self->_materialize }, @values;
}

sub POP {
  my ($self) = @_;
  return pop @{ $self->_materialize };
}

sub SHIFT {
  my ($self) = @_;
  return shift @{ $self->_materialize };
}

sub UNSHIFT {
  my ($self, @values) = @_;
  return unshift @{ $self->_materialize }, @values;
}

sub EXISTS {
  my ($self, $index) = @_;
  return exists $self->_materialize->[$index];
}

sub DELETE {
  my ($self, $index) = @_;
  return delete $self->_materialize->[$index];
}

sub SPLICE {
  my $self = shift;
  return splice @{ $self->_materialize }, @_;
}

package GraphQL::Houtou::Parser::Internal::LazyArray::ObjectFields;

use 5.014;
use strict;
use warnings;

sub _new {
  my ($state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_ref(__PACKAGE__, $state, $ptr);
}

sub TIEARRAY {
  my ($class, $state, $ptr) = @_;
  return GraphQL::Houtou::Parser::Internal::_new_lazy_array_tie($class, $state, $ptr, 4);
}

sub _materialize {
  my ($self) = @_;
  return $self->{data} if $self->{data};
  $self->{data} = GraphQL::Houtou::XS::Parser::_materialize_object_fields_xs(
    $self->{state},
    $self->{ptr},
  );
  return $self->{data};
}

sub FETCHSIZE {
  my ($self) = @_;
  return scalar @{ $self->_materialize };
}

sub STORESIZE {
  my ($self, $count) = @_;
  $#{ $self->_materialize } = $count - 1;
  return;
}

sub FETCH {
  my ($self, $index) = @_;
  return $self->_materialize->[$index];
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->_materialize->[$index] = $value;
  return $value;
}

sub CLEAR {
  my ($self) = @_;
  @{ $self->_materialize } = ();
  return;
}

sub PUSH {
  my ($self, @values) = @_;
  return push @{ $self->_materialize }, @values;
}

sub POP {
  my ($self) = @_;
  return pop @{ $self->_materialize };
}

sub SHIFT {
  my ($self) = @_;
  return shift @{ $self->_materialize };
}

sub UNSHIFT {
  my ($self, @values) = @_;
  return unshift @{ $self->_materialize }, @values;
}

sub EXISTS {
  my ($self, $index) = @_;
  return exists $self->_materialize->[$index];
}

sub DELETE {
  my ($self, $index) = @_;
  return delete $self->_materialize->[$index];
}

sub SPLICE {
  my $self = shift;
  return splice @{ $self->_materialize }, @_;
}

1;
