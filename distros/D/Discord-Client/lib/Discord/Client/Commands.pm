package Discord::Client::Commands;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use IO::Async::Loop;
use JSON::PP ();
use Scalar::Util qw(blessed looks_like_number);
use Discord::Client::Error;

our $VERSION = '0.001';
my %OPTION_TYPES = (
    subcommand => 1,
    group => 2,
    string => 3,
    integer => 4,
    boolean => 5,
    user => 6,
    channel => 7,
    role => 8,
    mentionable => 9,
    number => 10,
    attachment => 11
);
my %COMMAND_TYPES = ( slash => 1, chat_input => 1, user => 2, message => 3 );

sub new {
    my ( $class, %args ) = @_;

    # The registry stores declarations locally; construction performs no discovery.
    croak 'Invalid application ID' if defined( $args{application_id} ) && !_id( $args{application_id} );
    return bless {
        loop => $args{loop} // IO::Async::Loop->new,
        rest => $args{rest},
        application_id => $args{application_id},
        commands => {},
        order => [],
        components => {}
    }, $class;
}
sub _id { defined( $_[0] ) && !ref( $_[0] ) && $_[0] =~ /\A\d+\z/ }

sub _name {
    my ($value) = @_;

    # Validate Unicode characters without silently changing the registered spelling.
    return
           defined($value)
        && !ref($value)
        && $value eq lc($value)
        && $value =~ /\A[-_\x{02BC}\p{L}\p{N}\p{sc=Deva}\p{sc=Thai}]{1,32}\z/;
}
sub _description { defined( $_[0] ) && !ref( $_[0] ) && length( $_[0] ) >= 1 && length( $_[0] ) <= 100 }
sub _number { defined( $_[0] ) && !ref( $_[0] ) && looks_like_number( $_[0] ) && abs( $_[0] ) <= 9007199254740992 }
sub _clone { JSON::PP->new->decode( JSON::PP->new->encode( $_[0] ) ) }

sub define {
    my ( $self, $name, %args ) = @_;

    # Validate the complete declaration before mutating the command registry.
    croak 'Command registry is closed' if $self->{closed};
    my $type = $args{type} // 1;
    $type = $COMMAND_TYPES{$type} if !ref($type) && exists $COMMAND_TYPES{$type};
    croak 'Invalid command type' unless defined($type) && !ref($type) && $type =~ /\A[1-3]\z/;
    my $valid_name =
        $type == 1
        ? _name($name)
        : defined($name) && !ref($name) && length($name) >= 1 && length($name) <= 32;
    croak 'Invalid command name' unless $valid_name;
    croak 'Invalid command description' if $type == 1 && !_description( $args{description} );
    croak 'Context menu commands cannot have descriptions or options'
        if $type != 1
        && ( ( defined( $args{description} ) && length( $args{description} ) ) || exists( $args{options} ) );
    croak 'handler must be a code reference' if defined( $args{handler} ) && ref( $args{handler} ) ne 'CODE';

    # Keep executable handlers separate from the JSON sent to Discord.
    my $node = { name => $name, type => 0 + $type, handler => $args{handler} };
    my ( $wire_options, $nodes ) = $self->_options( $args{options} // [], 'root' );
    $node->{options} = $nodes;
    croak 'A command requires a handler or subcommand handlers'
        unless $node->{handler} || _has_handlers($nodes);
    my %wire = ( %args, name => $name, type => 0 + $type );
    delete $wire{handler};
    if ( $type == 1 ) {
        $wire{options} = $wire_options if exists $args{options};
    }
    else {
        delete @wire{qw(description options)};
    }

    # Normalize wire types and validate localized names before taking a snapshot.
    if ( exists( $wire{default_member_permissions} ) && defined( $wire{default_member_permissions} ) ) {
        croak 'Invalid default member permissions' unless _id( $wire{default_member_permissions} );
        $wire{default_member_permissions} = "$wire{default_member_permissions}";
    }
    $wire{nsfw} = $wire{nsfw} ? JSON::PP::true : JSON::PP::false if exists $wire{nsfw};
    _localizations( $wire{name_localizations}, sub { $type == 1 ? _name( $_[0] ) : _description( $_[0] ) }, 32 )
        if exists $wire{name_localizations};
    _localizations( $wire{description_localizations}, \&_description, 100 )
        if exists $wire{description_localizations};
    croak 'Command declaration is not JSON encodable' unless eval {
        $node->{wire} = _clone( \%wire );
        1;
    };

    # Commit a valid declaration atomically, preserving its registration order.
    my $key = $type . ':' . $name;
    unless ( exists $self->{commands}{$key} ) {
        my $count = grep { $self->{commands}{$_}{type} == $type } @{ $self->{order} };
        croak 'Command count exceeds Discord limits' if $count >= ( $type == 1 ? 100 : 15 );
        push @{ $self->{order} }, $key;
    }
    $self->{commands}{$key} = $node;
    return $self;
}

sub _has_handlers {
    my ($nodes) = @_;

    # A parent command can delegate execution to a nested subcommand.
    for my $node (@$nodes) {
        return 1 if $node->{handler} || _has_handlers( $node->{options} // [] );
    }
    return 0;
}

sub _localizations {
    my ( $map, $validator, $max ) = @_;

    # A null localization map is allowed; supplied translations share the base limits.
    return if !defined $map;
    croak 'Invalid command localizations' unless ref($map) eq 'HASH';
    for my $value ( values %$map ) {
        croak 'Invalid localized command value' unless $validator->($value) && length($value) <= $max;
    }
}

sub _options {
    my ( $self, $options, $level ) = @_;
    croak 'Options must be an array with at most 25 entries'
        unless ref($options) eq 'ARRAY' && @$options <= 25;

    # Validate sibling names, required-option order and nesting at each level.
    my ( @wire, @nodes, %names );
    my ( $optional_seen, $has_subcommands );
    for my $option (@$options) {
        croak 'Invalid command option'
            unless ref($option) eq 'HASH'
            && _name( $option->{name} )
            && _description( $option->{description} );
        croak 'Invalid command option' if $names{ $option->{name} };
        $names{ $option->{name} } = 1;

        my %declaration = %$option;
        my $type = _option_type( $declaration{type} );
        $declaration{type} = $type;
        my $node = { name => $declaration{name}, type => $type };
        my $is_subcommand = $type <= 2;
        $has_subcommands //= $is_subcommand;
        croak 'Subcommands cannot be mixed with value options'
            if $is_subcommand != $has_subcommands;
        croak 'Groups contain only subcommands' if $level eq 'group' && $type != 1;
        croak 'Subcommands cannot be nested inside subcommands'
            if $level eq 'subcommand' && $is_subcommand;

        # Subcommands carry child handlers; value options carry wire constraints.
        if ($is_subcommand) {
            $self->_configure_subcommand( \%declaration, $node );
        }
        else {
            croak 'Value options cannot contain options or handlers'
                if exists( $declaration{options} ) || exists( $declaration{handler} );
            if ( $declaration{required} ) {
                croak 'Required options must precede optional options' if $optional_seen;
            }
            else {
                $optional_seen = 1;
            }
            _configure_value_option( \%declaration, $node );
        }

        # Snapshot each validated option so later caller edits cannot change deployment.
        _localizations( $declaration{name_localizations}, \&_name, 32 )
            if exists $declaration{name_localizations};
        _localizations( $declaration{description_localizations}, \&_description, 100 )
            if exists $declaration{description_localizations};
        $node->{wire} = _clone( \%declaration );
        push @wire, $node->{wire};
        push @nodes, $node;
    }
    return ( \@wire, \@nodes );
}

sub _configure_value_option {
    my ( $declaration, $node ) = @_;

    # Normalize scalar flags without adding omitted fields to the wire declaration.
    $declaration->{required} = $declaration->{required} ? JSON::PP::true : JSON::PP::false
        if exists $declaration->{required};

    # Keep suggestions, bounds and resource filters independent of sibling ordering.
    _configure_autocomplete( $declaration, $node ) if exists $declaration->{autocomplete};
    _normalize_choices($declaration) if exists $declaration->{choices};
    _normalize_option_bounds($declaration);
    _normalize_option_filters($declaration);
}

sub _option_type {
    my ($type) = @_;

    # Accept a name or a wire value, then return one numeric representation.
    $type = $OPTION_TYPES{$type}
        if defined($type) && !ref($type) && exists $OPTION_TYPES{$type};
    croak 'Invalid option type'
        unless defined($type) && !ref($type) && $type =~ /\A(?:[1-9]|10|11)\z/;
    return 0 + $type;
}

sub _configure_subcommand {
    my ( $self, $declaration, $node ) = @_;
    my $type = $declaration->{type};

    # Reject value-only settings before descending into the command tree.
    croak 'Subcommands cannot have required, choices or autocomplete fields'
        if exists( $declaration->{required} )
        || exists( $declaration->{choices} )
        || exists( $declaration->{autocomplete} );
    croak 'Groups require at least one subcommand'
        if $type == 2 && ( !ref( $declaration->{options} ) || !@{ $declaration->{options} } );

    # Groups select a subcommand; only executable subcommands may own handlers.
    my $level = $type == 1 ? 'subcommand' : 'group';
    my ( $wire_children, $children ) = $self->_options( $declaration->{options} // [], $level );
    $declaration->{options} = $wire_children;
    $node->{options} = $children;
    croak 'Invalid subcommand handler'
        if defined( $declaration->{handler} ) && ref( $declaration->{handler} ) ne 'CODE';
    croak 'Groups cannot have handlers' if $type == 2 && defined( $declaration->{handler} );
    $node->{handler} = delete $declaration->{handler};
}

sub _configure_autocomplete {
    my ( $declaration, $node ) = @_;
    my $type = $declaration->{type};

    # Only compatible value types may opt into callback-based suggestions.
    croak 'Autocomplete is valid only for string/integer/number options'
        unless $type == 3 || $type == 4 || $type == 10;
    croak 'Autocomplete and choices are mutually exclusive'
        if exists( $declaration->{choices} ) && $declaration->{autocomplete};

    # Retain the callback locally and send only the enabled flag to Discord.
    if ( ref( $declaration->{autocomplete} ) eq 'CODE' ) {
        $node->{autocomplete} = $declaration->{autocomplete};
        $declaration->{autocomplete} = JSON::PP::true;
    }
    elsif ( $declaration->{autocomplete} ) {
        croak 'Enabled autocomplete requires a callback';
    }
    else {
        $declaration->{autocomplete} = JSON::PP::false;
    }
}

sub _valid_numeric_value {
    my ( $type, $value ) = @_;
    return 0 unless _number($value);
    return 1 if $type == 10;
    return $value == int($value) && abs($value) < 9007199254740992;
}

sub _normalize_choices {
    my ($declaration) = @_;
    my $type = $declaration->{type};
    croak 'Choices are invalid for this option type' unless $type == 3 || $type == 4 || $type == 10;
    croak 'Choices must be an array of at most 25 entries'
        unless ref( $declaration->{choices} ) eq 'ARRAY' && @{ $declaration->{choices} } <= 25;

    # Encode every choice according to its option type, regardless of Perl scalar flags.
    my @choices;
    for my $choice ( @{ $declaration->{choices} } ) {
        croak 'Invalid choice'
            unless ref($choice) eq 'HASH'
            && _description( $choice->{name} )
            && defined( $choice->{value} )
            && !ref( $choice->{value} );
        my %wire_choice = %$choice;
        if ( $type == 3 ) {
            croak 'Invalid choice value' if length( $wire_choice{value} ) > 100;
            $wire_choice{value} = "$wire_choice{value}";
        }
        else {
            croak 'Invalid choice value' unless _valid_numeric_value( $type, $wire_choice{value} );
            $wire_choice{value} = 0 + $wire_choice{value};
        }
        push @choices, \%wire_choice;
    }
    $declaration->{choices} = \@choices;
}

sub _normalize_option_bounds {
    my ($declaration) = @_;
    my $type = $declaration->{type};

    # Numeric bounds must match the declared number type and form a valid interval.
    for my $field (qw(min_value max_value)) {
        next unless exists $declaration->{$field};
        croak 'Invalid numeric option bound'
            unless ( $type == 4 || $type == 10 ) && _valid_numeric_value( $type, $declaration->{$field} );
        $declaration->{$field} = 0 + $declaration->{$field};
    }
    croak 'Minimum option value exceeds maximum'
        if exists( $declaration->{min_value} )
        && exists( $declaration->{max_value} )
        && $declaration->{min_value} > $declaration->{max_value};

    # String lengths have separate limits and must not be accepted for numeric options.
    for my $field (qw(min_length max_length)) {
        next unless exists $declaration->{$field};
        my $length = $declaration->{$field};
        croak 'Invalid string length bound'
            unless $type == 3
            && defined($length)
            && !ref($length)
            && $length =~ /\A\d+\z/
            && $length <= 6000
            && ( $field ne 'max_length' || $length > 0 );
        $declaration->{$field} = 0 + $length;
    }
    croak 'Minimum string length exceeds maximum'
        if exists( $declaration->{min_length} )
        && exists( $declaration->{max_length} )
        && $declaration->{min_length} > $declaration->{max_length};
}

sub _normalize_option_filters {
    my ($declaration) = @_;

    # Channel and attachment filters belong only to their corresponding option types.
    if ( exists $declaration->{channel_types} ) {
        croak 'channel_types requires a channel option'
            unless $declaration->{type} == 7 && ref( $declaration->{channel_types} ) eq 'ARRAY';
        croak 'Invalid channel type'
            if grep { !defined($_) || ref($_) || $_ !~ /\A\d+\z/ } @{ $declaration->{channel_types} };
        $declaration->{channel_types} = [ map { 0 + $_ } @{ $declaration->{channel_types} } ];
    }
    if ( exists $declaration->{file_types} ) {
        croak 'file_types requires an attachment option'
            unless $declaration->{type} == 11
            && ref( $declaration->{file_types} ) eq 'ARRAY'
            && @{ $declaration->{file_types} } <= 10;
        croak 'Invalid file type'
            if grep { !defined($_) || ref($_) || $_ !~ /\A(?:image|video|audio|\.[^\s\/\\\x00-\x1f\x7f]+)\z/ }
            @{ $declaration->{file_types} };
    }
}

sub definitions {
    my ($self) = @_;

    # Return detached wire snapshots, never application callbacks.
    my @definitions = map { $self->{commands}{$_}{wire} } @{ $self->{order} };
    return _clone( \@definitions );
}

sub application_id {
    my ( $self, $id ) = @_;

    # Treat an explicit argument as a setter and preserve the ID as a string.
    if ( @_ > 1 ) {
        croak 'Invalid application ID' unless _id($id);
        $self->{application_id} = "$id";
    }
    return $self->{application_id};
}

sub component {
    my ( $self, $id, $handler ) = @_;

    # Validate registration before replacing a handler for this custom ID.
    croak 'Command registry is closed' if $self->{closed};
    croak 'Invalid component ID or handler'
        unless defined($id)
        && !ref($id)
        && length($id) >= 1
        && length($id) <= 100
        && ref($handler) eq 'CODE';
    $self->{components}{$id} = $handler;
    return $self;
}

sub handler_for {
    my ( $self, $context ) = @_;

    # Components and modal submissions dispatch directly by their custom ID.
    return $self->{components}{ $context->custom_id // '' } if $context->type == 3 || $context->type == 5;

    # Walk the selected command path, inheriting a parent fallback handler.
    my $data = $context->raw->{data};
    my $node = $self->{commands}{ ( $data->{type} // 1 ) . ':' . ( $data->{name} // '' ) } or return;
    my $handler = $node->{handler};
    for my $part ( @{ $context->command_path } ) {
        my ($child) = grep { $_->{name} eq $part && $_->{type} <= 2 } @{ $node->{options} // [] };
        return unless $child;
        $node = $child;
        $handler = $node->{handler} // $handler;
    }

    # Autocomplete validates only the focused option; other required values may be absent.
    if ( $context->type == 4 ) {
        my $focused = $context->focused or return;
        my ($option) = grep { $_->{name} eq $focused->{name} } @{ $node->{options} // [] };
        return $option ? $option->{autocomplete} : undef;
    }

    # Normal commands must satisfy the local declaration before application code runs.
    _validate_supplied_options( $node, $context->options );
    return $handler;
}

sub _validate_supplied_options {
    my ( $node, $values ) = @_;

    # Reject unknown values and missing required values as separate input failures.
    my %declared = map { $_->{name} => $_ } @{ $node->{options} // [] };
    for my $name ( keys %$values ) {
        my $option = $declared{$name} or croak 'Unknown interaction option';
        _validate_option_value( $option, $values->{$name} );
    }
    for my $option ( values %declared ) {
        croak 'Missing required interaction option'
            if $option->{wire}{required} && !exists( $values->{ $option->{name} } );
    }
}

sub _validate_option_value {
    my ( $option, $value ) = @_;

    # Check the value type before applying comparisons or length constraints.
    my $type = $option->{type};
    croak 'Invalid interaction option value' unless defined $value;
    if ( $type == 4 || $type == 10 ) {
        croak 'Invalid numeric interaction option' unless _valid_numeric_value( $type, $value );
    }
    elsif ( $type == 5 ) {
        croak 'Invalid boolean interaction option'
            unless JSON::PP::is_bool($value) || ( !ref($value) && $value =~ /\A[01]\z/ );
    }
    elsif ( $type >= 6 && $type != 10 ) {
        croak 'Invalid entity interaction option' unless _id($value);
    }
    elsif ( $type == 3 ) {
        croak 'Invalid string interaction option' if ref($value);
    }

    # Apply declaration bounds and choices after basic type validation.
    my $wire = $option->{wire};
    croak 'Interaction option outside numeric bounds'
        if ( $type == 4 || $type == 10 )
        && (   ( exists( $wire->{min_value} ) && $value < $wire->{min_value} )
            || ( exists( $wire->{max_value} ) && $value > $wire->{max_value} ) );
    croak 'Interaction option outside string bounds'
        if $type == 3
        && (   ( exists( $wire->{min_length} ) && length($value) < $wire->{min_length} )
            || ( exists( $wire->{max_length} ) && length($value) > $wire->{max_length} ) );
    if ( $wire->{choices} ) {
        croak 'Interaction option is not a declared choice'
            unless grep { $_->{value} eq $value } @{ $wire->{choices} };
    }
}

sub _failed {
    my ( $self, $message, $category ) = @_;
    my $error = Discord::Client::Error->new( message => $message, category => $category );
    return $self->{loop}->new_future->fail( $message, $category, $error );
}

sub sync {
    my ( $self, %args ) = @_;

    # Validate explicit deployment scope before taking an immutable declaration snapshot.
    return $self->_failed( 'Command registry is closed', 'shutdown' ) if $self->{closed};
    return $self->_failed( 'Command synchronization requires a REST client', 'state' ) unless $self->{rest};
    return $self->_failed( 'Command synchronization is already running', 'state' ) if $self->{syncing};
    my $scope = $args{scope} // { global => 1 };
    return $self->_failed( 'Invalid command scope', 'request' )
        unless ref($scope) eq 'HASH'
        && (
            ( keys(%$scope) == 1 && _id( $scope->{guild_id} ) )
            || (   keys(%$scope) == 1
                && defined( $scope->{global} )
                && !ref( $scope->{global} )
                && $scope->{global} eq '1' )
        );

    # Track one deployment and propagate cancellation to its current HTTP stage.
    my $future = $self->{loop}->new_future;
    $self->{syncing} = $future;
    my $operation = { future => $future, scope => $scope, definitions => $self->definitions };
    $future->on_cancel(
        sub {
            my $source = $operation->{source};
            $source->cancel if $source && !$source->is_ready;
        }
    );
    $future->on_ready( sub { delete $self->{syncing} } );

    # Discover the application only when its ID is not already known.
    if ( $self->{application_id} ) {
        $self->_send_command_sync($operation);
    }
    else {
        $self->_discover_sync_application($operation);
    }
    return $future;
}

sub _send_command_sync {
    my ( $self, $operation ) = @_;
    my $future = $operation->{future};
    return if $future->is_ready;

    # Bulk replacement affects exactly the requested global or guild scope.
    my $path = '/applications/' . $self->{application_id};
    my $scope = $operation->{scope};
    $path .= '/guilds/' . $scope->{guild_id} if exists $scope->{guild_id};
    $path .= '/commands';

    # Observe transport completion without exposing raw failure details.
    my $source = eval { $self->{rest}->request( 'PUT', $path, json => $operation->{definitions} ) };
    $operation->{source} = $source;
    unless ( blessed($source) && $source->isa('Future') ) {
        $future->fail( $self->_failed( 'Command synchronization transport failed', 'transport' )->failure );
        return;
    }
    $source->on_ready(
        sub {
            return if $future->is_ready;
            if ( $source->is_done ) {
                $future->done( $source->result );
            }
            elsif ( $source->is_failed ) {
                $self->_forward_failure( $future, $source );
            }
            else {
                $future->cancel;
            }
        }
    );
}

sub _discover_sync_application {
    my ( $self, $operation ) = @_;
    my $future = $operation->{future};

    # Resolve the application identity before issuing any command replacement.
    my $discovery = eval { $self->{rest}->request( 'GET', '/oauth2/applications/@me' ) };
    $operation->{source} = $discovery;
    unless ( blessed($discovery) && $discovery->isa('Future') ) {
        $future->fail( $self->_failed( 'Application discovery failed', 'transport' )->failure );
        return;
    }
    $discovery->on_ready(
        sub {
            return if $future->is_ready;
            if ( $discovery->is_done ) {
                my ($application) = $discovery->result;
                unless ( ref($application) eq 'HASH' && _id( $application->{id} ) ) {
                    $future->fail( $self->_failed( 'Invalid application metadata', 'protocol' )->failure );
                    return;
                }
                $self->{application_id} = "$application->{id}";
                $self->_send_command_sync($operation);
            }
            elsif ( $discovery->is_failed ) {
                $self->_forward_failure( $future, $discovery );
            }
            else {
                $future->cancel;
            }
        }
    );
}

sub close {
    my ($self) = @_;

    # Stop deployment and release application closures throughout the declaration tree.
    $self->{closed} = 1;
    $self->{syncing}->cancel if $self->{syncing} && !$self->{syncing}->is_ready;
    _clear_handlers($_) for values %{ $self->{commands} };
    $self->{components} = {};
    return $self->{loop}->new_future->done;
}

sub _clear_handlers {
    my ($node) = @_;
    delete @{$node}{qw(handler autocomplete)};
    _clear_handlers($_) for @{ $node->{options} // [] };
}

sub _forward_failure {
    my ( $self, $future, $source ) = @_;
    my ( undef, $category, $error ) = $source->failure;

    # Preserve structured SDK failures while hiding arbitrary transport exception text.
    if ( blessed($error) && $error->isa('Discord::Client::REST::Error') ) {
        $future->fail( $error->message, $error->category, $error );
    }
    else {
        $future->fail( $self->_failed( 'Command synchronization failed', $category // 'transport' )->failure );
    }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Commands - Command declarations and explicit deployment

=head1 SYNOPSIS

    use Discord::Client::Commands;

    # Create a local registry without network I/O.
    my $commands = Discord::Client::Commands->new;

    # Declare /greet with one required argument.
    $commands->define(
        greet => (
            description => 'Greet someone',
            options => [
                {name => 'name', type => 'string', description => 'Name', required => 1},
            ],
            handler => sub {
                my ($interaction) = @_;
                return $interaction->reply({
                    content => 'Hello, '.$interaction->option('name'),
                    allowed_mentions => {parse => []},
                });
            },
        ),
    );

=head1 DESCRIPTION

Stores local command declarations and handlers. L<Discord::Client/command>
delegates to this registry. Declaration makes no request; C<sync> explicitly
deploys commands. Startup never deploys commands.

=head1 METHODS

=head2 new

C<new(loop =E<gt> $loop, rest =E<gt> $rest, application_id =E<gt> $id)>
returns a registry. All arguments are optional. Without C<loop>, one is created.
Deployment needs a Bot-authorized REST client.

=head2 define

C<define(name, description =E<gt> ..., options =E<gt> [...], handler =E<gt> CODE)>
declares a slash command and returns the registry. Handlers receive an
L<Discord::Client::Interaction>; return their response Future and reply or
defer explicitly. Invalid declarations throw before changing the registry.
Validation covers names, descriptions, types, unique option names, nesting,
choices and bounds.
Required options must precede optional ones. Slash names use Discord's
L<Unicode/lowercase rules|https://docs.discord.com/developers/interactions/application-commands>.

Option types are C<subcommand>, C<group>, C<string>, C<integer>, C<boolean>, C<user>,
C<channel>, C<role>, C<mentionable>, C<number> and C<attachment>; numeric values 1–11
are accepted. Subcommands can have their own handler or use the root handler.
Groups contain subcommands and have no handler. Do not mix value options and
subcommands at one level.

C<type =E<gt> 'user'> or C<'message'> declares a context-menu command without a
description or options. Its name may contain spaces and mixed case.
JSON fields for localization, contexts, installation and permissions are
preserved. Permission bit sets are sent as strings.

=head2 definitions

Returns a copied JSON-ready arrayref without callbacks.

=head2 application_id

Returns the configured application ID. C<application_id(id)> sets it and
returns the ID; invalid IDs throw.

=head2 component

C<component(custom_id =E<gt> CODE)> registers a button, select menu or modal
handler and returns the registry. The handler receives an Interaction.

=head2 handler_for

C<handler_for($interaction)> returns the selected callback or undef if absent.
It validates invocation options and may throw for invalid arguments.

=head2 sync

    # Replace this application's commands in one server.
    my $deployment = $bot->commands->sync(scope => {guild_id => $guild_id});
    $bot->loop->await($deployment);
    $deployment->get;

Use C<scope =E<gt> {global =E<gt> 1}> for global deployment; this is also the default.
C<sync> bulk-replaces slash and context-menu commands in the selected scope.
Commands absent from the local declarations are removed.

C<sync> returns a Future. Concurrent sync calls fail with C<state>; cancellation
propagates to REST. The application ID comes from construction, READY or REST
discovery. Deployment needs a Bot-authorized REST client.

To deploy an example's declarations without starting its Gateway:

    perl examples/sync-commands.pl examples/ping.pl
    perl examples/ping.pl

Set C<DISCORD_BOT_TOKEN> and C<TEST_GUILD_ID>. The script deploys only to that
server. Examples return their client when loaded and run only when executed
directly. Use L<the example list|Discord::Client> to choose another command set.

=head2 close

Cancels an active synchronization and clears handlers. Returns a completed
Future. An injected REST client remains caller-owned.

=head1 AUTOCOMPLETE

Set C<autocomplete =E<gt> CODE> on a string, integer or number option. Return a choice
array such as C<[{name =E<gt> 'Perl', value =E<gt> 'perl'}]>, a Future yielding that array,
or call C<$interaction-E<gt>autocomplete> explicitly. Do not combine autocomplete
with fixed choices. Invocation options are checked against the declaration;
autocomplete permits partial input.

=head1 LICENSE

Apache License 2.0.

=cut
