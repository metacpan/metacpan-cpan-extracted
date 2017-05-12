use 5.008001;
use utf8;
use strict;
use warnings;

use Locale::KeyedText::Message 2.001000;

###########################################################################
###########################################################################

{ package Locale::KeyedText::Translator; # class
    BEGIN {
        our $VERSION = '2.001000';
        $VERSION = eval $VERSION;
    }

    use Scalar::Util 'blessed';

    # has _set_names
        # isa ArrayRef
            # One elem per set name:
                # elem is Str
        # default []
        # List of Template module Set Names to search.
    sub _set_names {
        my $self = shift;
        $self->{_set_names} = $_[0] if scalar @_;
        return $self->{_set_names};
    }

    # has _member_names
        # isa ArrayRef
            # One elem per member name:
                # elem is Str
        # default []
        # List of Template module Member Names to search.
    sub _member_names {
        my $self = shift;
        $self->{_member_names} = $_[0] if scalar @_;
        return $self->{_member_names};
    }

###########################################################################

sub new {
    my ($class, @args) = @_;
    $class = (blessed $class) || $class;

    my $params = $class->BUILDARGS( @args );

    my $self = bless {}, $class;

    # Set attribute default values.
    $self->_set_names( [] );
    $self->_member_names( [] );

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
    my ($set_names_ref, $member_names_ref)
        = @{$args}{'set_names', 'member_names'};

    if (ref $set_names_ref ne 'ARRAY') {
        $set_names_ref = [$set_names_ref];
    }
    if (ref $member_names_ref ne 'ARRAY') {
        $member_names_ref = [$member_names_ref];
    }

    $self->_assert_arg_ary( 'new', ':@set_names!', $set_names_ref );
    $self->_assert_arg_ary( 'new', ':@member_names!', $member_names_ref );

    $self->_set_names( [@{$set_names_ref}] );
    $self->_member_names( [@{$member_names_ref}] );

    return;
}

###########################################################################

sub export_as_hash {
    my ($self) = @_;
    return {
        'set_names'    => [@{$self->_set_names()}],
        'member_names' => [@{$self->_member_names()}],
    };
}

###########################################################################

sub get_set_names {
    my ($self) = @_;
    return [@{$self->_set_names()}];
}

sub get_member_names {
    my ($self) = @_;
    return [@{$self->_member_names()}];
}

###########################################################################

sub as_debug_string {
    my ($self) = @_;
    my $set_names = $self->_set_names();
    my $member_names = $self->_member_names();
    return '  Debug String of a Locale::KeyedText::Translator object:'
         . "\n"
         . '    @set_names: ["' . (join q{", "}, @{$set_names}) . '"]'
         . "\n"
         . '    @member_names: ["'
             . (join q{", "}, @{$member_names}) . '"]'
         . "\n";
}

use overload (
    '""' => \&as_debug_string,
    fallback => 1,
);

sub as_debug_str {
    my ($self) = @_;
    my $set_names = $self->_set_names();
    my $member_names = $self->_member_names();
    return 'SETS: ' . (join ', ', @{$set_names}) . '; '
         . 'MEMBERS: ' . (join ', ', @{$member_names});
}

###########################################################################

sub get_set_member_combinations {
    my ($self) = @_;
    my @combinations = ();
    for my $member_name (@{$self->_member_names()}) {
        for my $set_name (@{$self->_set_names()}) {
            push @combinations, $set_name . $member_name;
        }
    }
    return \@combinations;
}

###########################################################################

sub translate_message {
    my ($self, $message) = @_;

    $self->_assert_arg_msg( 'translate_message', '$message!', $message );

    my $text = undef;
    SET_MEMBER:
    for my $module_name (@{$self->get_set_member_combinations()}) {
        # Determine if requested template module is already loaded.
        # It may have been embedded in a core program file and hence
        # should never be loaded by translate_message().
        my $module_is_loaded
            = $self->template_module_is_loaded( $module_name );

        # Try to load an external Perl template module; on a require
        # failure, we assume that module intentionally doesn't exist,
        # and so skip to the next candidate module name.
        if (!$module_is_loaded) {
            eval {
                $self->load_template_module( $module_name );
            };
            next SET_MEMBER
                if $@;
        }

        # Try to fetch template text for the given message key from the
        # successfully loaded template module; on a function call
        # death, assume module is damaged and say so; an undefined
        # ret val means module doesn't define key, skip to next module.
        $text = $self->get_template_text_from_loaded_module( $module_name,
            $message->get_msg_key() ); # let escape any thrown exception
        next SET_MEMBER
            if !defined $text;

        # We successfully got template text for the message key, so
        # interpolate the message vars into it and return that.
        $text = $self->interpolate_vars_into_template_text(
            $text, $message->get_msg_vars() );
        last SET_MEMBER;
    }

    return $text;
}

###########################################################################

sub template_module_is_loaded {
    my ($self, $module_name) = @_;
    $self->_assert_arg_str( 'template_module_is_loaded',
        '$module_name!', $module_name );
    no strict 'refs';
    return scalar keys %{$module_name . '::'};
}

sub load_template_module {
    my ($self, $module_name) = @_;

    $self->_assert_arg_str( 'load_template_module',
        '$module_name!', $module_name );

    # Note: We have to invoke this 'require' in an eval string
    # because we need the bareword semantics, where 'require'
    # will munge the package name into file system paths.
    eval "require $module_name;";
    $self->_die_with_msg( 'LKT_T_FAIL_LOAD_TMPL_MOD',
            { 'METH' => 'load_template_module',
            'TMPL_MOD_NAME' => $module_name, 'REASON' => $@ } )
        if $@;

    return;
}

sub get_template_text_from_loaded_module {
    my ($self, $module_name, $msg_key) = @_;

    $self->_assert_arg_str( 'get_template_text_from_loaded_module',
        '$module_name!', $module_name );
    $self->_assert_arg_str( 'get_template_text_from_loaded_module',
        '$msg_key!', $msg_key );

    # TODO: Use a "can" test to suss out whether a call would work before trying it.

    my $text = undef;
    eval {
        $text = $module_name->get_text_by_key( $msg_key );
    };
    $self->_die_with_msg( 'LKT_T_FAIL_GET_TMPL_TEXT',
            { 'METH' => 'get_template_text_from_loaded_module',
            'TMPL_MOD_NAME' => $module_name, 'REASON' => $@ } )
        if $@;

    return $text;
}

sub interpolate_vars_into_template_text {
    my ($self, $text, $msg_vars_ref) = @_;

    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => 'interpolate_vars_into_template_text',
            'ARG' => '$text!' } )
        if !defined $text;
    $self->_assert_arg_hash( 'interpolate_vars_into_template_text',
        '%msg_vars!', $msg_vars_ref );

    while (my ($var_name, $var_value) = each %{$msg_vars_ref}) {
        my $var_value_as_str
            = defined $var_value ? "$var_value"
            :                      q{}
            ;
        $text =~ s/ \< $var_name \> /$var_value_as_str/xg;
    }

    return $text;
}

###########################################################################

sub _die_with_msg {
    my ($self, $msg_key, $msg_vars_ref) = @_;
    $msg_vars_ref ||= {};
    $msg_vars_ref->{'CLASS'} = 'Locale::KeyedText::Translator';
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

sub _assert_arg_ary {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_ARY',
            { 'METH' => $meth, 'ARG' => $arg, 'VAL' => $val } )
        if ref $val ne 'ARRAY';
    $self->_die_with_msg( 'LKT_ARG_ARY_NO_ELEMS',
            { 'METH' => $meth, 'ARG' => $arg } )
        if @{$val} == 0;
    for my $val_elem (@{$val}) {
        $self->_die_with_msg( 'LKT_ARG_ARY_ELEM_UNDEF',
                { 'METH' => $meth, 'ARG' => $arg } )
            if !defined $val_elem;
        $self->_die_with_msg( 'LKT_ARG_ARY_ELEM_EMP_STR',
                { 'METH' => $meth, 'ARG' => $arg } )
            if $val_elem eq q{};
    }
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

sub _assert_arg_msg {
    my ($self, $meth, $arg, $val) = @_;
    $self->_die_with_msg( 'LKT_ARG_UNDEF',
            { 'METH' => $meth, 'ARG' => $arg } )
        if !defined $val;
    $self->_die_with_msg( 'LKT_ARG_NO_EXP_TYPE', { 'METH' => $meth,
            'ARG' => $arg, 'EXP_TYPE' => 'Locale::KeyedText::Message',
            'VAL' => $val } )
        if !blessed $val or !$val->isa( 'Locale::KeyedText::Message' );
}

###########################################################################

} # class Locale::KeyedText::Translator

###########################################################################
###########################################################################

1;
