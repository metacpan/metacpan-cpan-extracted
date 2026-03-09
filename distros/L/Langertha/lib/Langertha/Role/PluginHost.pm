package Langertha::Role::PluginHost;
# ABSTRACT: Role for objects that host plugins (Raider, Engine)
our $VERSION = '0.305';
use Moose::Role;
use Future::AsyncAwait;
use Log::Any qw( $log );
use Module::Runtime qw( use_module );
use Scalar::Util qw( blessed );


has plugins => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  builder => '_build_plugins',
);


sub _build_plugins {
  my ( $self ) = @_;
  return $self->can('_sugar_plugins') ? $self->_sugar_plugins : [];
}

has _plugin_instances => (
  is      => 'ro',
  isa     => 'ArrayRef',
  lazy    => 1,
  builder => '_build_plugin_instances',
);

has _plugin_args => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

sub _parse_plugin_specs {
  my ( $self ) = @_;
  my @raw = @{$self->plugins};
  my @specs;
  while (@raw) {
    my $item = shift @raw;
    if (ref $item && blessed($item) && $item->isa('Langertha::Plugin')) {
      push @specs, $item;
    } elsif (!ref $item && @raw && ref $raw[0] eq 'HASH') {
      push @specs, [ $item, shift @raw ];
    } elsif (!ref $item) {
      push @specs, $item;
    }
  }
  return @specs;
}

sub _build_plugin_instances {
  my ( $self ) = @_;
  $log->debugf("[%s] Loading %d plugin(s)", ref $self, scalar @{$self->plugins});
  my @instances;
  for my $spec ($self->_parse_plugin_specs) {
    if (ref $spec eq 'ARRAY') {
      my ($name, $args) = @$spec;
      my $class = $self->_resolve_plugin_name($name);
      push @instances, $class->new(%{$self->_plugin_args}, %$args, host => $self);
    } elsif (ref $spec && $spec->isa('Langertha::Plugin')) {
      push @instances, $spec;
    } else {
      my $class = $self->_resolve_plugin_name($spec);
      push @instances, $class->new(%{$self->_plugin_args}, host => $self);
    }
  }
  # Build event registry and validate dependencies
  my %provided;
  for my $plugin (@instances) {
    for my $event (@{$plugin->provides_events}) {
      $provided{$event} = ref $plugin;
    }
  }
  $self->{_event_providers} = \%provided;
  for my $plugin (@instances) {
    for my $event (@{$plugin->requires_events}) {
      next if $provided{$event};
      die "Plugin '" . ref($plugin) . "' requires event '$event' "
        . "but no loaded plugin provides it (via provides_events)";
    }
  }
  return \@instances;
}

sub _resolve_plugin_name {
  my ( $self, $name ) = @_;
  # +FullClass::Name — load directly, skip prefix search
  if ($name =~ s/^\+//) {
    use_module($name);
    return $name;
  }
  if ($name =~ /::/) {
    eval { use_module($name) };
    return $name if $name->isa('Langertha::Plugin');
  }
  for my $prefix ('Langertha::Plugin', 'LangerthaX::Plugin') {
    my $full = "${prefix}::${name}";
    my $ok = eval { use_module($full); 1 };
    return $full if $ok;
  }
  # Check if already loaded (e.g. inline/test classes)
  if ($name->can('new') && $name->isa('Langertha::Plugin')) {
    return $name;
  }
  die "Plugin '$name' not found (tried Langertha::Plugin::$name, LangerthaX::Plugin::$name)";
}

# --- Plugin event system ---

async sub fire_event_f {
  my ( $self, $event_name, @args ) = @_;
  $log->tracef("[%s] Firing event: %s", ref $self, $event_name);
  my $method = "on_${event_name}";
  my @results;
  for my $plugin (@{$self->_plugin_instances}) {
    if ($plugin->can($method)) {
      push @results, await $plugin->$method(@args);
    }
  }
  return @results;
}



# --- Plugin hook dispatch ---

async sub _plugin_pipeline_tool_call {
  my ( $self, $name, $input ) = @_;
  for my $plugin (@{$self->_plugin_instances}) {
    my @result = await $plugin->plugin_before_tool_call($name, $input);
    return () unless @result;
    ( $name, $input ) = @result;
  }
  return ( $name, $input );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::PluginHost - Role for objects that host plugins (Raider, Engine)

=head1 VERSION

version 0.305

=head1 DESCRIPTION

Shared role consumed by L<Langertha::Raider>, L<Langertha::Chat>,
L<Langertha::Embedder>, L<Langertha::ImageGen>, and engine classes to
provide a plugin system with lifecycle management and a custom event bus.

Plugins are instantiated lazily on first use. Each plugin receives the host
as its C<host> attribute. Short names are resolved to
C<Langertha::Plugin::$name> or C<LangerthaX::Plugin::$name>. Prefixing a
name with C<+> bypasses resolution and loads the class directly.

=head2 plugins

    plugins => ['Langfuse']
    plugins => [Langfuse => { trace_name => 'my-trace', auto_flush => 1 }]
    plugins => [$plugin_instance]

ArrayRef of plugin specifications. Each entry may be:

=over 4

=item * A short name string (resolved to C<Langertha::Plugin::$name>)

=item * A short name followed by a HashRef of constructor args

=item * A fully qualified class name (with or without C<+> prefix)

=item * An already-instantiated L<Langertha::Plugin> object

=back

=head2 fire_event_f

    my @results = await $host->fire_event_f('history_saved', $data);

Fires a custom event to all loaded plugins that implement
C<on_$event_name>. Returns a list of all plugin return values.
Plugins declare the events they provide via
L<Langertha::Plugin/provides_events> and the events they require via
L<Langertha::Plugin/requires_events>.

=head1 SEE ALSO

=over

=item * L<Langertha::Plugin> - Base class for all plugins

=item * L<Langertha::Plugin::Langfuse> - Observability plugin

=item * L<Langertha::Chat> - Chat wrapper that consumes this role

=item * L<Langertha::Embedder> - Embedder wrapper that consumes this role

=item * L<Langertha::ImageGen> - Image generation wrapper that consumes this role

=item * L<Langertha::Raider> - Autonomous agent that consumes this role

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
