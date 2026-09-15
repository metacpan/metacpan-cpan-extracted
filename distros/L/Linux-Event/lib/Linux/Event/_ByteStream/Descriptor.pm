package Linux::Event::_ByteStream::Descriptor;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use mro ();

my %FRAMER_DEFINITION;
my %CONSUMER_DEFINITION;
my %CLASS_DESCRIPTOR;
my %CONSTRUCTION_DESCRIPTOR;

my @TUNING_NAME = qw(
    read_size read_budget_bytes read_batch_bytes message_batch_size
    high_watermark low_watermark max_pending_bytes max_buffer
    idle_timeout read_timeout write_timeout
);
my %TUNING_NAME = map { $_ => 1 } @TUNING_NAME;
my @NATIVE_TUNING_NAME = qw(
    read_size read_budget_bytes read_batch_bytes message_batch_size
    high_watermark low_watermark max_pending_bytes max_buffer
);

my @NATIVE_SPEC_FIELD = qw(
    read_size read_budget_bytes read_batch_bytes message_batch_size
    high_watermark low_watermark max_pending_bytes max_buffer read_mode
    deliver_cb message_cb message_batch_cb drain_cb eof_cb read_error_cb
    write_error_cb output_limit_cb write_empty_cb framing_error_cb delimiter
    include_delimiter max_frame fixed_size prefix_bytes prefix_little
    include_prefix consumer_provider consumer_abi_version
    consumer_ops_address
);
my %NATIVE_SPEC_FIELD = map { $_ => 1 } @NATIVE_SPEC_FIELD;

sub tuning_names () { @TUNING_NAME }
sub native_tuning_names () { @NATIVE_TUNING_NAME }

sub _validate_native_spec ($spec) {
    croak 'native descriptor requires a hash reference'
        if ref($spec) ne 'HASH';
    my @unknown = grep { !$NATIVE_SPEC_FIELD{$_} } keys %$spec;
    croak "unknown ordered-byte descriptor field '$unknown[0]'"
        if @unknown == 1;
    croak 'unknown ordered-byte descriptor fields: '
        . join(', ', sort @unknown) if @unknown;
    for my $field (@NATIVE_SPEC_FIELD) {
        croak "missing ordered-byte descriptor field '$field'"
            if !exists $spec->{$field};
    }

    my %normalized = %$spec;
    $normalized{$_} = $normalized{$_} ? 1 : 0
        for qw(include_delimiter prefix_little include_prefix);
    $normalized{$_} = defined($normalized{$_}) ? 0 + $normalized{$_} : 0
        for qw(
            read_size read_budget_bytes read_batch_bytes message_batch_size
            high_watermark low_watermark max_pending_bytes max_buffer
            read_mode fixed_size prefix_bytes consumer_abi_version
            consumer_ops_address
        );

    return \%normalized;
}

sub declare_framer ($base, $target, $definition) {
    croak 'a framer may be declared only for a Linux::Event ordered-byte subclass'
        if $target eq $base || !$target->isa($base);
    croak "$target already has an ordered-byte descriptor"
        if exists $CLASS_DESCRIPTOR{$target};
    croak "$target already declares a framer"
        if exists $FRAMER_DEFINITION{$target};
    $FRAMER_DEFINITION{$target} = $definition;
    return;
}

sub _framer_for ($class) {
    for my $package (@{ mro::get_linear_isa($class) }) {
        return $FRAMER_DEFINITION{$package}
            if exists $FRAMER_DEFINITION{$package};
    }
    return undef;
}

sub declare_consumer ($base, $target, $definition) {
    croak 'a native consumer may be declared only for a Linux::Event ordered-byte subclass'
        if $target eq $base || !$target->isa($base);
    croak "$target already has an ordered-byte descriptor"
        if exists $CLASS_DESCRIPTOR{$target};
    croak "$target already declares a native consumer"
        if exists $CONSUMER_DEFINITION{$target};
    croak 'native consumer declaration must be a hash reference'
        if ref($definition) ne 'HASH';
    my @unknown = grep {
        $_ ne 'provider' && $_ ne 'abi_version'
            && $_ ne 'operations_address'
    } keys %$definition;
    croak 'native consumer declaration has unknown fields: '
        . join(', ', sort @unknown) if @unknown;
    croak 'native consumer declaration requires provider'
        if !exists($definition->{provider}) || !defined($definition->{provider});
    croak 'native consumer declaration requires a positive integer abi_version'
        if !defined($definition->{abi_version})
        || $definition->{abi_version} !~ /\A[1-9]\d*\z/;
    croak 'native consumer declaration requires a positive operations_address'
        if !defined($definition->{operations_address})
        || $definition->{operations_address} !~ /\A[1-9]\d*\z/;
    $CONSUMER_DEFINITION{$target} = { %$definition };
    return;
}

sub _consumer_for ($class) {
    for my $package (@{ mro::get_linear_isa($class) }) {
        return $CONSUMER_DEFINITION{$package}
            if exists $CONSUMER_DEFINITION{$package};
    }
    return undef;
}

sub _validate_tuning ($target, $option) {
    croak "$target high_watermark must be a non-negative integer"
        if $option->{high_watermark} !~ /\A\d+\z/;
    croak "$target low_watermark must be a non-negative integer"
        if $option->{low_watermark} !~ /\A\d+\z/;
    croak "$target low_watermark must be <= high_watermark"
        if $option->{low_watermark} > $option->{high_watermark};
    croak "$target max_pending_bytes must be a non-negative integer"
        if $option->{max_pending_bytes} !~ /\A\d+\z/;
    croak "$target read_size must be a positive integer"
        if $option->{read_size} !~ /\A\d+\z/ || $option->{read_size} <= 0;
    croak "$target read_budget_bytes must be a non-negative integer"
        if $option->{read_budget_bytes} !~ /\A\d+\z/;
    croak "$target read_batch_bytes must be a non-negative integer"
        if $option->{read_batch_bytes} !~ /\A\d+\z/;
    croak "$target message_batch_size must be a non-negative integer"
        if $option->{message_batch_size} !~ /\A\d+\z/;
    croak "$target max_buffer must be a positive integer"
        if $option->{max_buffer} !~ /\A\d+\z/ || $option->{max_buffer} <= 0;
    for my $name (qw(idle_timeout read_timeout write_timeout)) {
        $option->{$name} = Linux::Event::_ByteStream::_timeout_value(
            $target, $name, $option->{$name},
        );
    }
    return $option;
}

sub merge_tuning ($target, $base, $override) {
    croak "$target tuning must be a hash reference"
        if ref($override) ne 'HASH';
    my @unknown = grep { !$TUNING_NAME{$_} } keys %$override;
    croak "$target tuning has unknown options: "
        . join(', ', sort @unknown) if @unknown;
    my %option = (%$base, %$override);
    _validate_tuning($target, \%option);
    return \%option;
}

sub _stream_tuning_for ($class) {
    my %option = (
        high_watermark     => 1_048_576,
        low_watermark      =>   262_144,
        max_pending_bytes  =>         0,
        read_size          =>    65_536,
        read_budget_bytes  =>         0,
        read_batch_bytes   =>         0,
        message_batch_size =>         0,
        max_buffer         => 8_388_608,
        idle_timeout       =>         0,
        read_timeout       =>         0,
        write_timeout      =>         0,
    );

    if (my $configure = $class->can('stream_tuning')) {
        my @configured = $configure->($class);
        my %configured;
        if (@configured == 1 && ref($configured[0]) eq 'HASH') {
            %configured = %{ $configured[0] };
        } else {
            croak "$class stream_tuning() returned an odd option list"
                if @configured % 2;
            %configured = @configured;
        }
        my @unknown = grep { !$TUNING_NAME{$_} } keys %configured;
        croak "$class stream_tuning() returned unknown options: "
            . join(', ', sort @unknown) if @unknown;
        @option{keys %configured} = values %configured;
    }

    _validate_tuning($class, \%option);
    return \%option;
}

sub validate_modes ($target, $descriptor, $tuning, $callbacks) {
    if (!$descriptor->{framer}) {
        croak "$target message_batch_size is available only to framed ordered-byte classes"
            if $tuning->{message_batch_size};
        croak "$target on_message requires a framed ordered-byte class"
            if $callbacks->{on_message};
        croak "$target on_messages requires a framed ordered-byte class"
            if $callbacks->{on_messages};
        return;
    }

    croak "$target read_batch_bytes is available only to raw ordered-byte classes"
        if $tuning->{read_batch_bytes};
    croak "$target on_data requires a raw ordered-byte class"
        if $callbacks->{on_data};
    if ($descriptor->{consumer}) {
        croak "$target native consumer cannot be combined with message_batch_size"
            if $tuning->{message_batch_size};
        croak "$target on_message cannot be combined with a native consumer"
            if $callbacks->{on_message};
        croak "$target on_messages cannot be combined with a native consumer"
            if $callbacks->{on_messages};
    }
    return;
}

sub effective_input_callback ($descriptor, $tuning, $callbacks = {}) {
    return undef if $descriptor->{consumer};
    if (!$descriptor->{framer}) {
        return exists($callbacks->{on_data})
            ? $callbacks->{on_data} : $descriptor->{callbacks}{on_data};
    }
    my $name = $tuning->{message_batch_size} ? 'on_messages' : 'on_message';
    return exists($callbacks->{$name})
        ? $callbacks->{$name} : $descriptor->{callbacks}{$name};
}

sub _native_for ($option, $callback, $framing, $consumer) {
    return Linux::Event::_ByteStream::Descriptor::Native->new({
        read_size          => $option->{read_size},
        read_budget_bytes  => $option->{read_budget_bytes},
        read_batch_bytes   => $option->{read_batch_bytes},
        message_batch_size => $option->{message_batch_size},
        high_watermark     => $option->{high_watermark},
        low_watermark      => $option->{low_watermark},
        max_pending_bytes  => $option->{max_pending_bytes},
        max_buffer         => $option->{max_buffer},
        read_mode          => $framing->{read_mode},

        deliver_cb       => $callback->{on_data},
        message_cb       => $callback->{on_message},
        message_batch_cb => $callback->{on_messages},
        drain_cb         => $callback->{on_drain}
            ? \&Linux::Event::_ByteStream::_xs_drain : undef,
        eof_cb           => \&Linux::Event::_ByteStream::_xs_read_eof,
        read_error_cb    => \&Linux::Event::_ByteStream::_xs_read_error,
        write_error_cb   => \&Linux::Event::_ByteStream::_xs_write_error,
        output_limit_cb  => \&Linux::Event::_ByteStream::_xs_output_limit,
        write_empty_cb   => \&Linux::Event::_ByteStream::_xs_write_empty,
        framing_error_cb => \&Linux::Event::_ByteStream::_xs_framing_error,

        delimiter         => $framing->{delimiter},
        include_delimiter => $framing->{include_delimiter} // 0,
        max_frame         => $framing->{max_frame},
        fixed_size        => $framing->{fixed_size} // 0,
        prefix_bytes      => $framing->{prefix_bytes} // 0,
        prefix_little     => $framing->{prefix_little} // 0,
        include_prefix    => $framing->{include_prefix} // 0,

        consumer_provider    => $consumer ? $consumer->{provider} : undef,
        consumer_abi_version => $consumer ? $consumer->{abi_version} : 0,
        consumer_ops_address => $consumer
            ? $consumer->{operations_address} : 0,
    });
}

sub for_class ($class) {
    return $CONSTRUCTION_DESCRIPTOR{$class}
        if exists $CONSTRUCTION_DESCRIPTOR{$class};
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};

    croak 'Linux::Event::_ByteStream is a private implementation base; subclass a public ordered-byte leaf'
        if $class eq 'Linux::Event::_ByteStream';
    croak "$class is not a Linux::Event ordered-byte class"
        if !$class->isa('Linux::Event::_ByteStream');

    my $is_stream_socket = $class->isa('Linux::Event::_Socket::Stream');
    if (!$is_stream_socket) {
        croak "$class defines socket_options() but is not a Linux::Event stream-socket class"
            if $class->can('socket_options');
        croak "$class defines configure_socket() but is not a Linux::Event stream-socket class"
            if $class->can('configure_socket');
    }

    my $framer = _framer_for($class);
    my $consumer = _consumer_for($class);
    my $option = _stream_tuning_for($class);
    my %callback = map { $_ => scalar $class->can($_) }
        qw(on_data on_message on_messages on_drain on_eof on_error on_close
           on_ready on_transport_ready);

    if ($framer) {
        croak "$class read_batch_bytes is available only to raw ordered-byte classes"
            if $option->{read_batch_bytes};
        croak "$class cannot define on_data() when it declares a framer"
            if $callback{on_data};
        if ($consumer) {
            croak "$class native consumer cannot be combined with message_batch_size"
                if $option->{message_batch_size};
            croak "$class native consumer cannot be combined with on_message()"
                if $callback{on_message};
            croak "$class native consumer cannot be combined with on_messages()"
                if $callback{on_messages};
        }
    } else {
        croak "$class native consumer requires a framed ordered-byte class"
            if $consumer;
        croak "$class defines on_message() but does not declare a framer"
            if $callback{on_message};
        croak "$class defines on_messages() but does not declare a framer"
            if $callback{on_messages};
        croak "$class message_batch_size is available only to framed ordered-byte classes"
            if $option->{message_batch_size};
    }

    my $framing = $framer ? { %{ $framer->{native} } } : { read_mode => 0 };
    my $native = _native_for($option, \%callback, $framing, $consumer);

    my $descriptor = {
        class     => $class,
        native    => $native,
        options   => $option,
        framing   => $framing,
        framer    => $framer,
        consumer  => $consumer,
        callbacks => \%callback,
    };
    $CLASS_DESCRIPTOR{$class} = $descriptor;
    return $descriptor;
}

sub prepared ($class, $override = {}, $callback_override = {}) {
    croak "$class Listener stream callbacks must be a hash reference"
        if ref($callback_override) ne 'HASH';
    my $base = for_class($class);
    return $base if !%$override && !%$callback_override;
    my $option = merge_tuning(
        "$class Listener stream", $base->{options}, $override,
    );
    my %callback = (%{ $base->{callbacks} }, %$callback_override);
    validate_modes("$class Listener stream", $base, $option, \%callback);
    my $native = _native_for(
        $option, \%callback, $base->{framing}, $base->{consumer},
    );
    return {
        %$base,
        native        => $native,
        options       => $option,
        callbacks     => \%callback,
        prepared_from => $base,
    };
}

sub with_prepared ($class, $descriptor, $constructor, @arg) {
    croak 'internal prepared Stream constructor must be a coderef'
        if ref($constructor) ne 'CODE';
    local $CONSTRUCTION_DESCRIPTOR{$class} = $descriptor;
    return $constructor->($class, @arg);
}

sub clear_cache () {
    %CLASS_DESCRIPTOR = ();
    return;
}

1;
