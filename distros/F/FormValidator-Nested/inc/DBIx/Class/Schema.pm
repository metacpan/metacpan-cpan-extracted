#line 1
package DBIx::Class::Schema;

use strict;
use warnings;

use DBIx::Class::Exception;
use Carp::Clan qw/^DBIx::Class/;
use Scalar::Util qw/weaken/;
use File::Spec;
use Sub::Name ();
use Module::Find();

use base qw/DBIx::Class/;

__PACKAGE__->mk_classdata('class_mappings' => {});
__PACKAGE__->mk_classdata('source_registrations' => {});
__PACKAGE__->mk_classdata('storage_type' => '::DBI');
__PACKAGE__->mk_classdata('storage');
__PACKAGE__->mk_classdata('exception_action');
__PACKAGE__->mk_classdata('stacktrace' => $ENV{DBIC_TRACE} || 0);
__PACKAGE__->mk_classdata('default_resultset_attributes' => {});

#line 148

# Pre-pends our classname to the given relative classname or
#   class namespace, unless there is a '+' prefix, which will
#   be stripped.
sub _expand_relative_name {
  my ($class, $name) = @_;
  return if !$name;
  $name = $class . '::' . $name if ! ($name =~ s/^\+//);
  return $name;
}

# Finds all modules in the supplied namespace, or if omitted in the
# namespace of $class. Untaints all findings as they can be assumed
# to be safe
sub _findallmod {
  my $proto = shift;
  my $ns = shift || ref $proto || $proto;

  my @mods = Module::Find::findallmod($ns);

  # try to untaint module names. mods where this fails
  # are left alone so we don't have to change the old behavior
  no locale; # localized \w doesn't untaint expression
  return map { $_ =~ m/^( (?:\w+::)* \w+ )$/x ? $1 : $_ } @mods;
}

# returns a hash of $shortname => $fullname for every package
# found in the given namespaces ($shortname is with the $fullname's
# namespace stripped off)
sub _map_namespaces {
  my ($class, @namespaces) = @_;

  my @results_hash;
  foreach my $namespace (@namespaces) {
    push(
      @results_hash,
      map { (substr($_, length "${namespace}::"), $_) }
      $class->_findallmod($namespace)
    );
  }

  @results_hash;
}

# returns the result_source_instance for the passed class/object,
# or dies with an informative message (used by load_namespaces)
sub _ns_get_rsrc_instance {
  my $class = shift;
  my $rs = ref ($_[0]) || $_[0];

  if ($rs->can ('result_source_instance') ) {
    return $rs->result_source_instance;
  }
  else {
    $class->throw_exception (
      "Attempt to load_namespaces() class $rs failed - are you sure this is a real Result Class?"
    );
  }
}

sub load_namespaces {
  my ($class, %args) = @_;

  my $result_namespace = delete $args{result_namespace} || 'Result';
  my $resultset_namespace = delete $args{resultset_namespace} || 'ResultSet';
  my $default_resultset_class = delete $args{default_resultset_class};

  $class->throw_exception('load_namespaces: unknown option(s): '
    . join(q{,}, map { qq{'$_'} } keys %args))
      if scalar keys %args;

  $default_resultset_class
    = $class->_expand_relative_name($default_resultset_class);

  for my $arg ($result_namespace, $resultset_namespace) {
    $arg = [ $arg ] if !ref($arg) && $arg;

    $class->throw_exception('load_namespaces: namespace arguments must be '
      . 'a simple string or an arrayref')
        if ref($arg) ne 'ARRAY';

    $_ = $class->_expand_relative_name($_) for (@$arg);
  }

  my %results = $class->_map_namespaces(@$result_namespace);
  my %resultsets = $class->_map_namespaces(@$resultset_namespace);

  my @to_register;
  {
    no warnings 'redefine';
    local *Class::C3::reinitialize = sub { };
    use warnings 'redefine';

    # ensure classes are loaded and attached in inheritance order
    $class->ensure_class_loaded($_) foreach(values %results);
    my %inh_idx;
    my @subclass_last = sort {

      ($inh_idx{$a} ||=
        scalar @{mro::get_linear_isa( $results{$a} )}
      )

          <=>

      ($inh_idx{$b} ||=
        scalar @{mro::get_linear_isa( $results{$b} )}
      )

    } keys(%results);

    foreach my $result (@subclass_last) {
      my $result_class = $results{$result};

      my $rs_class = delete $resultsets{$result};
      my $rs_set = $class->_ns_get_rsrc_instance ($result_class)->resultset_class;

      if($rs_set && $rs_set ne 'DBIx::Class::ResultSet') {
        if($rs_class && $rs_class ne $rs_set) {
          carp "We found ResultSet class '$rs_class' for '$result', but it seems "
             . "that you had already set '$result' to use '$rs_set' instead";
        }
      }
      elsif($rs_class ||= $default_resultset_class) {
        $class->ensure_class_loaded($rs_class);
        $class->_ns_get_rsrc_instance ($result_class)->resultset_class($rs_class);
      }

      my $source_name = $class->_ns_get_rsrc_instance ($result_class)->source_name || $result;

      push(@to_register, [ $source_name, $result_class ]);
    }
  }

  foreach (sort keys %resultsets) {
    carp "load_namespaces found ResultSet class $_ with no "
      . 'corresponding Result class';
  }

  Class::C3->reinitialize;
  $class->register_class(@$_) for (@to_register);

  return;
}

#line 332

sub load_classes {
  my ($class, @params) = @_;

  my %comps_for;

  if (@params) {
    foreach my $param (@params) {
      if (ref $param eq 'ARRAY') {
        # filter out commented entries
        my @modules = grep { $_ !~ /^#/ } @$param;

        push (@{$comps_for{$class}}, @modules);
      }
      elsif (ref $param eq 'HASH') {
        # more than one namespace possible
        for my $comp ( keys %$param ) {
          # filter out commented entries
          my @modules = grep { $_ !~ /^#/ } @{$param->{$comp}};

          push (@{$comps_for{$comp}}, @modules);
        }
      }
      else {
        # filter out commented entries
        push (@{$comps_for{$class}}, $param) if $param !~ /^#/;
      }
    }
  } else {
    my @comp = map { substr $_, length "${class}::"  }
                 $class->_findallmod;
    $comps_for{$class} = \@comp;
  }

  my @to_register;
  {
    no warnings qw/redefine/;
    local *Class::C3::reinitialize = sub { };
    foreach my $prefix (keys %comps_for) {
      foreach my $comp (@{$comps_for{$prefix}||[]}) {
        my $comp_class = "${prefix}::${comp}";
        $class->ensure_class_loaded($comp_class);

        my $snsub = $comp_class->can('source_name');
        if(! $snsub ) {
          carp "Failed to load $comp_class. Can't find source_name method. Is $comp_class really a full DBIC result class? Fix it, move it elsewhere, or make your load_classes call more specific.";
          next;
        }
        $comp = $snsub->($comp_class) || $comp;

        push(@to_register, [ $comp, $comp_class ]);
      }
    }
  }
  Class::C3->reinitialize;

  foreach my $to (@to_register) {
    $class->register_class(@$to);
    #  if $class->can('result_source_instance');
  }
}

#line 523

sub connect { shift->clone->connection(@_) }

#line 542

sub resultset {
  my ($self, $moniker) = @_;
  $self->throw_exception('resultset() expects a source name')
    unless defined $moniker;
  return $self->source($moniker)->resultset;
}

#line 563

sub sources { return keys %{shift->source_registrations}; }

#line 582

sub source {
  my ($self, $moniker) = @_;
  my $sreg = $self->source_registrations;
  return $sreg->{$moniker} if exists $sreg->{$moniker};

  # if we got here, they probably passed a full class name
  my $mapped = $self->class_mappings->{$moniker};
  $self->throw_exception("Can't find source for ${moniker}")
    unless $mapped && exists $sreg->{$mapped};
  return $sreg->{$mapped};
}

#line 610

sub class {
  my ($self, $moniker) = @_;
  return $self->source($moniker)->result_class;
}

#line 642

sub txn_do {
  my $self = shift;

  $self->storage or $self->throw_exception
    ('txn_do called on $schema without storage');

  $self->storage->txn_do(@_);
}

#line 658

sub txn_scope_guard {
  my $self = shift;

  $self->storage or $self->throw_exception
    ('txn_scope_guard called on $schema without storage');

  $self->storage->txn_scope_guard(@_);
}

#line 675

sub txn_begin {
  my $self = shift;

  $self->storage or $self->throw_exception
    ('txn_begin called on $schema without storage');

  $self->storage->txn_begin;
}

#line 692

sub txn_commit {
  my $self = shift;

  $self->storage or $self->throw_exception
    ('txn_commit called on $schema without storage');

  $self->storage->txn_commit;
}

#line 709

sub txn_rollback {
  my $self = shift;

  $self->storage or $self->throw_exception
    ('txn_rollback called on $schema without storage');

  $self->storage->txn_rollback;
}

#line 773

sub populate {
  my ($self, $name, $data) = @_;
  if(my $rs = $self->resultset($name)) {
    if(defined wantarray) {
        return $rs->populate($data);
    } else {
        $rs->populate($data);
    }
  } else {
      $self->throw_exception("$name is not a resultset"); 
  }
}

#line 806

sub connection {
  my ($self, @info) = @_;
  return $self if !@info && $self->storage;

  my ($storage_class, $args) = ref $self->storage_type ? 
    ($self->_normalize_storage_type($self->storage_type),{}) : ($self->storage_type, {});

  $storage_class = 'DBIx::Class::Storage'.$storage_class
    if $storage_class =~ m/^::/;
  eval { $self->ensure_class_loaded ($storage_class) };
  $self->throw_exception(
    "No arguments to load_classes and couldn't load ${storage_class} ($@)"
  ) if $@;
  my $storage = $storage_class->new($self=>$args);
  $storage->connect_info(\@info);
  $self->storage($storage);
  return $self;
}

sub _normalize_storage_type {
  my ($self, $storage_type) = @_;
  if(ref $storage_type eq 'ARRAY') {
    return @$storage_type;
  } elsif(ref $storage_type eq 'HASH') {
    return %$storage_type;
  } else {
    $self->throw_exception('Unsupported REFTYPE given: '. ref $storage_type);
  }
}

#line 869

# this might be oversimplified
# sub compose_namespace {
#   my ($self, $target, $base) = @_;

#   my $schema = $self->clone;
#   foreach my $moniker ($schema->sources) {
#     my $source = $schema->source($moniker);
#     my $target_class = "${target}::${moniker}";
#     $self->inject_base(
#       $target_class => $source->result_class, ($base ? $base : ())
#     );
#     $source->result_class($target_class);
#     $target_class->result_source_instance($source)
#       if $target_class->can('result_source_instance');
#     $schema->register_source($moniker, $source);
#   }
#   return $schema;
# }

sub compose_namespace {
  my ($self, $target, $base) = @_;
  my $schema = $self->clone;
  {
    no warnings qw/redefine/;
#    local *Class::C3::reinitialize = sub { };
    foreach my $moniker ($schema->sources) {
      my $source = $schema->source($moniker);
      my $target_class = "${target}::${moniker}";
      $self->inject_base(
        $target_class => $source->result_class, ($base ? $base : ())
      );
      $source->result_class($target_class);
      $target_class->result_source_instance($source)
        if $target_class->can('result_source_instance');
     $schema->register_source($moniker, $source);
    }
  }
#  Class::C3->reinitialize();
  {
    no strict 'refs';
    no warnings 'redefine';
    foreach my $meth (qw/class source resultset/) {
      *{"${target}::${meth}"} =
        sub { shift->schema->$meth(@_) };
    }
  }
  return $schema;
}

sub setup_connection_class {
  my ($class, $target, @info) = @_;
  $class->inject_base($target => 'DBIx::Class::DB');
  #$target->load_components('DB');
  $target->connection(@info);
}

#line 933

sub svp_begin {
  my ($self, $name) = @_;

  $self->storage or $self->throw_exception
    ('svp_begin called on $schema without storage');

  $self->storage->svp_begin($name);
}

#line 950

sub svp_release {
  my ($self, $name) = @_;

  $self->storage or $self->throw_exception
    ('svp_release called on $schema without storage');

  $self->storage->svp_release($name);
}

#line 967

sub svp_rollback {
  my ($self, $name) = @_;

  $self->storage or $self->throw_exception
    ('svp_rollback called on $schema without storage');

  $self->storage->svp_rollback($name);
}

#line 989

sub clone {
  my ($self) = @_;
  my $clone = { (ref $self ? %$self : ()) };
  bless $clone, (ref $self || $self);

  $clone->class_mappings({ %{$clone->class_mappings} });
  $clone->source_registrations({ %{$clone->source_registrations} });
  foreach my $moniker ($self->sources) {
    my $source = $self->source($moniker);
    my $new = $source->new($source);
    # we use extra here as we want to leave the class_mappings as they are
    # but overwrite the source_registrations entry with the new source
    $clone->register_extra_source($moniker => $new);
  }
  $clone->storage->set_schema($clone) if $clone->storage;
  return $clone;
}

#line 1022

sub throw_exception {
  my $self = shift;

  DBIx::Class::Exception->throw($_[0], $self->stacktrace)
    if !$self->exception_action || !$self->exception_action->(@_);
}

#line 1053

sub deploy {
  my ($self, $sqltargs, $dir) = @_;
  $self->throw_exception("Can't deploy without storage") unless $self->storage;
  $self->storage->deploy($self, undef, $sqltargs, $dir);
}

#line 1076

sub deployment_statements {
  my $self = shift;

  $self->throw_exception("Can't generate deployment statements without a storage")
    if not $self->storage;

  $self->storage->deployment_statements($self, @_);
}

#line 1101

sub create_ddl_dir {
  my $self = shift;

  $self->throw_exception("Can't create_ddl_dir without storage") unless $self->storage;
  $self->storage->create_ddl_dir($self, @_);
}

#line 1142

sub ddl_filename {
  my ($self, $type, $version, $dir, $preversion) = @_;

  my $filename = ref($self);
  $filename =~ s/::/-/g;
  $filename = File::Spec->catfile($dir, "$filename-$version-$type.sql");
  $filename =~ s/$version/$preversion-$version/ if($preversion);

  return $filename;
}

#line 1161

sub thaw {
  my ($self, $obj) = @_;
  local $DBIx::Class::ResultSourceHandle::thaw_schema = $self;
  return Storable::thaw($obj);
}

#line 1174

sub freeze {
  return Storable::freeze($_[1]);
}

#line 1185

sub dclone {
  my ($self, $obj) = @_;
  local $DBIx::Class::ResultSourceHandle::thaw_schema = $self;
  return Storable::dclone($obj);
}

#line 1197

sub schema_version {
  my ($self) = @_;
  my $class = ref($self)||$self;

  # does -not- use $schema->VERSION
  # since that varies in results depending on if version.pm is installed, and if
  # so the perl or XS versions. If you want this to change, bug the version.pm
  # author to make vpp and vxs behave the same.

  my $version;
  {
    no strict 'refs';
    $version = ${"${class}::VERSION"};
  }
  return $version;
}


#line 1236

sub register_class {
  my ($self, $moniker, $to_register) = @_;
  $self->register_source($moniker => $to_register->result_source_instance);
}

#line 1256

sub register_source {
  my $self = shift;

  $self->_register_source(@_);
}

#line 1275

sub register_extra_source {
  my $self = shift;

  $self->_register_source(@_, { extra => 1 });
}

sub _register_source {
  my ($self, $moniker, $source, $params) = @_;

  my $orig_source = $source;

  $source = $source->new({ %$source, source_name => $moniker });
  $source->schema($self);
  weaken($source->{schema}) if ref($self);

  my $rs_class = $source->result_class;

  my %reg = %{$self->source_registrations};
  $reg{$moniker} = $source;
  $self->source_registrations(\%reg);

  return if ($params->{extra});
  return unless defined($rs_class) && $rs_class->can('result_source_instance');

  my %map = %{$self->class_mappings};
  if (
    exists $map{$rs_class}
      and
    $map{$rs_class} ne $moniker
      and
    $rs_class->result_source_instance ne $orig_source
  ) {
    carp "$rs_class already has a source, use register_extra_source for additional sources";
  }
  $map{$rs_class} = $moniker;
  $self->class_mappings(\%map);
}

sub _unregister_source {
    my ($self, $moniker) = @_;
    my %reg = %{$self->source_registrations}; 

    my $source = delete $reg{$moniker};
    $self->source_registrations(\%reg);
    if ($source->result_class) {
        my %map = %{$self->class_mappings};
        delete $map{$source->result_class};
        $self->class_mappings(\%map);
    }
}


#line 1361

{
  my $warn;

  sub compose_connection {
    my ($self, $target, @info) = @_;

    carp "compose_connection deprecated as of 0.08000"
      unless ($INC{"DBIx/Class/CDBICompat.pm"} || $warn++);

    my $base = 'DBIx::Class::ResultSetProxy';
    eval "require ${base};";
    $self->throw_exception
      ("No arguments to load_classes and couldn't load ${base} ($@)")
        if $@;

    if ($self eq $target) {
      # Pathological case, largely caused by the docs on early C::M::DBIC::Plain
      foreach my $moniker ($self->sources) {
        my $source = $self->source($moniker);
        my $class = $source->result_class;
        $self->inject_base($class, $base);
        $class->mk_classdata(resultset_instance => $source->resultset);
        $class->mk_classdata(class_resolver => $self);
      }
      $self->connection(@info);
      return $self;
    }

    my $schema = $self->compose_namespace($target, $base);
    {
      no strict 'refs';
      my $name = join '::', $target, 'schema';
      *$name = Sub::Name::subname $name, sub { $schema };
    }

    $schema->connection(@info);
    foreach my $moniker ($schema->sources) {
      my $source = $schema->source($moniker);
      my $class = $source->result_class;
      #warn "$moniker $class $source ".$source->storage;
      $class->mk_classdata(result_source_instance => $source);
      $class->mk_classdata(resultset_instance => $source->resultset);
      $class->mk_classdata(class_resolver => $schema);
    }
    return $schema;
  }
}

1;

#line 1421
