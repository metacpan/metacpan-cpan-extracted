package GraphQL::Houtou::Schema;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
use JSON::MaybeXS ();

use GraphQL::Houtou::Directive ();
use GraphQL::Houtou::Runtime::SchemaGraph ();
use GraphQL::Houtou::Type::Scalar qw($Int $Float $String $Boolean $ID);
use GraphQL::Houtou::Introspection qw($SCHEMA_META_TYPE);

our @EXPORT_OK = qw(lookup_type);
my $JSON = JSON::MaybeXS->new->canonical;

sub new {
  my ($class, %args) = @_;
  die "GraphQL::Houtou::Schema requires query" if !defined $args{query};
  my $self = bless {
    query => $args{query},
    mutation => $args{mutation},
    subscription => $args{subscription},
    description => $args{description},
    types => $args{types} || [ $Int, $Float, $String, $Boolean, $ID ],
    directives => $args{directives} || \@GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES,
  }, $class;
  return $self;
}

sub description { return $_[0]->{description} }
sub query { return $_[0]->{query} }
sub mutation { return $_[0]->{mutation} }
sub subscription { return $_[0]->{subscription} }
sub types { return $_[0]->{types} }
sub directives { return $_[0]->{directives} }

our %KIND2CLASS = (
  type => 'GraphQL::Houtou::Type::Object',
  interface => 'GraphQL::Houtou::Type::Interface',
  union => 'GraphQL::Houtou::Type::Union',
  enum => 'GraphQL::Houtou::Type::Enum',
  input => 'GraphQL::Houtou::Type::InputObject',
  scalar => 'GraphQL::Houtou::Type::Scalar',
);
my @ROOT_ATTRS = qw(query mutation subscription);
my %VALID_DIRECTIVE_LOCATION = map { ($_ => 1) } qw(
  QUERY MUTATION SUBSCRIPTION FIELD FRAGMENT_DEFINITION FRAGMENT_SPREAD
  INLINE_FRAGMENT VARIABLE_DEFINITION SCHEMA SCALAR OBJECT FIELD_DEFINITION
  ARGUMENT_DEFINITION INTERFACE UNION ENUM ENUM_VALUE INPUT_OBJECT
  INPUT_FIELD_DEFINITION
);

sub from_doc {
  my ($class, $doc, %opts) = @_;
  require GraphQL::Houtou;
  require GraphQL::Houtou::XS::Parser;
  my ($ast, $diagnostics) = @{
    GraphQL::Houtou::XS::Parser::_parse_with_diagnostics_xs($doc)
  };
  if (@$diagnostics) {
    die join("\n", map { $_->{message} } @$diagnostics) . "\n";
  }
  return $class->from_ast($ast, %opts);
}

sub from_ast {
  my ($class, $ast, %opts) = @_;
  my $kind2class = $opts{kind2class} || \%KIND2CLASS;

  my ($merged_ast, $merge_error) = eval { (_merge_type_system_extensions($ast, $kind2class), undef) };
  $merge_error = $@ if $@;
  die $merge_error if $merge_error;

  my @type_nodes = grep { $kind2class->{$_->{kind} || q()} } @$merged_ast;
  my ($schema_node, $extra_schema_node) = grep { ($_->{kind} || q()) eq 'schema' } @$merged_ast;
  die "Must provide only one schema definition.\n" if $extra_schema_node;

  my %name2type;
  for my $node (@type_nodes) {
    die "Type '$node->{name}' was defined more than once.\n"
      if $name2type{ $node->{name} };
    my $type_class = $kind2class->{ $node->{kind} };
    (my $module_file = $type_class) =~ s{::}{/}g;
    require "$module_file.pm";
    $name2type{ $node->{name} } = $type_class->from_ast(\%name2type, $node);
  }
  for my $builtin ($Int, $Float, $String, $Boolean, $ID) {
    $name2type{ $builtin->name } ||= $builtin;
  }

  if (!$schema_node) {
    $schema_node = +{
      map { $name2type{ ucfirst $_ } ? ($_ => ucfirst $_) : () } @ROOT_ATTRS
    };
  }
  die "Must provide schema definition with query type or a type named Query.\n"
    if !$schema_node->{query};

  my @directives = map { GraphQL::Houtou::Directive->from_ast(\%name2type, $_) }
    grep { ($_->{kind} || q()) eq 'directive' } @$merged_ast;
  my @all_directives = (@GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES, @directives);
  my $ast_validation_errors = _type_system_directive_errors(
    $merged_ast, \@all_directives,
  );

  my $schema = $class->new(
    (map {
      $schema_node->{$_}
        ? ($_ => $name2type{ $schema_node->{$_} }
          // die "Specified $_ type '$schema_node->{$_}' not found.\n")
        : ()
    } @ROOT_ATTRS),
    ($schema_node->{description} ? (description => $schema_node->{description}) : ()),
    (@directives
      ? (directives => \@all_directives)
      : ()),
    types => [ values %name2type ],
  );
  $schema->{_ast_validation_errors} = $ast_validation_errors;
  $schema->_apply_resolvers($opts{resolvers}) if $opts{resolvers};
  $schema->name2type;
  return $schema;
}

sub _merge_type_system_extensions {
  my ($ast, $kind2class) = @_;
  my @result;
  my %definitions;
  my @extensions;
  my $schema_definition;
  my %repeatable = map { ($_ => 0) } qw(include skip deprecated specifiedBy oneOf);

  for my $node (@$ast) {
    if (!$node->{extension}) {
      push @result, $node;
      if ($kind2class->{ $node->{kind} || q() }) {
        $definitions{ $node->{name} } = $node
          if !exists $definitions{ $node->{name} };
      } elsif (($node->{kind} || q()) eq 'schema' && !$schema_definition) {
        $schema_definition = $node;
      }
      next;
    }
    push @extensions, $node;
  }
  for my $node (@$ast) {
    next if ($node->{kind} || q()) ne 'directive';
    $repeatable{ $node->{name} } = $node->{repeatable} ? 1 : 0;
  }
  return \@result if !@extensions;

  # Copy only nodes that receive extensions. This keeps from_ast from
  # modifying a caller-owned parser AST while avoiding a full deep clone.
  my %copies;
  for my $extension (@extensions) {
    my $kind = $extension->{kind} || q();
    if ($kind eq 'schema') {
      if (!$schema_definition) {
        $schema_definition = {
          kind => 'schema',
          map { $definitions{ ucfirst $_ } ? ($_ => ucfirst $_) : () } @ROOT_ATTRS
        };
        push @result, $schema_definition;
      }
      $schema_definition = _extension_target_copy(
        \@result, $schema_definition, \%copies,
      );
      _merge_schema_extension($schema_definition, $extension, \%repeatable);
      next;
    }

    my $name = $extension->{name};
    my $target = $definitions{$name}
      // die "Cannot extend type '$name' because it is not defined.\n";
    die "Cannot extend type '$name' as $kind because it is a '$target->{kind}' type.\n"
      if ($target->{kind} ne $kind);
    $target = _extension_target_copy(\@result, $target, \%copies);
    $definitions{$name} = $target;
    _merge_type_extension($target, $extension, \%repeatable);
  }
  return \@result;
}

sub _type_system_directive_errors {
  my ($ast, $directives) = @_;
  my (@errors, %name2directive, %definition_count);
  for my $directive (@$directives) {
    my $name = $directive->name;
    push @errors, "Directive '\@$name' is defined more than once."
      if $definition_count{$name}++;
    $name2directive{$name} ||= $directive;
  }

  for my $node (@$ast) {
    my $kind = $node->{kind} || q();
    if ($kind eq 'directive') {
      my %seen_location;
      for my $location (@{ $node->{locations} || [] }) {
        push @errors, "Directive '\@$node->{name}' has unknown location '$location'."
          if !$VALID_DIRECTIVE_LOCATION{$location};
        push @errors, "Directive '\@$node->{name}' repeats location '$location'."
          if $seen_location{$location}++;
      }
      next;
    }
    my %location = (
      schema => 'SCHEMA', scalar => 'SCALAR', type => 'OBJECT',
      interface => 'INTERFACE', union => 'UNION', enum => 'ENUM',
      input => 'INPUT_OBJECT',
    );
    push @errors, _applied_directive_errors(
      $node->{directives}, $location{$kind},
      $kind eq 'schema' ? 'schema' : "$kind @{[$node->{name} || q()]}",
      \%name2directive,
    ) if $location{$kind};

    if ($kind eq 'type' || $kind eq 'interface') {
      for my $field_name (sort keys %{ $node->{fields} || {} }) {
        my $field = $node->{fields}{$field_name};
        push @errors, _applied_directive_errors(
          $field->{directives}, 'FIELD_DEFINITION',
          "$kind $node->{name}.$field_name", \%name2directive,
        );
        for my $arg_name (sort keys %{ $field->{args} || {} }) {
          push @errors, _applied_directive_errors(
            $field->{args}{$arg_name}{directives}, 'ARGUMENT_DEFINITION',
            "$kind $node->{name}.$field_name($arg_name:)", \%name2directive,
          );
        }
      }
    }
    elsif ($kind eq 'input') {
      for my $field_name (sort keys %{ $node->{fields} || {} }) {
        push @errors, _applied_directive_errors(
          $node->{fields}{$field_name}{directives}, 'INPUT_FIELD_DEFINITION',
          "input $node->{name}.$field_name", \%name2directive,
        );
      }
    }
    elsif ($kind eq 'enum') {
      for my $value_name (sort keys %{ $node->{values} || {} }) {
        push @errors, _applied_directive_errors(
          $node->{values}{$value_name}{directives}, 'ENUM_VALUE',
          "enum $node->{name}.$value_name", \%name2directive,
        );
      }
    }
  }
  return \@errors;
}

sub _applied_directive_errors {
  my ($applications, $location, $coordinate, $name2directive) = @_;
  my (@errors, %seen);
  for my $application (@{ $applications || [] }) {
    my $name = $application->{name} || q();
    my $directive = $name2directive->{$name};
    if (!$directive) {
      push @errors, "Unknown directive '\@$name' on $coordinate.";
      next;
    }
    push @errors, "Directive '\@$name' is not repeatable and cannot be used more than once on $coordinate."
      if $seen{$name}++ && !$directive->repeatable;
    push @errors, "Directive '\@$name' cannot be used at $location on $coordinate."
      if !grep { $_ eq $location } @{ $directive->locations || [] };

    my $arguments = $application->{arguments} || {};
    my $definitions = $directive->args || {};
    for my $arg_name (sort keys %$arguments) {
      my $definition = $definitions->{$arg_name};
      if (!$definition) {
        push @errors, "Unknown argument '$arg_name' on directive '\@$name' at $coordinate.";
        next;
      }
      if (my $detail = _missing_required_input_field(
          $definition->{type}, $arguments->{$arg_name}, q())) {
        push @errors, "Argument '$arg_name' on directive '\@$name' at $coordinate "
          . "is invalid for type @{[$definition->{type}->to_string]}: $detail.";
        next;
      }
      my $ok = eval { $definition->{type}->graphql_to_perl($arguments->{$arg_name}); 1 };
      if (!$ok) {
        my $detail = $@ || 'invalid value';
        $detail =~ s/\s+\z//;
        $detail =~ s/ at \S+ line \d+\.?\z//;
        push @errors, "Argument '$arg_name' on directive '\@$name' at $coordinate "
          . "is invalid for type @{[$definition->{type}->to_string]}: $detail.";
      }
    }
    for my $arg_name (sort keys %$definitions) {
      my $definition = $definitions->{$arg_name};
      push @errors, "Required argument '$arg_name' was not provided to directive '\@$name' at $coordinate."
        if !exists($arguments->{$arg_name})
          && ref($definition->{type})
          && $definition->{type}->isa('GraphQL::Houtou::Type::NonNull')
          && !exists($definition->{default_value});
    }
  }
  return @errors;
}

sub _extension_target_copy {
  my ($result, $target, $copies) = @_;
  my $key = "$target";
  return $copies->{$key} if $copies->{$key};
  my $copy = { %$target };
  for my $i (0 .. $#$result) {
    if ($result->[$i] == $target) {
      $result->[$i] = $copy;
      last;
    }
  }
  return $copies->{$key} = $copy;
}

sub _merge_named_hash {
  my ($target, $extension, $key, $type_name) = @_;
  return if !$extension->{$key};
  my %merged = %{ $target->{$key} || {} };
  for my $name (keys %{ $extension->{$key} }) {
    die "Type extension for '$type_name' redefines $key '$name'.\n"
      if exists $merged{$name};
    $merged{$name} = $extension->{$key}{$name};
  }
  $target->{$key} = \%merged;
}

sub _merge_named_array {
  my ($target, $extension, $key, $type_name) = @_;
  return if !$extension->{$key};
  my @merged = @{ $target->{$key} || [] };
  my %seen = map { ($_ => 1) } @merged;
  for my $name (@{ $extension->{$key} }) {
    die "Type extension for '$type_name' repeats $key member '$name'.\n"
      if $seen{$name}++;
    push @merged, $name;
  }
  $target->{$key} = \@merged;
}

sub _merge_directives {
  my ($target, $extension, $repeatable) = @_;
  return if !$extension->{directives};
  my %seen;
  for my $directive (@{ $target->{directives} || [] }, @{ $extension->{directives} }) {
    my $name = $directive->{name};
    die "Type-system extension repeats non-repeatable directive '\@$name'.\n"
      if $seen{$name}++ && !$repeatable->{$name};
  }
  $target->{directives} = [
    @{ $target->{directives} || [] },
    @{ $extension->{directives} },
  ];
}

sub _merge_type_extension {
  my ($target, $extension, $repeatable) = @_;
  my $name = $target->{name};
  _merge_directives($target, $extension, $repeatable);
  _merge_named_hash($target, $extension, 'fields', $name)
    if $target->{kind} eq 'type' || $target->{kind} eq 'interface'
      || $target->{kind} eq 'input';
  _merge_named_hash($target, $extension, 'values', $name)
    if $target->{kind} eq 'enum';
  _merge_named_array($target, $extension, 'interfaces', $name)
    if $target->{kind} eq 'type' || $target->{kind} eq 'interface';
  _merge_named_array($target, $extension, 'types', $name)
    if $target->{kind} eq 'union';
}

sub _merge_schema_extension {
  my ($target, $extension, $repeatable) = @_;
  _merge_directives($target, $extension, $repeatable);
  for my $operation (@ROOT_ATTRS) {
    next if !$extension->{$operation};
    die "Schema extension redefines $operation root type.\n"
      if $target->{$operation};
    $target->{$operation} = $extension->{$operation};
  }
}

sub _apply_resolvers {
  my ($self, $resolvers) = @_;
  my $name2type = $self->name2type;
  for my $type_name (sort keys %$resolvers) {
    my $type = $name2type->{$type_name}
      // die "Cannot attach resolvers to unknown type '$type_name'.\n";
    my $spec = $resolvers->{$type_name};
    die "Resolvers for '$type_name' must be a hash reference.\n"
      if ref($spec) ne 'HASH';
    for my $key (sort keys %$spec) {
      if ($key eq 'resolve_type' || $key eq 'tag_resolver' || $key eq 'is_type_of'
          || $key eq 'serialize' || $key eq 'parse_value') {
        die "Type '$type_name' does not support '$key'.\n" if !$type->can($key);
        $type->{$key} = $spec->{$key};
        next;
      }
      my $fields = $type->can('fields') ? $type->fields : undef;
      die "Cannot attach a field resolver to '$type_name.$key': no such field.\n"
        if !$fields || !$fields->{$key};
      $fields->{$key}{resolve} = $spec->{$key};
    }
  }
  return $self;
}

my %BUILTIN_SCALARS = map { ($_ => 1) } qw(Int Float String Boolean ID);

sub to_doc {
  my ($self) = @_;
  require GraphQL::Houtou::Internal::TypeSupport;
  my @sections;

  my $default_roots = !grep {
    $self->$_ && $self->$_->name ne ucfirst $_
  } @ROOT_ATTRS;
  if ($self->description || !$default_roots) {
    push @sections, join '', map "$_\n",
      GraphQL::Houtou::Internal::TypeSupport::description_doc_lines($self->description),
      'schema {',
      (map { $self->$_ ? "  $_: @{[$self->$_->name]}" : () } @ROOT_ATTRS),
      '}';
  }

  my %specified = map { ($_->name => 1) } @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES;
  for my $directive (sort { $a->name cmp $b->name } @{ $self->directives || [] }) {
    next if $specified{ $directive->name };
    push @sections, $directive->to_doc;
  }

  my $name2type = $self->name2type;
  for my $name (sort keys %$name2type) {
    my $type = $name2type->{$name} or next;
    next if $BUILTIN_SCALARS{$name};
    next if $name =~ /\A__/;
    next if $type->can('is_introspection') && $type->is_introspection;
    push @sections, $type->to_doc;
  }

  return join "\n", @sections;
}

sub name2type {
  my ($self) = @_;
  return $self->{name2type} ||= $self->_build_name2type;
}

sub name2directive {
  my ($self) = @_;
  return $self->{name2directive} ||= $self->_build_name2directive;
}

sub _interface2types {
  my ($self) = @_;
  return $self->{_interface2types} ||= $self->_build__interface2types;
}

sub _possible_type_map {
  my ($self, @set) = @_;
  $self->{_possible_type_map} = $set[0] if @set;
  return $self->{_possible_type_map};
}

sub prepare_runtime {
  my ($self) = @_;
  return $self->_runtime_cache;
}

sub compile_runtime {
  my ($self, %opts) = @_;
  $self->assert_valid;
  return GraphQL::Houtou::Runtime::SchemaGraph->compile_schema($self, %opts);
}

sub assert_valid {
  my ($self) = @_;
  return $self if $self->{_schema_validated};
  my $errors = $self->validation_errors;
  die join("\n", 'Schema validation failed:', map { "  - $_" } @$errors) . "\n"
    if @$errors;
  $self->{_schema_validated} = 1;
  return $self;
}

sub validation_errors {
  my ($self) = @_;
  my @errors = @{ $self->{_ast_validation_errors} || [] };
  my $name2type = eval { $self->name2type };
  if (!$name2type) {
    my $error = $@ || 'unknown error';
    $error =~ s/\s+\z//;
    $error =~ s/ at \S+ line \d+\.?\z//;
    return [ $error ];
  }

  my %root_name;
  for my $operation (@ROOT_ATTRS) {
    my $root = $self->$operation or next;
    push @errors, "The $operation root type must be an Object type, found "
      . (ref($root) && $root->can('to_string') ? $root->to_string : "'$root'") . '.'
      if !_is_object_type($root);
    if (ref($root) && $root->can('name') && $root_name{ $root->name }++) {
      push @errors, "The query, mutation, and subscription root types must be different; "
        . "@{[$root->name]} is used more than once.";
    }
  }

  my %directive_name;
  for my $directive (@{ $self->directives || [] }) {
    next if !ref($directive) || !$directive->can('name');
    my $name = $directive->name;
    push @errors, "Directive '\@$name' is defined more than once."
      if $directive_name{$name}++;
    push @errors, _reserved_name_error('Directive', $name);
    my %location;
    my $locations = $directive->locations || [];
    push @errors, "Directive '\@$name' must include one or more locations."
      if !@$locations;
    for my $location (@$locations) {
      push @errors, "Directive '\@$name' has unknown location '$location'."
        if !$VALID_DIRECTIVE_LOCATION{$location};
      push @errors, "Directive '\@$name' repeats location '$location'."
        if $location{$location}++;
    }
    for my $arg_name (sort keys %{ $directive->args || {} }) {
      my $arg = $directive->args->{$arg_name};
      push @errors, _reserved_name_error(
        "Argument $arg_name on directive @{[$directive->name]}", $arg_name,
      );
      push @errors, _default_value_error(
        "directive @{[$directive->name]} argument $arg_name", $arg,
      );
      push @errors, _required_deprecation_error(
        'argument @' . $directive->name . "($arg_name:)", $arg,
      );
    }
  }

  for my $type_name (sort keys %$name2type) {
    my $type = $name2type->{$type_name} or next;
    next if $type->can('is_introspection') && $type->{is_introspection};

    push @errors, _reserved_name_error('Type', $type_name);
    if ($type->can('fields')) {
      my $fields = $type->fields || {};
      for my $field_name (sort keys %$fields) {
        my $field = $fields->{$field_name};
        push @errors, _reserved_name_error(
          (_is_input_type($type) ? 'Input field' : 'Field')
            . " $type_name.$field_name",
          $field_name,
        );
        for my $arg_name (sort keys %{ $field->{args} || {} }) {
          my $arg = $field->{args}{$arg_name};
          push @errors, _reserved_name_error(
            "Argument $type_name.$field_name($arg_name:)", $arg_name,
          );
          push @errors, _default_value_error(
            "argument $type_name.$field_name($arg_name:)", $arg,
          );
          push @errors, _required_deprecation_error(
            "argument $type_name.$field_name($arg_name:)", $arg,
          );
        }
      }
    }
    if ($type->isa('GraphQL::Houtou::Type::Enum')) {
      for my $value_name (sort keys %{ $type->values || {} }) {
        push @errors, _reserved_name_error(
          "Enum value $type_name.$value_name", $value_name,
        );
      }
    }

    if (_is_object_type($type)) {
      push @errors, "Object type @{[$type->name]} must define one or more fields."
        if !keys %{ $type->fields || {} };
      push @errors, _implemented_interface_errors($type);
      push @errors, $self->_object_field_errors($type);
      for my $interface (@{ $type->interfaces || [] }) {
        if (!ref($interface) || !_is_interface_type($interface)) {
          push @errors, "Type @{[$type->name]} must only implement Interface types, "
            . 'found ' . (ref($interface) ? $interface->to_string : "'$interface'") . '.';
          next;
        }
        push @errors, $self->_interface_conformance_errors($type, $interface);
      }
    }
    elsif (_is_interface_type($type)) {
      push @errors, "Interface type @{[$type->name]} must define one or more fields."
        if !keys %{ $type->fields || {} };
      push @errors, _implemented_interface_errors($type);
      push @errors, $self->_object_field_errors($type);
      for my $interface (@{ $type->interfaces || [] }) {
        if (!ref($interface) || !_is_interface_type($interface)) {
          push @errors, "Type @{[$type->name]} must only implement Interface types, "
            . 'found ' . (ref($interface) ? $interface->to_string : "'$interface'") . '.';
          next;
        }
        push @errors, $self->_interface_conformance_errors($type, $interface);
      }
    }
    elsif ($type->isa('GraphQL::Houtou::Type::Union')) {
      my $members = $type->types || [];
      push @errors, "Union type @{[$type->name]} must define one or more member types."
        if !@$members;
      for my $member (@$members) {
        push @errors, "Union type @{[$type->name]} can only include Object types, "
          . 'found ' . (ref($member) ? $member->to_string : "'$member'") . '.'
          if !ref($member) || !_is_object_type($member);
      }
    }
    elsif ($type->isa('GraphQL::Houtou::Type::Enum')) {
      push @errors, "Enum type @{[$type->name]} must define one or more values."
        if !keys %{ $type->values || {} };
    }
    elsif ($type->isa('GraphQL::Houtou::Type::InputObject')) {
      my $fields = $type->fields || {};
      push @errors, "Input Object type @{[$type->name]} must define one or more fields."
        if !keys %$fields;
      my $is_one_of = $type->can('is_one_of') && $type->is_one_of;
      for my $field_name (sort keys %$fields) {
        my $field = $fields->{$field_name};
        my $field_type = $field->{type};
        push @errors, "The type of @{[$type->name]}.$field_name must be Input Type"
          . (ref($field_type) ? ' but got: ' . $field_type->to_string . '.' : '.')
          if !_is_input_type($field_type);
        push @errors, _default_value_error(
          "input field @{[$type->name]}.$field_name", $field,
        );
        push @errors, _required_deprecation_error(
          "input field @{[$type->name]}.$field_name", $field,
        );
        if ($is_one_of) {
          push @errors, "OneOf input field @{[$type->name]}.$field_name must be nullable."
            if ref($field_type) && $field_type->isa('GraphQL::Houtou::Type::NonNull');
          push @errors, "OneOf input field @{[$type->name]}.$field_name cannot have a default value."
            if exists $field->{default_value};
        }
      }
    }
  }

  push @errors, $self->_input_object_cycle_errors($name2type);
  push @errors, $self->_interface_cycle_errors($name2type);

  return \@errors;
}

sub _interface_cycle_errors {
  my ($self, $name2type) = @_;
  my (@errors, %state, @path, %path_index);

  my $visit;
  $visit = sub {
    my ($type) = @_;
    my $name = $type->name;
    $state{$name} = 1;
    $path_index{$name} = scalar @path;
    push @path, $name;

    for my $next (@{ $type->interfaces || [] }) {
      next if !ref($next) || !_is_interface_type($next);
      my $next_name = $next->name;
      if (($state{$next_name} || 0) == 1) {
        my @cycle = (@path[$path_index{$next_name} .. $#path], $next_name);
        push @errors, 'Interface implementation cannot contain a circular reference: '
          . join(' -> ', @cycle) . '.';
      }
      elsif (!$state{$next_name}) {
        $visit->($next);
      }
    }

    pop @path;
    delete $path_index{$name};
    $state{$name} = 2;
    return;
  };

  for my $name (sort keys %$name2type) {
    my $type = $name2type->{$name};
    next if !$type || !_is_interface_type($type) || $state{$name};
    $visit->($type);
  }
  return @errors;
}

sub _input_object_cycle_errors {
  my ($self, $name2type) = @_;
  my (@errors, %state, @path, %path_index);

  my $visit;
  $visit = sub {
    my ($type) = @_;
    my $name = $type->name;
    $state{$name} = 1;
    $path_index{$name} = scalar @path;
    push @path, $name;

    for my $field_name (sort keys %{ $type->fields || {} }) {
      my $next = _required_singular_input_object($type->fields->{$field_name}{type});
      next if !$next;
      my $next_name = $next->name;
      if (($state{$next_name} || 0) == 1) {
        my @cycle = (@path[$path_index{$next_name} .. $#path], $next_name);
        push @errors, 'Input Object circular reference cannot form an unbroken chain '
          . 'of singular Non-Null fields: ' . join(' -> ', @cycle) . '.';
      }
      elsif (!$state{$next_name}) {
        $visit->($next);
      }
    }

    pop @path;
    delete $path_index{$name};
    $state{$name} = 2;
    return;
  };

  for my $name (sort keys %$name2type) {
    my $type = $name2type->{$name};
    next if !$type || !$type->isa('GraphQL::Houtou::Type::InputObject') || $state{$name};
    $visit->($type);
  }
  return @errors;
}

sub _required_singular_input_object {
  my ($type) = @_;
  return if !ref($type) || !$type->isa('GraphQL::Houtou::Type::NonNull');
  my $of = $type->of;
  return if !ref($of) || $of->isa('GraphQL::Houtou::Type::List');
  return $of if $of->isa('GraphQL::Houtou::Type::InputObject');
  return;
}

sub _reserved_name_error {
  my ($coordinate, $name) = @_;
  return () if !defined($name) || $name !~ /\A__/;
  return "$coordinate must not begin with '__', which is reserved for introspection.";
}

sub _default_value_error {
  my ($coordinate, $definition) = @_;
  return () if !exists $definition->{default_value};
  my $type = $definition->{type};
  return () if !_is_input_type($type);
  if (my $detail = _missing_required_input_field(
      $type, $definition->{default_value}, q())) {
    return "The default value for $coordinate is invalid for type "
      . $type->to_string . ": $detail.";
  }
  my $ok = eval { $type->graphql_to_perl($definition->{default_value}); 1 };
  return () if $ok;
  my $detail = $@ || 'invalid value';
  $detail =~ s/\s+\z//;
  $detail =~ s/ at \S+ line \d+\.?\z//;
  return "The default value for $coordinate is invalid for type "
    . $type->to_string . ": $detail.";
}

sub _missing_required_input_field {
  my ($type, $value, $path) = @_;
  return if !ref($type) || !defined($value);
  $type = $type->of if $type->isa('GraphQL::Houtou::Type::NonNull');
  if ($type->isa('GraphQL::Houtou::Type::List')) {
    my $values = ref($value) eq 'ARRAY' ? $value : [ $value ];
    for my $index (0 .. $#$values) {
      my $error = _missing_required_input_field(
        $type->of, $values->[$index], "$path\[$index\]",
      );
      return $error if $error;
    }
    return;
  }
  return if !$type->isa('GraphQL::Houtou::Type::InputObject')
    || ref($value) ne 'HASH';

  for my $field_name (sort keys %{ $type->fields || {} }) {
    my $field = $type->fields->{$field_name};
    my $field_path = length($path) ? "$path.$field_name" : $field_name;
    if (!exists($value->{$field_name}) && !exists($field->{default_value})
        && ref($field->{type})
        && $field->{type}->isa('GraphQL::Houtou::Type::NonNull')) {
      return "required input field $field_path is missing";
    }
    next if !exists $value->{$field_name};
    my $error = _missing_required_input_field(
      $field->{type}, $value->{$field_name}, $field_path,
    );
    return $error if $error;
  }
  return;
}

sub _required_deprecation_error {
  my ($coordinate, $definition) = @_;
  return () if !ref($definition->{type})
    || !$definition->{type}->isa('GraphQL::Houtou::Type::NonNull')
    || exists($definition->{default_value})
    || (!$definition->{is_deprecated}
      && !defined($definition->{deprecation_reason}));
  return "Required $coordinate cannot be deprecated.";
}

sub _implemented_interface_errors {
  my ($type) = @_;
  my (@errors, %seen);
  for my $interface (@{ $type->interfaces || [] }) {
    next if !ref($interface) || !$interface->can('name');
    my $name = $interface->name;
    push @errors, "Type @{[$type->name]} can only implement $name once."
      if $seen{$name}++;
    push @errors, "Type @{[$type->name]} cannot implement itself."
      if $type == $interface;
  }
  return @errors;
}

sub _object_field_errors {
  my ($self, $type) = @_;
  my @errors;
  my $fields = $type->fields || {};
  for my $field_name (sort keys %$fields) {
    my $field = $fields->{$field_name};
    my $field_type = $field->{type};
    push @errors, "The type of @{[$type->name]}.$field_name must be Output Type"
      . (ref($field_type) ? ' but got: ' . $field_type->to_string . '.' : '.')
      if !_is_output_type($field_type);
    for my $arg_name (sort keys %{ $field->{args} || {} }) {
      my $arg_type = $field->{args}{$arg_name}{type};
      push @errors, "The type of @{[$type->name]}.$field_name($arg_name:) must be Input Type"
        . (ref($arg_type) ? ' but got: ' . $arg_type->to_string . '.' : '.')
        if !_is_input_type($arg_type);
    }
  }
  return @errors;
}

sub _interface_conformance_errors {
  my ($self, $object, $interface) = @_;
  my @errors;
  my $interface_fields = $interface->fields || {};
  my $object_fields = $object->fields || {};

  my %implemented = map { ($_->name => 1) }
    grep { ref($_) } @{ $object->interfaces || [] };
  for my $inherited (@{ $interface->interfaces || [] }) {
    push @errors, "Type @{[$object->name]} must implement @{[$inherited->name]} "
      . "because it is implemented by @{[$interface->name]}."
      if !$implemented{ $inherited->name };
  }

  for my $field_name (sort keys %$interface_fields) {
    my $interface_field = $interface_fields->{$field_name};
    my $object_field = $object_fields->{$field_name};

    if (!$object_field) {
      push @errors, "Interface field @{[$interface->name]}.$field_name expected "
        . "but @{[$object->name]} does not provide it.";
      next;
    }

    if (ref($interface_field->{type}) && ref($object_field->{type})
        && !$self->_is_sub_type($object_field->{type}, $interface_field->{type})) {
      push @errors, "Interface field @{[$interface->name]}.$field_name expects type "
        . "@{[$interface_field->{type}->to_string]} but @{[$object->name]}.$field_name "
        . "is type @{[$object_field->{type}->to_string]}.";
    }

    my $interface_args = $interface_field->{args} || {};
    my $object_args = $object_field->{args} || {};
    for my $arg_name (sort keys %$interface_args) {
      my $interface_arg = $interface_args->{$arg_name};
      my $object_arg = $object_args->{$arg_name};
      if (!$object_arg) {
        push @errors, "Interface field argument "
          . "@{[$interface->name]}.$field_name($arg_name:) expected "
          . "but @{[$object->name]}.$field_name does not provide it.";
        next;
      }
      if (ref($interface_arg->{type}) && ref($object_arg->{type})
          && $interface_arg->{type}->to_string ne $object_arg->{type}->to_string) {
        push @errors, "Interface field argument "
          . "@{[$interface->name]}.$field_name($arg_name:) expects type "
          . "@{[$interface_arg->{type}->to_string]} but "
          . "@{[$object->name]}.$field_name($arg_name:) is type "
          . "@{[$object_arg->{type}->to_string]}.";
      }
    }
    for my $arg_name (sort keys %$object_args) {
      next if $interface_args->{$arg_name};
      my $arg = $object_args->{$arg_name};
      my $arg_type = $arg->{type};
      if (ref($arg_type) && $arg_type->isa('GraphQL::Houtou::Type::NonNull')
          && !exists $arg->{default_value}) {
        push @errors, "Object field @{[$object->name]}.$field_name includes required "
          . "argument $arg_name that is missing from the Interface field "
          . "@{[$interface->name]}.$field_name.";
      }
    }
  }

  return @errors;
}

# Spec IsValidImplementationFieldType: object field types are covariant
# against the interface field type.
sub _is_sub_type {
  my ($self, $maybe, $super) = @_;
  return 0 if !ref($maybe) || !ref($super);
  if ($super->isa('GraphQL::Houtou::Type::NonNull')) {
    return 0 if !$maybe->isa('GraphQL::Houtou::Type::NonNull');
    return $self->_is_sub_type($maybe->of, $super->of);
  }
  return $self->_is_sub_type($maybe->of, $super)
    if $maybe->isa('GraphQL::Houtou::Type::NonNull');
  if ($super->isa('GraphQL::Houtou::Type::List')) {
    return 0 if !$maybe->isa('GraphQL::Houtou::Type::List');
    return $self->_is_sub_type($maybe->of, $super->of);
  }
  return 0 if $maybe->isa('GraphQL::Houtou::Type::List');
  return 1 if $maybe->name eq $super->name;
  if (_is_object_type($maybe) || _is_interface_type($maybe)) {
    return 1 if _is_interface_type($super)
      && grep { ref($_) && $_->name eq $super->name } @{ $maybe->interfaces || [] };
    return 1 if $super->isa('GraphQL::Houtou::Type::Union')
      && grep { ref($_) && $_->name eq $maybe->name } @{ $super->types || [] };
  }
  return 0;
}

sub _is_object_type {
  my ($type) = @_;
  return ref($type)
    && ($type->isa('GraphQL::Houtou::Type::Object') || $type->isa('GraphQL::Type::Object'));
}

sub _is_interface_type {
  my ($type) = @_;
  return ref($type)
    && ($type->isa('GraphQL::Houtou::Type::Interface') || $type->isa('GraphQL::Type::Interface'));
}

sub _is_output_type {
  my ($type) = @_;
  return ref($type) && _does_any_role($type, qw(
    GraphQL::Houtou::Role::Output
    GraphQL::Role::Output
  ));
}

sub _is_input_type {
  my ($type) = @_;
  return ref($type) && _does_any_role($type, qw(
    GraphQL::Houtou::Role::Input
    GraphQL::Role::Input
  ));
}

sub build_native_runtime {
  my ($self, %opts) = @_;
  my $cache_max = delete $opts{program_cache_max};
  my $max_depth = delete $opts{max_depth};
  my $max_nodes = delete $opts{max_nodes};
  my $max_cost = delete $opts{max_cost};
  my $default_list_size = delete $opts{default_list_size};
  my $async = delete $opts{async};
  my $validate = delete $opts{validate};
  my $allow_introspection = delete $opts{allow_introspection};
  my %runtime_args;
  $runtime_args{program_cache_max} = $cache_max if defined $cache_max;
  $runtime_args{max_depth}         = $max_depth if defined $max_depth;
  $runtime_args{max_nodes}         = $max_nodes if defined $max_nodes;
  $runtime_args{max_cost}          = $max_cost if defined $max_cost;
  $runtime_args{default_list_size} = $default_list_size if defined $default_list_size;
  $runtime_args{async}             = $async if defined $async;
  $runtime_args{validate}          = $validate if defined $validate;
  $runtime_args{allow_introspection} = $allow_introspection
    if defined $allow_introspection;
  if (%opts || %runtime_args) {
    my $runtime_schema = %opts ? $self->compile_runtime(%opts) : $self->build_runtime;
    require GraphQL::Houtou::Runtime::NativeRuntime;
    return GraphQL::Houtou::Runtime::NativeRuntime->new(
      runtime_schema => $runtime_schema,
      %runtime_args,
    );
  }
  return $self->{_compiled_native_runtime} if $self->{_compiled_native_runtime};
  require GraphQL::Houtou::Runtime::NativeRuntime;
  return $self->{_compiled_native_runtime} = GraphQL::Houtou::Runtime::NativeRuntime->new(
    runtime_schema => $self->build_runtime,
  );
}

sub build_runtime {
  my ($self, %opts) = @_;
  return $self->compile_runtime(%opts) if %opts;
  return $self->{_compiled_runtime_graph} if $self->{_compiled_runtime_graph};
  return $self->{_compiled_runtime_graph} = $self->compile_runtime;
}

sub compile_runtime_descriptor {
  my ($self, %opts) = @_;
  return $self->compile_runtime(%opts)->to_struct;
}

sub compile_native_runtime_descriptor {
  my ($self, %opts) = @_;
  return $self->compile_runtime(%opts)->to_native_struct;
}

sub inflate_runtime {
  my ($self, $descriptor) = @_;
  return GraphQL::Houtou::Runtime::SchemaGraph->inflate_schema($self, $descriptor);
}

sub dump_runtime_descriptor {
  my ($self, $path, %opts) = @_;
  my $descriptor = $self->compile_runtime_descriptor(%opts);
  _write_json_descriptor($path, $descriptor);
  return $descriptor;
}

sub dump_native_runtime_descriptor {
  my ($self, $path, %opts) = @_;
  my $descriptor = $self->compile_native_runtime_descriptor(%opts);
  _write_json_descriptor($path, $descriptor);
  return $descriptor;
}

sub load_runtime_descriptor {
  my ($self, $path) = @_;
  my $descriptor = _read_json_descriptor($path);
  return $self->inflate_runtime($descriptor);
}

sub load_native_runtime_descriptor {
  my ($self, $path) = @_;
  return _read_json_descriptor($path);
}

sub compile_program {
  my ($self, $document, %opts) = @_;
  my $runtime = $self->build_runtime;
  return $runtime->compile_program($document, %opts);
}

sub compile_program_descriptor {
  my ($self, $document, %opts) = @_;
  my $runtime = $self->build_runtime;
  return $runtime->compile_program_descriptor($document, %opts);
}

sub dump_program_descriptor {
  my ($self, $document, $path, %opts) = @_;
  my $descriptor = $self->compile_program_descriptor($document, %opts);
  _write_json_descriptor($path, $descriptor);
  return $descriptor;
}

sub load_program_descriptor {
  my ($self, $path, %opts) = @_;
  my $descriptor = _read_json_descriptor($path);
  return $self->inflate_program($descriptor, %opts);
}

sub inflate_program {
  my ($self, $descriptor, %opts) = @_;
  my $runtime = $self->build_runtime;
  return $runtime->inflate_program($descriptor, %opts);
}

sub execute {
  my ($self, $document, %opts) = @_;
  die "promise_code is no longer supported; Promise::XS is detected automatically.\n"
    if exists $opts{promise_code};

  my $runtime = $self->build_native_runtime;
  return $runtime->execute_document($document, %opts);
}

sub compile_native_program_descriptor {
  my ($self, $document, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->compile_program_descriptor_for_document($document, %opts);
}

sub compile_native_program {
  my ($self, $document, %opts) = @_;
  GraphQL::Houtou::_bootstrap_xs();
  return GraphQL::Houtou::XS::VM::load_native_program_xs(
    $self->compile_native_program_descriptor($document, %opts),
  );
}

sub compile_native_bundle_descriptor {
  my ($self, $document, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->compile_bundle_descriptor_for_document($document, %opts);
}

sub compile_native_bundle {
  my ($self, $document, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->compile_bundle_for_document($document, %opts);
}

sub dump_native_bundle_descriptor {
  my ($self, $document, $path, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->dump_bundle_descriptor_for_document($document, $path, %opts);
}

sub load_native_bundle_descriptor {
  my ($self, $path) = @_;
  return _read_json_descriptor($path);
}

sub load_native_bundle {
  my ($self, $descriptor) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->load_bundle_descriptor($descriptor);
}

sub load_native_bundle_file {
  my ($self, $path) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->load_bundle_descriptor_file($path);
}

sub inflate_native_bundle_descriptor {
  my ($self, $descriptor, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->inflate_bundle_descriptor($descriptor);
}

sub execute_native_bundle_descriptor {
  my ($self, $descriptor, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->execute_bundle_descriptor($descriptor, %opts);
}

sub execute_native {
  my ($self, $document, %opts) = @_;
  my $runtime = $self->build_native_runtime;
  return $runtime->execute_document($document, %opts, strict_sync => 1);
}

sub runtime_cache {
  my ($self) = @_;
  return $self->{_runtime_cache};
}

sub clear_runtime_cache {
  my ($self) = @_;
  delete $self->{_runtime_cache};
  delete $self->{_compiled_runtime_graph};
  delete $self->{_compiled_native_runtime};
  return $self;
}

sub _runtime_cache {
  my ($self) = @_;
  return $self->{_runtime_cache} if $self->{_runtime_cache};

  my $name2type = $self->name2type || {};
  my $interface2types = $self->_interface2types || {};
  my $possible_type_map = { %{ $self->_possible_type_map || {} } };
  my %possible_types;
  my %field_maps;
  my %resolve_type_map;
  my %is_type_of_map;
  my %tag_resolver_map;
  my %runtime_tag_map;
  my %leaf_kind_map;
  my %enum_values_map;
  my %serialize_map;

  # Codes shared with the native runtime's leaf result coercion
  # (gql_runtime_vm_serialize_leaf_sv): the executor checks resolver
  # output against the field's leaf type at completion time.
  my %BUILTIN_LEAF_KIND = (
    Int => 1, Float => 2, String => 3, Boolean => 4, ID => 5,
  );

  for my $type (values %$name2type) {
    next if !$type;

    my $type_name = $type->name;
    if (defined $BUILTIN_LEAF_KIND{$type_name}
        && $type->isa('GraphQL::Houtou::Type::Scalar')) {
      $leaf_kind_map{$type_name} = $BUILTIN_LEAF_KIND{$type_name};
    } elsif ($type->isa('GraphQL::Houtou::Type::Enum')) {
      # Serialization maps the internal value back to the enum name
      # (Enum->perl_to_graphql); with default values this is identity.
      my $values = $type->values || {};
      $leaf_kind_map{$type_name} = 6;
      $enum_values_map{$type_name} = {
        map { ($values->{$_}{value} => $_) } keys %$values
      };
    } elsif ($type->isa('GraphQL::Houtou::Type::Scalar')) {
      $leaf_kind_map{$type_name} = 7;
      $serialize_map{$type_name} = $type->serialize if $type->serialize;
    }

    if (_does_any_role($type, qw(
      GraphQL::Houtou::Role::FieldsOutput
      GraphQL::Role::FieldsOutput
    ))) {
      $field_maps{ $type->name } = $type->fields || {};
    }

    if ($type->isa('GraphQL::Type::Object') || $type->isa('GraphQL::Houtou::Type::Object')) {
      my $is_type_of = $type->is_type_of;
      $is_type_of_map{ $type->name } = $is_type_of if $is_type_of;
    }

    if ($type->isa('GraphQL::Type::Union') || $type->isa('GraphQL::Houtou::Type::Union')) {
      my $types = $type->types || [];
      my $resolve_type = $type->resolve_type;
      my $tag_resolver = $type->can('tag_resolver') ? $type->tag_resolver : undef;
      $resolve_type_map{ $type->name } = $resolve_type if $resolve_type;
      $tag_resolver_map{ $type->name } = $tag_resolver if $tag_resolver;
      $possible_types{ $type->name } = [ @$types ];
      $possible_type_map->{ $type->name } ||= { map { ($_->name => 1) } @$types };
      if (my $tag_map = _build_runtime_tag_map($type, $types, $name2type)) {
        $runtime_tag_map{ $type->name } = $tag_map;
      }
      next;
    }

    if ($type->isa('GraphQL::Type::Interface') || $type->isa('GraphQL::Houtou::Type::Interface')) {
      my $types = [ @{ $interface2types->{ $type->name } || [] } ];
      my $resolve_type = $type->resolve_type;
      my $tag_resolver = $type->can('tag_resolver') ? $type->tag_resolver : undef;
      $resolve_type_map{ $type->name } = $resolve_type if $resolve_type;
      $tag_resolver_map{ $type->name } = $tag_resolver if $tag_resolver;
      $possible_types{ $type->name } = $types;
      $possible_type_map->{ $type->name } ||= { map { ($_->name => 1) } @$types };
      if (my $tag_map = _build_runtime_tag_map($type, $types, $name2type)) {
        $runtime_tag_map{ $type->name } = $tag_map;
      }
      next;
    }
  }

  return $self->{_runtime_cache} = {
    root_types => {
      query => $self->{query},
      mutation => $self->{mutation},
      subscription => $self->{subscription},
    },
    name2type => $name2type,
    interface2types => $interface2types,
    possible_type_map => $possible_type_map,
    possible_types => \%possible_types,
    field_maps => \%field_maps,
    resolve_type_map => \%resolve_type_map,
    is_type_of_map => \%is_type_of_map,
    tag_resolver_map => \%tag_resolver_map,
    runtime_tag_map => \%runtime_tag_map,
    leaf_kind_map => \%leaf_kind_map,
    enum_values_map => \%enum_values_map,
    serialize_map => \%serialize_map,
  };
}

sub _build_runtime_tag_map {
  my ($abstract_type, $possible_types, $name2type) = @_;
  my %tag_map;
  my $declared = $abstract_type->can('tag_map') ? $abstract_type->tag_map : undef;

  if ($declared) {
    for my $tag (keys %$declared) {
      my $target = $declared->{$tag};
      my $type = ref($target) ? $target : $name2type->{$target};
      next if !$type;
      next if !($type->isa('GraphQL::Type::Object') || $type->isa('GraphQL::Houtou::Type::Object'));
      $tag_map{$tag} = $type;
    }
  }

  for my $type (@{ $possible_types || [] }) {
    next if !$type || !$type->can('runtime_tag');
    my $tag = $type->runtime_tag;
    next if !defined $tag || ref($tag);
    $tag_map{$tag} ||= $type;
  }

  return keys(%tag_map) ? \%tag_map : undef;
}

sub _build_name2type {
  my ($self) = @_;
  my @types = grep $_, (map $self->$_, qw(query mutation subscription)), $SCHEMA_META_TYPE;
  push @types, @{ $self->types || [] };

  my %name2type;
  _expand_type_houtou(\%name2type, $_) for @types;
  # The built-in scalars are always available (spec 3.5) even when nothing
  # in the schema references them, e.g. a variable declared as Int against
  # a schema whose fields are all String.
  for my $builtin (
    $GraphQL::Houtou::Type::Scalar::Int,
    $GraphQL::Houtou::Type::Scalar::Float,
    $GraphQL::Houtou::Type::Scalar::String,
    $GraphQL::Houtou::Type::Scalar::Boolean,
    $GraphQL::Houtou::Type::Scalar::ID,
  ) {
    $name2type{ $builtin->name } //= $builtin;
  }
  return \%name2type;
}

sub _write_json_descriptor {
  my ($path, $descriptor) = @_;
  open my $fh, '>', $path or die "Cannot write descriptor '$path': $!";
  print {$fh} $JSON->encode($descriptor);
  close $fh or die "Cannot close descriptor '$path': $!";
  return;
}

sub _read_json_descriptor {
  my ($path) = @_;
  open my $fh, '<', $path or die "Cannot read descriptor '$path': $!";
  local $/;
  my $json = <$fh>;
  close $fh or die "Cannot close descriptor '$path': $!";
  return $JSON->decode($json);
}

sub _does_any_role {
  my ($type, @roles) = @_;
  return if !$type || !$type->can('DOES');
  return !!grep { $type->DOES($_) } @roles;
}

sub _build_name2directive {
  my ($self) = @_;
  return +{ map { ($_->name => $_) } @{ $self->directives || [] } };
}

sub _build__interface2types {
  my ($self) = @_;
  my $name2type = $self->name2type || {};
  my %interface2types;

  for my $type (values %$name2type) {
    next if !($type->isa('GraphQL::Type::Object') || $type->isa('GraphQL::Houtou::Type::Object'));
    my @queue = @{ $type->interfaces || [] };
    my %seen;
    while (my $interface = shift @queue) {
      next if !$interface || $seen{ $interface->name }++;
      push @{ $interface2types{ $interface->name } }, $type;
      push @queue, @{ $interface->can('interfaces') ? $interface->interfaces : [] };
    }
  }

  return \%interface2types;
}

sub get_possible_types {
  my ($self, $abstract_type) = @_;
  return $abstract_type->get_types
    if $abstract_type->isa('GraphQL::Type::Union') || $abstract_type->isa('GraphQL::Houtou::Type::Union');
  return $self->_interface2types->{ $abstract_type->name } || [];
}

sub is_possible_type {
  my ($self, $abstract_type, $possible_type) = @_;
  my $map = $self->_possible_type_map || {};
  my @possibles;

  return $map->{$abstract_type->name}{$possible_type->name}
    if $map->{$abstract_type->name};

  @possibles = @{ $self->get_possible_types($abstract_type) || [] };
  die <<"EOF" if !@possibles;
Could not find possible implementing types for @{[$abstract_type->name]}
in schema. Check that schema.types is defined and is an array of
all possible types in the schema.
EOF
  $map->{$abstract_type->name} = { map { ($_->name => 1) } @possibles };
  $self->_possible_type_map($map);
  if ($self->{_runtime_cache}) {
    $self->{_runtime_cache}{possible_type_map} = $map;
  }
  return $map->{$abstract_type->name}{$possible_type->name};
}

sub _expand_type_houtou {
  my ($map, $type) = @_;
  my @types;
  my $name;

  if ($type->can('of')) {
    return _expand_type_houtou($map, $type->of);
  }

  $name = $type->name if $type->can('name');
  if ($name && $map->{$name}) {
    return []
      if $map->{$name} == $type;
    return []
      if _is_builtin_scalar_pair($map->{$name}, $type);
    die "Duplicate type $name";
  }

  $map->{$name} = $type if $name;

  push @types, ($type, map @{ _expand_type_houtou($map, $_) }, @{ $type->interfaces || [] })
    if $type->isa('GraphQL::Type::Object') || $type->isa('GraphQL::Houtou::Type::Object');
  push @types, ($type, map @{ _expand_type_houtou($map, $_) }, @{ $type->get_types })
    if $type->isa('GraphQL::Type::Union') || $type->isa('GraphQL::Houtou::Type::Union');
  if (_does_any_role($type, qw(
    GraphQL::Houtou::Role::FieldsInput
    GraphQL::Houtou::Role::FieldsOutput
    GraphQL::Role::FieldsInput
    GraphQL::Role::FieldsOutput
  ))) {
    my $fields = $type->fields || {};
    push @types, map {
      map @{ _expand_type_houtou($map, $_->{type}) }, $_, values %{ $_->{args} || {} }
    } values %$fields;
  }

  return \@types;
}

sub _is_builtin_scalar_pair {
  my ($left, $right) = @_;
  return 0 if !$left || !$right;
  return 0 if !(
    ($left->isa('GraphQL::Type::Scalar') || $left->isa('GraphQL::Houtou::Type::Scalar'))
    && ($right->isa('GraphQL::Type::Scalar') || $right->isa('GraphQL::Houtou::Type::Scalar'))
  );
  return 0 if !(grep { $_ eq $left->name } qw(Int Float String Boolean ID));
  return $left->name eq $right->name ? 1 : 0;
}

sub lookup_type {
  my ($typedef, $name2type) = @_;
  my ($type, $wrapper_type, $wrapped);

  die "lookup_type expects a type definition hash reference\n"
    if ref($typedef) ne 'HASH';
  die "lookup_type expects a name2type hash reference\n"
    if ref($name2type) ne 'HASH';

  $type = $typedef->{type};
  die "Undefined type given\n" if !defined $type;

  if (!ref($type)) {
    return $name2type->{$type} // die "Unknown type '$type'.\n";
  }

  if (ref($type) ne 'ARRAY') {
    die "Unknown wrapped type representation\n";
  }

  ($wrapper_type, $wrapped) = @$type;
  return lookup_type($wrapped, $name2type)->$wrapper_type;
}

1;
__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Schema - schema container for GraphQL::Houtou

=head1 SYNOPSIS

    use GraphQL::Houtou::Schema;
    use GraphQL::Houtou::Type::Object;
    use GraphQL::Houtou::Type::Scalar qw($String);

    my $schema = GraphQL::Houtou::Schema->new(
      query => GraphQL::Houtou::Type::Object->new(
        name   => 'Query',
        fields => {
          hello => { type => $String, resolve => sub { 'world' } },
        },
      ),
    );

    # or from SDL
    my $schema = GraphQL::Houtou::Schema->from_doc($sdl, resolvers => \%resolvers);

    my $runtime = $schema->build_native_runtime(async => 1);

=head1 DESCRIPTION

Holds the root operation types, the type registry, and the directive
definitions, and is the factory for execution runtimes. Most applications
build one schema at startup and one native runtime from it.

=head1 CONSTRUCTORS

=head2 new(%args)

C<query> is required; C<mutation>, C<subscription>, C<description>,
C<types>, and C<directives> are optional. C<types> defaults to the
built-in scalars; list types here when they are reachable only through
an interface or union (concrete types behind abstract fields).

=head2 from_doc($sdl, %opts) / from_ast($ast, %opts)

Build a schema from SDL (or its parsed AST). Resolvers, abstract type
dispatch, and custom scalar coercion attach through
C<< resolvers => { TypeName => { field => sub {...} } } >>; see
L<GraphQL::Houtou/Building a schema from SDL>.

=head1 METHODS

=head2 build_native_runtime(%opts)

Compiles the schema and returns a
L<GraphQL::Houtou::Runtime::NativeRuntime>. Options: C<async> (declare
that resolvers return promises; see
L<GraphQL::Houtou/Batching resolvers (DataLoader / the on_stall hook)>),
C<program_cache_max> (per-query program cache size, default 1000),
C<max_depth>, C<max_nodes>, C<max_cost>, and C<default_list_size>. With no
options the compiled runtime is cached on the
schema, so repeated calls are cheap.

=head2 assert_valid / validation_errors

C<validation_errors> returns an arrayref of schema-validation messages
(interface conformance, input/output type placement, and so on);
C<assert_valid> dies with the collected messages and is memoized.

=head2 to_doc

Renders the schema back to SDL, matching graphql-js C<printSchema>
conventions; also exposed as C<print_schema()> in L<GraphQL::Houtou>.

=head2 Accessors

C<query>, C<mutation>, C<subscription>, C<types>, C<directives>,
C<description>, C<name2type>, C<get_possible_types($abstract)>,
C<is_possible_type($abstract, $object)>.

=head1 SEE ALSO

L<GraphQL::Houtou>, L<GraphQL::Houtou::Runtime::NativeRuntime>

=cut
