package GraphQL::Houtou::Runtime::Slot;

use 5.014;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  my $arg_defs_compact = _normalize_arg_defs(
    $args{arg_defs_compact},
    $args{arg_defs},
  );
  return bless {
    schema_slot_key => $args{schema_slot_key},
    schema_slot_index => $args{schema_slot_index},
    field_name => $args{field_name},
    result_name => $args{result_name},
    return_type_name => $args{return_type_name},
    return_type_kind_code => defined $args{return_type_kind_code} ? $args{return_type_kind_code} : 0,
    item_non_null => $args{item_non_null} ? 1 : 0,
    resolver_shape => $args{resolver_shape} || 'DEFAULT',
    resolver_mode => $args{resolver_mode} || 'DEFAULT',
    completion_family => $args{completion_family} || 'GENERIC',
    dispatch_family => $args{dispatch_family} || 'GENERIC',
    arg_defs_compact => $arg_defs_compact,
    has_args => $args{has_args} ? 1 : 0,
    has_directives => $args{has_directives} ? 1 : 0,
  }, $class;
}

sub schema_slot_key { return $_[0]{schema_slot_key} }
sub schema_slot_index { return $_[0]{schema_slot_index} }
sub field_name { return $_[0]{field_name} }
sub result_name { return $_[0]{result_name} }
sub return_type_name { return $_[0]{return_type_name} }
sub return_type_kind_code { return $_[0]{return_type_kind_code} }
sub item_non_null { return $_[0]{item_non_null} }
sub resolver_shape { return $_[0]{resolver_shape} }
sub resolver_mode { return $_[0]{resolver_mode} }
sub completion_family { return $_[0]{completion_family} }
sub dispatch_family { return $_[0]{dispatch_family} }
sub callback_abi_code { return _callback_abi_code($_[0]{resolver_shape}, $_[0]{resolver_mode}) }
sub arg_defs_compact { return $_[0]{arg_defs_compact} }
sub has_args { return $_[0]{has_args} }
sub has_directives { return $_[0]{has_directives} }

sub to_struct {
  my ($self) = @_;
  return {
    schema_slot_key => $self->{schema_slot_key},
    schema_slot_index => $self->{schema_slot_index},
    field_name => $self->{field_name},
    result_name => $self->{result_name},
    return_type_name => $self->{return_type_name},
    resolver_shape => $self->{resolver_shape},
    resolver_mode => $self->{resolver_mode},
    completion_family => $self->{completion_family},
    dispatch_family => $self->{dispatch_family},
    return_type_kind_code => $self->{return_type_kind_code},
    item_non_null => $self->{item_non_null},
    arg_defs_compact => _clone_compact($self->{arg_defs_compact}),
    has_args => $self->{has_args},
    has_directives => $self->{has_directives},
  };
}

sub to_native_struct {
  my ($self, %opts) = @_;
  my $include_arg_defs = exists $opts{include_arg_defs} ? $opts{include_arg_defs} : 1;
  return {
    schema_slot_key => $self->{schema_slot_key},
    schema_slot_index => $self->{schema_slot_index},
    field_name => $self->{field_name},
    result_name => $self->{result_name},
    return_type_name => $self->{return_type_name},
    return_type_kind_code => $self->{return_type_kind_code},
    item_non_null => $self->{item_non_null},
    resolver_shape => $self->{resolver_shape},
    resolver_shape_code => _resolver_shape_code($self->{resolver_shape}),
    resolver_mode => $self->{resolver_mode},
    resolver_mode_code => _resolver_mode_code($self->{resolver_mode}),
    callback_abi_code => _callback_abi_code($self->{resolver_shape}, $self->{resolver_mode}),
    completion_family => $self->{completion_family},
    completion_family_code => _family_code($self->{completion_family}),
    dispatch_family => $self->{dispatch_family},
    dispatch_family_code => _dispatch_family_code($self->{dispatch_family}),
    ($include_arg_defs ? (arg_defs => _clone_compact($self->{arg_defs_compact})) : ()),
    has_args => $self->{has_args},
    has_directives => $self->{has_directives},
  };
}

sub to_native_compact_struct {
  my ($self, %opts) = @_;
  my $include_arg_defs = exists $opts{include_arg_defs} ? $opts{include_arg_defs} : 1;
  my $native = $self->to_native_struct;
  return [
    $native->{field_name},
    $native->{result_name},
    $native->{return_type_name},
    $native->{schema_slot_index},
    $native->{resolver_shape_code},
    $native->{completion_family_code},
    $native->{dispatch_family_code},
    $native->{return_type_kind_code},
    $native->{has_args},
    $native->{has_directives},
    $native->{resolver_mode_code},
    ($include_arg_defs ? _clone_compact($self->{arg_defs_compact}) : undef),
    $native->{callback_abi_code},
    $native->{item_non_null} ? 1 : 0,
  ];
}

sub to_native_exec_struct {
  my ($self, %opts) = @_;
  return $self->to_native_struct(%opts);
}

sub _resolver_shape_code {
  my ($shape) = @_;
  return 2 if ($shape || q()) eq 'EXPLICIT';
  return 1;
}

sub _resolver_mode_code {
  my ($mode) = @_;
  return 2 if ($mode || q()) eq 'NATIVE';
  return 1;
}

sub _callback_abi_code {
  my ($shape, $mode) = @_;
  return 3 if ($mode || q()) eq 'NATIVE';
  return 2 if ($shape || q()) eq 'EXPLICIT';
  return 1;
}

sub _family_code {
  my ($family) = @_;
  return 2 if ($family || q()) eq 'OBJECT';
  return 3 if ($family || q()) eq 'LIST';
  return 4 if ($family || q()) eq 'ABSTRACT';
  return 1;
}

sub _dispatch_family_code {
  my ($family) = @_;
  return 2 if ($family || q()) eq 'RESOLVE_TYPE';
  return 3 if ($family || q()) eq 'TAG';
  return 4 if ($family || q()) eq 'POSSIBLE_TYPES';
  return 1;
}

sub _clone_value {
  my ($value) = @_;
  my $ref = ref($value);
  return $value if !$ref;
  return [ map { _clone_value($_) } @$value ] if $ref eq 'ARRAY';
  return { map { $_ => _clone_value($value->{$_}) } keys %$value } if $ref eq 'HASH';
  return $value;
}

sub _clone_compact {
  my ($value) = @_;
  return undef if !defined $value;
  return _clone_value($value);
}

sub _normalize_arg_defs {
  my ($compact, $hash) = @_;
  if (defined $compact) {
    return _arg_defs_to_compact($compact) if ref($compact) eq 'HASH';
    return _clone_compact($compact);
  }
  return _arg_defs_to_compact($hash);
}

sub _arg_defs_to_compact {
  my ($arg_defs) = @_;
  my @entries;
  for my $name (sort keys %{ $arg_defs || {} }) {
    my $def = $arg_defs->{$name} || {};
    push @entries, [
      $name,
      $def->{type},
      $def->{has_default} ? 1 : 0,
      _clone_value($def->{default_value}),
    ];
  }
  return \@entries;
}

1;
