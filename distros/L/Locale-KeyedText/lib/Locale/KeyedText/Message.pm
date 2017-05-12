use 5.008001;
use utf8;
use strict;
use warnings;

###########################################################################
###########################################################################

{ package Locale::KeyedText::Message; # class
    BEGIN {
        our $VERSION = '2.001000';
        $VERSION = eval $VERSION;
    }

    use Scalar::Util 'blessed';

    # has _msg_key
        # isa Str
        # default ''
        # The machine-readable key that uniquely ident this message.
    sub _msg_key {
        my $self = shift;
        $self->{_msg_key} = $_[0] if scalar @_;
        return $self->{_msg_key};
    }

    # has _msg_vars
        # isa HashRef
            # One elem per var:
                # hkey is Str - var name
                # hval is Any - current value for var
        # default {}
        # Named variables for messages, if any, go here.
    sub _msg_vars {
        my $self = shift;
        $self->{_msg_vars} = $_[0] if scalar @_;
        return $self->{_msg_vars};
    }

###########################################################################

sub new {
    my ($class, @args) = @_;
    $class = (blessed $class) || $class;

    my $params = $class->BUILDARGS( @args );

    my $self = bless {}, $class;

    # Set attribute default values.
    $self->_msg_key( '' );
    $self->_msg_vars( {} );

    $self->BUILD( $params );

    return $self;
}

###########################################################################

sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args == 1 and ref $args[0] eq 'HASH') {
        # Constructor was called with (possibly zero) named arguments.
        return { %{$args[0]} };
    }
    elsif ((scalar @args % 2) == 0) {
        # Constructor was called with (possibly zero) named arguments.
        return { @args };
    }
    else {
        # Constructor was called with odd number positional arguments.
        $class->_die_with_msg( 'LKT_ARGS_BAD_PSEUDO_NAMED' );
    }
}

###########################################################################

sub BUILD {
    my ($self, $args) = @_;
    my ($msg_key, $msg_vars_ref) = @{$args}{'msg_key', 'msg_vars'};

    if (!defined $msg_vars_ref) {
        $msg_vars_ref = {};
    }

    $self->_assert_arg_str( 'new', ':$msg_key!', $msg_key );
    $self->_assert_arg_hash( 'new', ':%msg_vars?', $msg_vars_ref );

    $self->_msg_key( $msg_key );
    $self->_msg_vars( {%{$msg_vars_ref}} );

    return;
}

###########################################################################

sub export_as_hash {
    my ($self) = @_;
    return {
        'msg_key'  => $self->_msg_key(),
        'msg_vars' => {%{$self->_msg_vars()}},
    };
}

###########################################################################

sub get_msg_key {
    my ($self) = @_;
    return $self->_msg_key();
}

sub get_msg_var {
    my ($self, $var_name) = @_;
    $self->_assert_arg_str( 'get_msg_var', '$var_name!', $var_name );
    return $self->_msg_vars()->{$var_name};
}

sub get_msg_vars {
    my ($self) = @_;
    return {%{$self->_msg_vars()}};
}

###########################################################################

sub as_debug_string {
    my ($self) = @_;
    my $msg_key = $self->_msg_key();
    my $msg_vars = $self->_msg_vars();
    return '  Debug String of a Locale::KeyedText::Message object:'
         . "\n"
         . '    $msg_key: "' . $msg_key . '"'
         . "\n"
         . '    %msg_vars: {' . (join q{, }, map {
               '"' . $_ . '"="' . (defined $msg_vars->{$_}
                   ? $msg_vars->{$_} : q{}) . '"'
           } sort keys %{$msg_vars}) . '}'
         . "\n";
}

use overload (
    '""' => \&as_debug_string,
    fallback => 1,
);

sub as_debug_str {
    my ($self) = @_;
    my $msg_key = $self->_msg_key();
    my $msg_vars = $self->_msg_vars();
    return $msg_key . ': ' . join ', ', map {
            $_ . '='
            . (defined $msg_vars->{$_} ? $msg_vars->{$_} : q{})
        } sort keys %{$msg_vars};
}

###########################################################################

sub _die_with_msg {
    my ($self, $msg_key, $msg_vars_ref) = @_;
    $msg_vars_ref ||= {};
    $msg_vars_ref->{'CLASS'} = 'Locale::KeyedText::Message';
    die Locale::KeyedText::Message->new({
        'msg_key' => $msg_key, 'msg_vars' => $msg_vars_ref });
}

sub _assert_arg_str {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_EMP_STR',
            { 'METH' => $meth, 'ARG' => $arg } )
        if $val eq q{};
}

sub _assert_arg_hash {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_HASH',
            { 'METH' => $meth, 'ARG' => $arg, 'VAL' => $val } )
        if ref $val ne 'HASH';
    $self->_die_with_msg( 'LKT_ARG_HASH_KEY_EMP_STR',
            { 'METH' => $meth, 'ARG' => $arg } )
        if exists $val->{q{}};
}

###########################################################################

} # class Locale::KeyedText::Message

###########################################################################
###########################################################################

1;
