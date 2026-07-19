package GraphQL::Houtou::Type::Scalar;

use 5.014;
use strict;
use warnings;

use parent 'GraphQL::Houtou::Type';
use Exporter 'import';
use JSON::MaybeXS qw(JSON is_bool);
use Role::Tiny::With;
use Scalar::Util qw(looks_like_number);
use GraphQL::Houtou::Internal::TypeSupport qw(description_doc_lines named_from_ast);
use GraphQL::Houtou::Type::List ();
use GraphQL::Houtou::Type::NonNull ();

with qw(
  GraphQL::Houtou::Role::Input
  GraphQL::Houtou::Role::Output
  GraphQL::Houtou::Role::Leaf
);

our @EXPORT_OK = qw($Int $Float $String $Boolean $ID);
use constant DEBUG => $ENV{GRAPHQL_DEBUG};

sub list {
  $_[0]->{_houtou_list} ||= GraphQL::Houtou::Type::List->new(of => $_[0]);
}

sub non_null {
  $_[0]->{_houtou_non_null} ||= GraphQL::Houtou::Type::NonNull->new(of => $_[0]);
}

sub _leave_undef {
  my ($closure) = @_;
  sub { return undef if !defined $_[0]; goto &$closure; };
}

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->{name} = $args{name};
  $self->{description} = $args{description};
  $self->{serialize} = $args{serialize};
  $self->{parse_value} = $args{parse_value};
  $self->{_builtin_kind} = $args{_builtin_kind};
  $self->{specified_by_url} = $args{specified_by_url};
  return bless $self, $class;
}

sub name { $_[0]->{name} }
sub description { $_[0]->{description} }
sub to_string { $_[0]->{to_string} ||= $_[0]->name }
sub serialize { $_[0]->{serialize} }
sub parse_value { $_[0]->{parse_value} }

sub from_ast {
  my ($class, $name2type, $ast_node) = @_;
  my ($specified_by) = grep { ($_->{name} || q()) eq 'specifiedBy' }
    @{ $ast_node->{directives} || [] };
  return $class->new(
    named_from_ast($ast_node),
    # SDL-built custom scalars default to pass-through coercion; override
    # via the resolvers option of Schema->from_doc or by replacing these.
    serialize => sub { $_[0] },
    parse_value => sub { $_[0] },
    ($specified_by && defined $specified_by->{arguments}{url}
      ? (specified_by_url => $specified_by->{arguments}{url})
      : ()),
  );
}

sub to_doc {
  my ($self) = @_;
  return $self->{to_doc} if exists $self->{to_doc};
  my $line = "scalar @{[$self->name]}";
  if (defined(my $url = $self->specified_by_url)) {
    $line .= ' @specifiedBy(url: '
      . JSON::MaybeXS->new->utf8(0)->allow_nonref->encode($url) . ')';
  }
  return $self->{to_doc} = join '', map "$_\n",
    description_doc_lines($self->description),
    $line;
}
sub _builtin_kind { $_[0]->{_builtin_kind} }
sub specified_by_url { $_[0]->{specified_by_url} }

sub _fast_is_nonref_defined {
  defined $_[0] && !ref($_[0]);
}

sub _fast_is_int32_signed {
  return if !_fast_is_nonref_defined($_[0]);
  return if !looks_like_number($_[0]);
  return if int($_[0]) != $_[0];
  return $_[0] >= -2147483648 && $_[0] <= 2147483647;
}

sub _fast_is_num {
  return if !_fast_is_nonref_defined($_[0]);
  return looks_like_number($_[0]);
}

sub _fast_is_str {
  return _fast_is_nonref_defined($_[0]);
}

sub _fast_is_boolish {
  return 1 if is_bool($_[0]);
  return if !_fast_is_nonref_defined($_[0]);
  return if !looks_like_number($_[0]);
  return $_[0] == 0 || $_[0] == 1;
}

sub _builtin_is_valid {
  my ($self, $item) = @_;
  my $kind = $self->_builtin_kind or return;

  return 1 if !defined $item;
  return _fast_is_int32_signed($item) if $kind eq 'Int';
  return _fast_is_num($item) if $kind eq 'Float';
  return _fast_is_str($item) if $kind eq 'String';
  return _fast_is_boolish($item) if $kind eq 'Boolean';
  return _fast_is_str($item) if $kind eq 'ID';
  return;
}

sub _builtin_graphql_to_perl {
  my ($self, $item) = @_;
  my $kind = $self->_builtin_kind or return;

  return $item if !defined $item;

  if ($kind eq 'Int') {
    _fast_is_int32_signed($item) or die "Not an Int.\n";
    return $item + 0;
  }
  if ($kind eq 'Float') {
    _fast_is_num($item) or die "Not a Float.\n";
    return $item + 0;
  }
  if ($kind eq 'String') {
    _fast_is_str($item) or die "Not a String.\n";
    return $item;
  }
  if ($kind eq 'Boolean') {
    _fast_is_boolish($item) or die "Not a Boolean.\n";
    return $item ? 1 : 0;
  }
  if ($kind eq 'ID') {
    _fast_is_str($item) or die "Not an ID.\n";
    return $item;
  }

  return;
}

sub _builtin_perl_to_graphql {
  my ($self, $item) = @_;
  my $kind = $self->_builtin_kind or return;

  return $item if !defined $item;

  if ($kind eq 'Int') {
    _fast_is_int32_signed($item) or die "Not an Int.\n";
    return $item + 0;
  }
  if ($kind eq 'Float') {
    _fast_is_num($item) or die "Not a Float.\n";
    return $item + 0;
  }
  if ($kind eq 'String') {
    _fast_is_str($item) or die "Not a String.\n";
    return $item . '';
  }
  if ($kind eq 'Boolean') {
    _fast_is_boolish($item) or die "Not a Boolean.\n";
    return $item ? JSON->true : JSON->false;
  }
  if ($kind eq 'ID') {
    _fast_is_str($item) or die "Not an ID.\n";
    return $item . '';
  }

  return;
}

sub is_valid {
  my ($self, $item) = @_;
  my $fast = $self->_builtin_kind ? $self->_builtin_is_valid($item) : undef;
  return $fast if defined $fast;
  return 1 if !defined $item;
  return eval { $self->serialize->($item); 1 };
}

sub graphql_to_perl {
  my ($self, $item) = @_;
  my $fast = $self->_builtin_kind ? $self->_builtin_graphql_to_perl($item) : undef;
  return $fast if defined $fast || !defined $item;
  return $self->parse_value->($item);
}

sub perl_to_graphql {
  my ($self, $item) = @_;
  my $fast = $self->_builtin_kind ? $self->_builtin_perl_to_graphql($item) : undef;
  return $fast if defined $fast || !defined $item;
  return $self->serialize->($item);
}

our $Int = __PACKAGE__->new(
  _builtin_kind => 'Int',
  name => 'Int',
  description =>
    'The `Int` scalar type represents non-fractional signed whole numeric ' .
    'values. Int can represent values between -(2^31) and 2^31 - 1.',
  serialize => _leave_undef(sub { !_fast_is_int32_signed($_[0]) and die "Not an Int.\n"; $_[0] + 0 }),
  parse_value => _leave_undef(sub { !_fast_is_int32_signed($_[0]) and die "Not an Int.\n"; $_[0] + 0 }),
);

our $Float = __PACKAGE__->new(
  _builtin_kind => 'Float',
  name => 'Float',
  description =>
    'The `Float` scalar type represents signed double-precision fractional ' .
    'values as specified by [IEEE 754](http://en.wikipedia.org/wiki/IEEE_floating_point).',
  serialize => _leave_undef(sub { !_fast_is_num($_[0]) and die "Not a Float.\n"; $_[0] + 0 }),
  parse_value => _leave_undef(sub { !_fast_is_num($_[0]) and die "Not a Float.\n"; $_[0] + 0 }),
);

our $String = __PACKAGE__->new(
  _builtin_kind => 'String',
  name => 'String',
  description =>
    'The `String` scalar type represents textual data, represented as UTF-8 ' .
    'character sequences. The String type is most often used by GraphQL to ' .
    'represent free-form human-readable text.',
  serialize => _leave_undef(sub { !_fast_is_str($_[0]) and die "Not a String.\n"; $_[0] . '' }),
  parse_value => _leave_undef(sub { !_fast_is_str($_[0]) and die "Not a String.\n"; $_[0] }),
);

our $Boolean = __PACKAGE__->new(
  _builtin_kind => 'Boolean',
  name => 'Boolean',
  description => 'The `Boolean` scalar type represents `true` or `false`.',
  serialize => _leave_undef(sub {
    !_fast_is_boolish($_[0]) and die "Not a Boolean.\n";
    $_[0] ? JSON->true : JSON->false;
  }),
  parse_value => _leave_undef(sub {
    !_fast_is_boolish($_[0]) and die "Not a Boolean.\n";
    $_[0] + 0;
  }),
);

our $ID = __PACKAGE__->new(
  _builtin_kind => 'ID',
  name => 'ID',
  description =>
    'The `ID` scalar type represents a unique identifier, often used to ' .
    'refetch an object or as key for a cache. The ID type appears in a JSON ' .
    'response as a String; however, it is not intended to be human-readable. ' .
    'When expected as an input type, any string (such as `"4"`) or integer ' .
    '(such as `4`) input value will be accepted as an ID.',
  serialize => _leave_undef(sub { !_fast_is_str($_[0]) and die "Not an ID.\n"; $_[0] . '' }),
  parse_value => _leave_undef(sub { !_fast_is_str($_[0]) and die "Not an ID.\n"; $_[0] }),
);

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::Scalar - built-in and custom GraphQL scalars

=head1 SYNOPSIS

    use GraphQL::Houtou::Type::Scalar qw($String $Int $Float $Boolean $ID);

    my $DateTime = GraphQL::Houtou::Type::Scalar->new(
      name        => 'DateTime',
      serialize   => sub { $_[0]->iso8601 },
      parse_value => sub { parse_iso8601($_[0]) },
    );

=head1 DESCRIPTION

Exports the five specced scalars as ready-made instances. Custom scalars
take C<serialize> (internal value to response value) and C<parse_value>
(variable/argument input to internal value); both default to pass-through.
C<specified_by_url> adds the C<@specifiedBy> URL. Input coercion for the
built-in scalars runs natively in the XS lane.

=head1 SEE ALSO

L<GraphQL::Houtou>

=cut
