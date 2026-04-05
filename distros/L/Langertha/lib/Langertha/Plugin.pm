package Langertha::Plugin;
# ABSTRACT: Base class for plugins
our $VERSION = '0.308';
use Moose;
use Future::AsyncAwait;


has host => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);


around BUILDARGS => sub {
  my ( $orig, $class, %args ) = @_;
  if ($args{raider} && !$args{host}) {
    $args{host} = delete $args{raider};
  }
  return $class->$orig(%args);
};

sub raider {
  my ( $self ) = @_;
  my $host = $self->host;
  return $host if $host->isa('Langertha::Raider');
  return undef;
}


# --- Hook methods (identity/passthrough defaults) ---

async sub plugin_before_raid {
  my ( $self, $messages ) = @_;
  return $messages;
}

async sub plugin_build_conversation {
  my ( $self, $conversation ) = @_;
  return $conversation;
}

async sub plugin_before_llm_call {
  my ( $self, $conversation, $iteration ) = @_;
  return $conversation;
}

async sub plugin_after_llm_response {
  my ( $self, $data, $iteration ) = @_;
  return $data;
}

async sub plugin_before_tool_call {
  my ( $self, $name, $input ) = @_;
  return ($name, $input);
}

async sub plugin_after_tool_call {
  my ( $self, $name, $input, $result ) = @_;
  return $result;
}

async sub plugin_after_raid {
  my ( $self, $result ) = @_;
  return $result;
}


sub self_tools { [] }


sub provides_events { [] }


sub requires_events { [] }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Plugin - Base class for plugins

=head1 VERSION

version 0.308

=head1 SYNOPSIS

    package Langertha::Plugin::MyPlugin;
    use Moose;
    use Future::AsyncAwait;
    extends 'Langertha::Plugin';

    has my_option => (is => 'ro', default => 42);

    async sub plugin_before_llm_call {
        my ($self, $conversation, $iteration) = @_;
        # ... modify conversation ...
        return $conversation;
    }

    __PACKAGE__->meta->make_immutable;

    # Or with sugar:
    package Langertha::Plugin::MyPlugin;
    use Langertha qw( Plugin );

    has my_option => (is => 'ro', default => 42);

    async sub plugin_before_llm_call { ... }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Base class for Langertha plugins. Plugins are Moose classes that extend
C<Langertha::Plugin> and override hook methods. Plugins can be attached
to any plugin host — L<Langertha::Raider> or an engine class that
consumes L<Langertha::Role::PluginHost>.

Plugins are registered via the C<plugins> attribute on the host:

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => ['Langfuse', 'MyPlugin'],
    );

Short names are resolved first to C<Langertha::Plugin::$name>, then to
C<LangerthaX::Plugin::$name>. Fully qualified names (containing C<::>)
are used as-is.

=head1 HOOK METHODS

Override these in your subclass. All hooks are C<async sub> and form a
pipeline: the host calls each plugin's hook in order, passing the
return value of one as input to the next.

=over 4

=item B<plugin_before_raid>($messages) -> $messages

Transform input messages before the raid starts.

=item B<plugin_build_conversation>($conversation) -> $conversation

Transform the assembled conversation (mission + history + messages).

=item B<plugin_before_llm_call>($conversation, $iteration) -> $conversation

Transform the conversation before each LLM request.

=item B<plugin_after_llm_response>($data, $iteration) -> $data

Inspect or transform the parsed LLM response.

=item B<plugin_before_tool_call>($name, $input) -> ($name, $input) or ()

Inspect or transform before each tool execution. Return an empty list
to skip the tool call.

=item B<plugin_after_tool_call>($name, $input, $result) -> $result

Transform the tool result after execution.

=item B<plugin_after_raid>($result) -> $result

Transform the final L<Langertha::Raider::Result> before return.

=back

=head2 host

Back-reference to the plugin host (L<Langertha::Raider> or engine)
this plugin belongs to. Weakened to avoid circular references.

=head2 raider

Convenience accessor. Returns the host if it is a L<Langertha::Raider>,
C<undef> otherwise.

=head2 self_tools

    sub self_tools {
        return [{
            name        => 'my_tool',
            description => 'Does something useful',
            inputSchema => { type => 'object', properties => { ... } },
            code        => sub { $_[0]->text_result('done') },
        }];
    }

Override to register additional self-tools on the host. Returns an
arrayref of tool definitions in MCP format. Tool codes receive
C<($mcp_tool, $args)>.

=head2 provides_events

    sub provides_events { ['history_saved', 'history_compressed'] }

Override to declare custom events this plugin provides. Other plugins
can hook into these events by implementing C<on_$event_name> methods.
The host validates at instantiation that all required events are
provided.

=head2 requires_events

    sub requires_events { ['history_saved'] }

Override to declare events this plugin depends on. If no loaded plugin
provides a required event, the host dies with a useful error at
instantiation.

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
