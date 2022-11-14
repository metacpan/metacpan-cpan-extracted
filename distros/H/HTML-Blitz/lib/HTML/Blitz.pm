package HTML::Blitz;
use HTML::Blitz::pragma;
use HTML::Blitz::Template ();
use HTML::Blitz::RuleSet ();
use HTML::Blitz::SSSelector ();
use HTML::Blitz::SelectorGroup ();
use HTML::Blitz::SelectorType qw(
    ST_FALSE
    ST_TAG_NAME
    ST_ATTR_HAS
    ST_ATTR_EQ
    ST_ATTR_PREFIX
    ST_ATTR_SUFFIX
    ST_ATTR_INFIX
    ST_ATTR_LIST_HAS
    ST_ATTR_LANG_PREFIX
    ST_NTH_CHILD
    ST_NTH_CHILD_OF_TYPE
);
use HTML::Blitz::ActionType qw(
    AT_REMOVE_IF
    AT_REPLACE_INNER
    AT_REPLACE_OUTER
    AT_REPEAT_OUTER

    AT_AS_MODIFY_ATTRS
    AT_AS_REPLACE_ATTRS

    AT_A_REMOVE_ATTR
    AT_A_SET_ATTR
    AT_A_MODIFY_ATTR

    AT_P_VARIABLE
    AT_P_IMMEDIATE
    AT_P_TRANSFORM
    AT_P_FRAGMENT
    AT_P_VARHTML
);
use Carp qw(croak);
use Scalar::Util qw(blessed);
use overload ();

our $VERSION = '0.01';

method new($class: @rules) {
    my $self = bless {
        ruleset => HTML::Blitz::RuleSet->new,
    }, $class;
    if (@rules && ref($rules[0]) eq 'HASH') {
        my %opt = %{shift @rules};
        $self->set_keep_doctype(delete $opt{keep_doctype}) if exists $opt{keep_doctype};
        $self->set_keep_comments_re(delete $opt{keep_comments_re}) if exists $opt{keep_comments_re};
        $self->set_dummy_marker_re(delete $opt{dummy_marker_re}) if exists $opt{dummy_marker_re};
        croak "Invalid HTML::Blitz option name(s): " . join(", ", sort keys %opt)
            if keys %opt;
    }
    $self->add_rules(@rules);
    $self
}

method set_keep_doctype($val) {
    $self->{ruleset}->set_keep_doctype($val);
}

method set_keep_comments_re($keep_comments_re) {
    $self->{ruleset}->set_keep_comments_re($keep_comments_re);
}

method set_dummy_marker_re($dummy_marker_re) {
    $self->{ruleset}->set_dummy_marker_re($dummy_marker_re);
}

fun _css_unescape($str) {
    $str =~ s{
        \\ (?:
            ( [[:xdigit:]]{1,6} ) (?: \r\n | [ \t\r\n\f] )?+
        |
            ( [^\n\r\f[:xdigit:]] )
        )
    }{
        $2 // do {
            my $n = hex $1;
            $n > 0x10_ffff ? "\x{fffd}" : chr $n
        }
    }xegr
}

fun _css_unescape_string($str) {
    if ($str =~ s/\A"//) {
        $str =~ s/"\z// or die "Internal error: unterminated \" string";
    } else {
        $str =~ s/\A'// or die "Internal error: malformed (unquoted) string: $str";
        $str =~ s/'\z// or die "Internal error: unterminated ' string";
    }
    $str =~ s{
        \\ (
            ( [[:xdigit:]]{1,6} ) (?: \r\n | [ \t\r\n\f] )?+
        |
            ( [^\n\r\f[:xdigit:]] )
        |
            ( \r \n?+ | [\n\f] )
        )
    }{
        defined $3 ? '' :
        $2 // do {
            my $n = hex $1;
            $n > 0x10_ffff ? "\x{fffd}" : chr $n
        }
    }xegr
}

my $ws = qr/[ \t\r\n\f]/;
my $nmchar = qr{
    (?:
        [a-zA-Z0-9_\-]
    |
        [^\x00-\x7f]
    |
        \\ [[:xdigit:]]{1,6} (?: \r\n | $ws )?+
    |
        \\ [^\n\r\f[:xdigit:]]
    )
}x;
my $ident = qr{ -?  (?! [0-9\-] ) $nmchar++ }x;
my $string = qr{
    " (?: [^\n\r\f\\"] | \\ (?: \r \n?+ | [^\r[:xdigit:]] | [[:xdigit:]]{1,6} (?: \r\n | $ws )?+ ) | [^\x00-\x7f] )*+ "
|
    ' (?: [^\n\r\f\\'] | \\ (?: \r \n?+ | [^\r[:xdigit:]] | [[:xdigit:]]{1,6} (?: \r\n | $ws )?+ ) | [^\x00-\x7f] )*+ '
}x;

my %attr_op_type = (
    ''  => ST_ATTR_EQ,
    '^' => ST_ATTR_PREFIX,
    '$' => ST_ATTR_SUFFIX,
    '*' => ST_ATTR_INFIX,
    '~' => ST_ATTR_LIST_HAS,
    '|' => ST_ATTR_LANG_PREFIX,
);

fun _try_parse_simple_selector($src_ref, :$allow_tag_name) {
    if ($allow_tag_name && $$src_ref =~ /\G(\*|$ident)/gc) {
        return { type => ST_TAG_NAME, name => _css_unescape($1) };
    }

    if ($$src_ref =~ /\G#($nmchar++)/gc) {
        return { type => ST_ATTR_EQ, attr => 'id', value => _css_unescape($1) };
    }

    if ($$src_ref =~ /\G\.($ident)/gc) {
        return { type => ST_ATTR_LIST_HAS, attr => 'class', value => _css_unescape($1) };
    }

    if (
        $$src_ref =~ m{
            \G
            \[ $ws*+
            ($ident) $ws*+
            (?:
                ( [\^\$\*~\|]?+ ) = $ws*+ (?: ($ident) | ($string) ) $ws*+
            )?+
            \]
        }xgc
    ) {
        my ($attr, $op, $val_ident, $val_string) = ($1, $2, $3, $4);
        $attr =~ tr/A-Z/a-z/;
        if (!defined $op) {
            return { type => ST_ATTR_HAS, attr => $attr };
        }

        my $value = defined($val_ident) ? _css_unescape($val_ident) : _css_unescape_string($val_string);
        if (
            ($op eq '~' && ($value eq '' || $value =~ /$ws/)) ||
            ($op =~ /\A[\^\$*]\z/ && $value eq '')
        ) {
            return { type => ST_FALSE };
        }
        return { type => $attr_op_type{$op}, attr => $attr, value => $value };
    }

    if ($$src_ref =~ /\G:(nth-child|nth-of-type())\(/iaagc) {
        my $pos = $-[0];
        my $name = $1;
        my $type = defined $2 ? ST_NTH_CHILD_OF_TYPE : ST_NTH_CHILD;
        $$src_ref =~ /\G$ws++/gc;
        $$src_ref =~ m{
            \G
            (
                ( [\-+]? [0-9]* ) [Nn] (?: $ws*+ ([\-+]) $ws*+ ([0-9]+) )?+
            |
                [\-+]? [0-9]+
            |
                [Oo][Dd][Dd]
            |
                [Ee][Vv][Ee][Nn]
            )
        }xgc
            or croak "Bad argument to :$name(): " . substr($$src_ref, $pos, 100);
        my ($arg, $num1, $sign, $num2) = ($1, $2, $3, $4);
        $$src_ref =~ /\G$ws++/gc;
        $$src_ref =~ /\G\)/gc
            or croak "Missing ')' after argument to :$name(): " . substr($$src_ref, $pos, 100);

        if (defined $num1) {
            if ($num1 eq '+' || $num1 eq '') {
                $num1 = 1;
            } elsif ($num1 eq '-') {
                $num1 = -1;
            } else {
                $num1 = 0 + $num1;
            }
            if (defined $sign) {
                $num2 = 0 + $num2;
                $num2 = -$num2 if $sign eq '-';
            } else {
                $num2 = 0;
            }
        } elsif (lc($arg) eq 'odd') {
            $num1 = 2;
            $num2 = 1;
        } elsif (lc($arg) eq 'even') {
            $num1 = 2;
            $num2 = 0;
        } else {
            $num1 = 0;
            $num2 = 0 + $arg;
        }
        return { type => $type, a => $num1, b => $num2 };
    }

    if ($$src_ref =~ /\G:first-child(?![^.#:\[\]),>~ \t\r\n\f])/iaagc) {
        return { type => ST_NTH_CHILD, a => 0, b => 1 };
    }

    if ($$src_ref =~ /\G:first-of-type(?![^.#:\[\]),>~ \t\r\n\f])/iaagc) {
        return { type => ST_NTH_CHILD_OF_TYPE, a => 0, b => 1 };
    }

    if ($$src_ref =~ /\G:($ident)/gc) {
        croak "Unsupported pseudo-class :$1";
    }

    undef
}

fun _parse_selector($src) {
    croak "Invalid selector: $src" if ref $src;
    my @sequences;
    my @simples;

    pos($src) = 0;
    $src =~ /\G$ws++/gc;

    while () {
        if ($src =~ /\G:not\(/iaagc) {
            my $pos = $-[0];
            $src =~ /\G$ws++/gc;
            my $simple = _try_parse_simple_selector \$src, allow_tag_name => 1
                or croak "Unparsable selector in argument to ':not()': " . substr($src, $pos, 100);
            $src =~ /\G$ws++/gc;
            $src =~ /\G\)/gc
                or croak "Missing ')' after argument to ':not(': " . substr($src, pos($src), 100);
            $simple->{negated} = 1;
            push @simples, $simple;
        } elsif (defined(my $simple = _try_parse_simple_selector \$src, allow_tag_name => !@simples)) {
            push @simples, $simple;
        } elsif ($src =~ /\G,$ws*+/gc) {
            @simples
                or croak "Selector list before ',' cannot be empty: " . substr($src, $-[0], 100);
            push @sequences, HTML::Blitz::SSSelector->new(@simples);
            @simples = ();
        } else {
            last;
        }
    }

    $src =~ /\G$ws*+\z/
        or croak "Unparsable selector: " . substr($src, pos($src), 100);
    @simples
        or croak @sequences ? "Trailing comma after last selector list" : "Selector cannot be empty";

    push @sequences, HTML::Blitz::SSSelector->new(@simples);

    HTML::Blitz::SelectorGroup->new(@sequences)
}

fun _text($str) {
    +{ type => AT_P_IMMEDIATE, value => '' . $str }
}

fun _varify($throw, $var) {
    $var =~ /\A[^\W\d][\w\-.]*\z/ or $throw->("Invalid variable name '$var'");
    [undef, $var]
}

fun _var($throw, $var) {
    +{ type => AT_P_VARIABLE, value => _varify($throw, $var) }
}

fun _is_callable($val) {
    ref($val) eq 'CODE' ||
    (blessed($val) && overload::Method($val, '&{}'))
}

fun _template($throw, $val) {
    blessed($val) && $val->isa('HTML::Blitz::Template')
        or $throw->("Argument must be an instance of HTML::Blitz::Template: '$val'");
    +{ type => AT_P_FRAGMENT, value => $val->_codegen }
}

fun _dyn_builder($throw, $var) {
    +{ type => AT_P_VARHTML, value => _varify($throw, $var) }
}

my %_nop = (
    type    => AT_REPLACE_INNER,
    attrset => {
        type    => AT_AS_MODIFY_ATTRS,
        content => {},
    }, 
    content => undef,
    repeat  => [],
);

fun _id($x) { $x }

fun _mk_transform_attr($attr, $fn) {
    +{
        %_nop,
        attrset => {
            type    => AT_AS_MODIFY_ATTRS,
            content => {
                $attr => {
                    type  => AT_A_MODIFY_ATTR,
                    param => { type => AT_P_TRANSFORM, static => $fn, dynamic => [] },
                },
            },
        },
    }
}

fun _attr_add_word($throw, $attr, @words) {
    for my $word (@words) {
        $throw->("Argument cannot contain whitespace: '$word'")
            if $word =~ /[ \t\r\n\f]/;
    }
    _mk_transform_attr $attr, fun ($value) {
        my (@list, %seen);
        for my $word (($value // '') =~ /[^ \t\r\n\f]+/g, @words) {
            push @list, $word if !$seen{$word}++;
        }
        join ' ', @list
    }
}

fun _attr_remove_word($throw, $attr, @words) {
    my %banned;
    for my $word (@words) {
        $throw->("Argument cannot contain whitespace: '$word'")
            if $word =~ /[ \t\r\n\f]/;
        $banned{$word} = 1;
    }
    _mk_transform_attr $attr, fun ($value) {
        my @list;
        my $new_value = join ' ', grep !$banned{$_}, ($value // '') =~ /[^ \t\r\n\f]+/g;
        length $new_value ? $new_value : undef
    }
}

my %actions = (
    remove => fun ($throw, @args) {
        $throw->("Expected 0 arguments, got " . @args)
            if @args != 0;
        +{ type => AT_REPLACE_OUTER, param => _text('') }
    },

    remove_inner => fun ($throw, @args) {
        $throw->("Expected 0 arguments, got " . @args)
            if @args != 0;
        +{ %_nop, content => _text('') }
    },

    remove_if => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $var = _varify $throw, $args[0];
        +{ type => AT_REMOVE_IF, cond => [$var], else => undef }
    },

    replace_inner_text => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ %_nop, content => _text($args[0]) }
    },

    replace_inner_var => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ %_nop, content => _var($throw, $args[0]) }
    },

    replace_inner_template => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ %_nop, content => _template($throw, $args[0]) }
    },

    #replace_inner_builder => fun ($throw, @args) {
    #    $throw->("Expected 1 argument, got " . @args)
    #        if @args != 1;
    #    +{ %_nop, content => _builder($throw, $args[0]) }
    #},

    replace_inner_dyn_builder => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ %_nop, content => _dyn_builder($throw, $args[0]) }
    },

    replace_outer_text => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ type => AT_REPLACE_OUTER, param => _text($args[0]) }
    },

    replace_outer_var => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ type => AT_REPLACE_OUTER, param => _var($throw, $args[0]) }
    },

    replace_outer_template => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ type => AT_REPLACE_OUTER, param => _template($throw, $args[0]) }
    },

    #replace_outer_builder => fun ($throw, @args) {
    #    $throw->("Expected 1 argument, got " . @args)
    #        if @args != 1;
    #    +{ type => AT_REPLACE_OUTER, param => _builder($throw, $args[0]) }
    #},

    replace_outer_dyn_builder => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        +{ type => AT_REPLACE_OUTER, param => _dyn_builder($throw, $args[0]) }
    },

    transform_inner_sub => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $fn = $args[0];
        _is_callable $fn
            or $throw->("Argument must be a function");
        +{ %_nop, content => { type => AT_P_TRANSFORM, static => $fn,  dynamic => [] } }
    },

    transform_inner_var => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $var = _varify $throw, $args[0];
        +{ %_nop, content => { type => AT_P_TRANSFORM, static => \&_id,  dynamic => [$var] } }
    },

    transform_outer_sub => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $fn = $args[0];
        _is_callable $fn
            or $throw->("Argument must be a function");
        +{ type => AT_REPLACE_OUTER, param => { type => AT_P_TRANSFORM, static => $fn,  dynamic => [] } }
    },

    transform_outer_var => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $var = _varify $throw, $args[0];
        +{ type => AT_REPLACE_OUTER, param => { type => AT_P_TRANSFORM, static => \&_id,  dynamic => [$var] } }
    },

    remove_attribute => fun ($throw, @args) {
        +{ %_nop, attrset => { type => AT_AS_MODIFY_ATTRS, content => { map +($_ => { type => AT_A_REMOVE_ATTR }), @args } } }
    },

    replace_all_attributes => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $attr = $args[0];
        +{
            %_nop,
            attrset => {
                type    => AT_AS_REPLACE_ATTRS,
                content => {
                    map {
                        my $v = $attr->{$_};
                        ref($v) eq 'ARRAY'
                            or $throw->("Attribute replacement value must be an array reference, not '$v'");
                        @$v == 2
                            or $throw->("Attribute replacement value must have 2 elements, not " . @$v);
                        $_ =>
                            $v->[0] eq 'text' ? _text($v->[1]) :
                            $v->[0] eq 'var' ? _var($throw, $v->[1]) :
                            $throw->("Invalid attribute replacement type (must be 'text' or 'var'): '$v->[0]'")
                    } keys %$attr
                },
            },
        }
    },

    remove_all_attributes => fun ($throw, @args) {
        $throw->("Expected 0 arguments, got " . @args)
            if @args != 0;
        +{ %_nop, attrset => { type => AT_AS_REPLACE_ATTRS, content => {} } }
    },

    set_attribute_text => fun ($throw, @args) {
        $throw->("Expected 1 or 2 arguments, got " . @args)
            if @args < 1 || @args > 2;
        if (@args == 1) {
            ref(my $attr = $args[0]) eq 'HASH'
                or $throw->(ref $args[0] ? "Invalid reference type (must be HASH): $args[0]" : "Missing value for attribute '$args[0]'");
            return +{ %_nop, attrset => { type => AT_AS_MODIFY_ATTRS, content => { map +($_ => { type => AT_A_SET_ATTR, param => _text($attr->{$_}) }), keys %$attr } } };
        }
        +{ %_nop, attrset => { type => AT_AS_MODIFY_ATTRS, content => { $args[0] => { type => AT_A_SET_ATTR, param => _text($args[1]) } } } }
    },

    set_attribute_var => fun ($throw, @args) {
        $throw->("Expected 1 or 2 arguments, got " . @args)
            if @args < 1 || @args > 2;
        if (@args == 1) {
            ref(my $attr = $args[0]) eq 'HASH'
                or $throw->(ref $args[0] ? "Invalid reference type (must be HASH): $args[0]" : "Missing value for attribute '$args[0]'");
            return +{ %_nop, attrset => { type => AT_AS_MODIFY_ATTRS, content => { map +($_ => { type => AT_A_SET_ATTR, param => _var($throw, $attr->{$_}) }), keys %$attr } } };
        }
        +{ %_nop, attrset => { type => AT_AS_MODIFY_ATTRS, content => { $args[0] => { type => AT_A_SET_ATTR, param => _var($throw, $args[1]) } } } }
    },

    set_attributes => fun ($throw, @args) {
        $throw->("Expected 1 argument, got " . @args)
            if @args != 1;
        my $attr = $args[0];
        +{
            %_nop,
            attrset => {
                type    => AT_AS_MODIFY_ATTRS,
                content => {
                    map {
                        my $v = $attr->{$_};
                        ref($v) eq 'ARRAY'
                            or $throw->("Attribute replacement value must be an array reference, not '$v'");
                        @$v == 2
                            or $throw->("Attribute replacement value must have 2 elements, not " . @$v);
                        $_ => {
                            type  => AT_A_SET_ATTR,
                            param =>
                                $v->[0] eq 'text' ? _text($v->[1]) :
                                $v->[0] eq 'var' ? _var($throw, $v->[1]) :
                                $throw->("Invalid attribute replacement type (must be 'text' or 'var'): '$v->[0]'")
                        }
                    } keys %$attr
                },
            },
        }
    },

    transform_attribute_sub => fun ($throw, @args) {
        $throw->("Expected 2 arguments, got " . @args)
            if @args != 2;
        my ($attr, $fn) = @args;
        _is_callable $fn
            or $throw->("Argument must be a function");
        _mk_transform_attr $attr, $fn
    },

    transform_attribute_var => fun ($throw, @args) {
        $throw->("Expected 2 arguments, got " . @args)
            if @args != 2;
        my ($attr, $var) = @args;
        $var = _varify $throw, $var;
        +{
            %_nop,
            attrset => {
                type    => AT_AS_MODIFY_ATTRS,
                content => {
                    $attr => {
                        type  => AT_A_MODIFY_ATTR,
                        param => { type => AT_P_TRANSFORM, static => \&_id, dynamic => [$var] },
                    },
                },
            },
        }
    },

    add_attribute_word => fun ($throw, @args) {
        $throw->("Expected 2 or more arguments, not " . @args)
            if @args < 2;
        _attr_add_word $throw, @args
    },

    remove_attribute_word => fun ($throw, @args) {
        $throw->("Expected 2 or more arguments, not " . @args)
            if @args < 2;
        _attr_remove_word $throw, @args
    },

    add_class => fun ($throw, @args) {
        $throw->("Expected 1 or more arguments, not " . @args)
            if @args < 1;
        _attr_add_word $throw, 'class', @args
    },

    remove_class => fun ($throw, @args) {
        $throw->("Expected 1 or more arguments, not " . @args)
            if @args < 1;
        _attr_remove_word $throw, 'class', @args
    },

    repeat_outer => fun ($throw, @args) {
        $throw->("Expected 1 or more arguments, not " . @args)
            if @args < 1;
        my $var = _varify $throw, shift @args;
        my @inplace;
        if (@args && ref($args[0]) eq 'REF' && ref(${$args[0]}) eq 'ARRAY') {
            my $actions = ${shift @args};
            @inplace = map _parse_action(fun ($err) { $throw->("Root action: $err") }, $_), ref($actions->[0]) ? @$actions : $actions;
        }
        my @rules;
        for my $proto (@args) {
            my ($selector, $actions) = _parse_rule($proto);
            push @rules, [$selector, @$actions]
                if @$actions;
        }
        +{ type => AT_REPEAT_OUTER, var => $var, inplace => \@inplace, nested => \%_nop, rules => \@rules }
    },

    repeat_inner => fun ($throw, @args) {
        $throw->("Expected 1 or more arguments, not " . @args)
            if @args < 1;
        my $var = _varify $throw, shift @args;
        my @rules;
        for my $proto (@args) {
            my ($selector, $actions) = _parse_rule($proto, custom_action => {
                separator => fun ($throw, @args) {
                    $throw->("Expected 0 arguments, got " . @args)
                        if @args != 0;
                    +{ type => AT_REMOVE_IF, else => undef, cond => [[undef, \'iter0']] }
                },
            });
            push @rules, [$selector, @$actions]
                if @$actions;
        }
        +{ %_nop, repeat => [{ var => $var, rules => \@rules }] }
    },
);

fun _parse_action($throw, $action_proto, $custom_action = {}) {
    ref($action_proto) eq 'ARRAY'
        or $throw->("Not an ARRAY reference: '$action_proto'");
    @$action_proto
        or $throw->("Action cannot be empty");
    my ($type, @args) = @$action_proto;
    my $action_fn = $custom_action->{$type} // $actions{$type} // $throw->("Unknown action type '$type'" . ($type eq 'seperator' && $custom_action->{separator} ? " (did you mean 'separator'?)" : ""));
    $action_fn->(fun ($err) { $throw->("'$type': $err"); }, @args)
}

fun _parse_rule($proto, :$custom_action = {}) {
    my ($sel_str, @action_protos) = @$proto;
    my $selector = _parse_selector $sel_str;
    my @actions = map _parse_action(fun ($err) { croak "Invalid action for '$sel_str': $err" }, $_, $custom_action), @action_protos;
    $selector, \@actions
}

method add_rules(@rules) {
    my $ruleset = $self->{ruleset};
    for my $rule (@rules) {
        my ($selector, $actions) = _parse_rule $rule;
        $ruleset->add_rule($selector, @$actions)
            if @$actions;
    }
}

method apply_to_html($name, $html) {
    HTML::Blitz::Template->new(_codegen => $self->{ruleset}->compile($name, $html))
}

method apply_to_file($file) {
    my $html = do {
        open my $fh, '<:encoding(UTF-8)', $file
            or croak "Can't open $file: $!";
        local $/;
        readline $fh
    };
    $self->apply_to_html($file, $html)
}

1
__END__

=head1 NAME

HTML::Blitz - high-performance, selector-based, content-aware HTML template engine

=head1 SYNOPSIS

    use HTML::Blitz ();
    my $blitz = HTML::Blitz->new;

    $blitz->add_rules(@rules);

    my $template = $blitz->apply_to_file("template.html");
    my $html = $template->process($variables);

    my $fn = $template->compile_to_sub;
    my $html = $fn->($variables);

=head1 DESCRIPTION

HTML::Blitz is a high-performance, CSS-selector-based, content-aware template
engine for HTML5. Let's unpack that:

=over

=item *

You want to generate web pages. Those are written in HTML5.

=item *

Your HTML documents are mostly static in nature, but some parts need to be
filled in dynamically (often with data obtained from a database query). This is
where a template engine shines.

(On the other hand, if you prefer to generate your HTML completely dynamically
with ad-hoc code, but you still want to be safe from HTML injection and XSS
vulnerabilities, have a look at L<HTML::Blitz::Builder>.)

=item *

Most template systems are content agnostic: They can be used for pretty much
any format or language as long as it is textual.

HTML::Blitz is different. It is restricted to HTML, but that also means it
understands more about the documents it processes, which eliminates certain
classes of bugs. (For example, HTML::Blitz will never produce mismatched tags
or forget to properly encode HTML entities.)

=item *

The format for HTML::Blitz template files is plain HTML. Instead of embedding
special template directives in the source document (like with most other
template systems), you write a separate piece of Perl code that instructs
HTML::Blitz to fill in or repeat elements of the source document. Those
elements are targeted with CSS selectors.

=item *

Having written the HTML document template and the corresponding processing
rules (consisting of CSS selectors and actions to be applied to matching
elements), you then compile them together into an L<HTML::Blitz::Template>
object. This object provides functions that take a set of input values, insert
them into the document template, and return the finished HTML page.

This latter step is quite fast. See L</PERFORMANCE> for details.

=back

=head2 General flow

In a typical web application, HTML::Blitz is intended to be used in the
following way ("compile on startup"):

=over

=item 1.

When the application starts up, do the following steps:

For each template, create an HTML::Blitz object by calling L</new>.

=item 2.

Tell the object what rules to apply, either by passing them to L</new>, or by
calling L</add_rules> afterwards (or both). This doesn't do much yet; it just
accumulates rules inside the object.

=item 3.

Apply the rules to the source document by calling L</apply_to_file> (if the
source document is stored in a file) or L</apply_to_html> (if you have the
source document in a string). This gives you an L<HTML::Blitz::Template>
object.

=item 4.

Turn the L<HTML::Blitz::Template> object into a function by calling
L<HTML::Blitz::Template/compile_to_sub>. Stash the function away somewhere.

(The previous steps are meant to be performed once, when the application starts
up and initializes.)

=item 5.

When a request comes in, retrieve the corresponding template function from
where you stashed it in step 4, then call it with the set of variables you want
to use to populate the template document. The result is the finished HTML page.

=back

Alternatively, if your application is not persistent (e.g. because it exits
after processing each request, like a CGI script) or if you just don't want to
spend time recompiling each template on startup, you can use a different model
("precompiled") as follows:

=over

=item 1.

In a separate script, run steps 1 to 3 from the list above in advance.

=item 2.

Serialize each template to a string by calling
L<HTML::Blitz::Template/compile_to_string> and store it where you can load it
back later, e.g. in a database or on disk. In the latter case, you can simply
call L<HTML::Blitz::Template/compile_to_file> directly.

=item 3.

Take care to recompile your templates as needed by rerunning steps 1 and 2 each
time the source documents or processing rules change.

=item 4.

In your application, load your template functions by C<eval>'ing the code
stored in step 2. In the case of files, you can simply use L<perlfunc/do EXPR>.
The return value will be a subroutine reference.

=item 5.

Call your template functions as described in step 5 above.

=back

=head2 Processing model

Conceptually, HTML::Blitz operates in two phases: First all selectors are
tested against the source document and their matches recorded. Then, in the
second phase, all matching actions are applied.

Consider the following document fragment:

    <div class="foo"> ... </div>

And these rules:

    [ 'div' => ['remove_all_attributes'] ],
    [ '.foo' => ['replace_inner_text', 'Hello!'] ],

The second rule matches against the C<class> attribute, but the first rule
removes all attributes. However, it doesn't matter in what order you define
these rules: Both selectors are matched first, and then both actions are
applied together. The attribute removal does not prevent the second rule from
matching. The result will always come out as:

    <div>Hello!</div>

In cases where multiple actions apply to the same element, all actions are run,
but their order is unspecified. Consider the following document fragment:

    <div class="foo"> ... </div>

And these rules:

    [ 'div' => ['replace_inner_text', 'A'], ['replace_inner_text', 'B'] ],
    [ '.foo' => ['replace_inner_text', 'B'] ],

All three actions will run and replace the contents of the C<div> element, but
since their order is unspecified, you may end up with any of the following
three results (depending on which action runs last):

    <div class="foo">A</div>

or

    <div class="foo">B</div>

or

    <div class="foo">C</div>


=over 8

B<Implementation details> (results not guaranteed, your mileage may vary, void
where prohibited, not financial advice): The current implementation tries to
maximize an internal metric called "unhelpfulness". Consider the following
document fragment:

    <img class="profile" src="dummy.jpg">

And these actions:

    ['remove_all_attributes'],                                          #1
    ['set_attribute_text', src => 'kitten.jpg'],                        #2
    ['set_attribute_text', alt => "Photo of a sleeping kitten"],        #3
    ['transform_attribute_sub', src => sub { "/media/images/$_[0]" }],  #4

Clearly the most sensible way to arrange these actions is from #1 to #4; first
removing all existing attributes, giving C<< <img> >>, then gradually setting
new attributes, giving C<< <img src="kitten.jpg" alt="Photo of a sleeping kitten"> >>,
and finally transforming them. This would result in:

    <img src="/media/images/kitten.jpg" alt="Photo of a sleeping kitten">

However, that's too helpful.

In order to maximize unhelpfulness, you would apply these actions from #4 back
to #1; first transforming the C<src> attribute, giving
C<< <img class="profile" src="/media/images/dummy.jpg"> >>, then
adding/overwriting other attributes, giving
C<< <img class="profile" src="kitten.jpg" alt="Photo of a sleeping kitten"> >>,
and finally removing all attributes. This would result in:

    <img>

And that's what HTML::Blitz actually does.

=back

=head1 METHODS

=head2 new

    my $blitz = HTML::Blitz->new;
    my $blitz = HTML::Blitz->new(\%options);
    my $blitz = HTML::Blitz->new(@rules);
    my $blitz = HTML::Blitz->new(\%options, @rules);

Creates a new C<HTML::Blitz> object.

You can optionally specify initial options by passing a hash reference as the
first argument. The following keys are supported:

=over

=item keep_doctype

Default: I<true>

By default, C<< <!DOCTYPE html> >> declarations in template files are retained.
If you set this option to a false value, they are removed instead.

=item keep_comments_re

Default: C<qr/\A/>

By default, HTML comments in template files are retained. This option accepts a
regex object (as created by L<C<qr//>|perlfunc/"qr/STRING/">), which is matched
against the contents of all HTML comments. Only those that match the regex are
retained; all others are removed.

For example, to remove all comments except for copyright notices, you could use
the following:

    HTML::Blitz->new({
        keep_comments_re => qr/ \(c\) | \b copyright \b | \N{COPYRIGHT SIGN} /xi,
    })

If you want to invert this functionality, e.g. to remove comments containing
C<DELETEME> and keep everything else, use negative look-ahead:

    HTML::Blitz->new({
        keep_comments_re => qr/\A(?!.*DELETEME)/s,
    })

=item dummy_marker_re

Default: C<qr/\A(?!)/>

Sometimes you might have dummy content or filler text in your templates that is
intended to be replaced by your processing rules (like "Lorem ipsum" or user
details for "Firstname Lastname"). To make sure all such instances are actually
found and replaced by your processing rules, come up with a distinctive piece
of marker text (e.g. I<XXX>), include it in all of your dummy content, and pass
a regex object (as created by L<C<qr//>|perlfunc/"qr/STRING/">) that detects
it. For example:

    HTML::Blitz->new({
        dummy_marker_re => qr/\bXXX\b/,
    })

If any of the attribute values or plain text parts of your source template
match this regex, template processing will stop and an exception will be
thrown.

Note that this only applies to text from the template; strings that are
substituted in by your processing rules are not checked.

The default behavior is to not detect/reject dummy content.

=back

All other arguments are interpreted as processing rules:

    my $blitz = HTML::Blitz->new(@rules);

is just a shorter way to write

    my $blitz = HTML::Blitz->new;
    $blitz->add_rules(@rules);

See L</add_rules>.

=head2 set_keep_doctype

    $blitz->set_keep_doctype(1);
    $blitz->set_keep_doctype(0);

Turns the L</"keep_doctype"> option on/off. See the description of L</new> for
details.

=head2 set_keep_comments_re

    $blitz->set_keep_comments_re( qr/copyright/i );

Sets the L</"keep_comments_re"> option. See the description of L</new> for
details.

=head2 set_dummy_marker_re

    $blitz->set_dummy_marker_re( qr/\bXXX\b/ );

Sets the L</"dummy_marker_re"> option. See the description of L</new> for
details.

=head2 add_rules

    $blitz->add_rules(
        [ 'a.info, a.next' =>
            [ set_attribute_text => 'href', 'https://example.com/' ],
            [ replace_inner_text => "click here" ],
        ],
        [ '#list-container' =>
            [ repeat_inner => 'list',
                [ '.name'  => [ replace_inner_var => 'name' ] ],
                [ '.group' => [ replace_inner_var => 'group' ] ],
                [ 'hr'     => ['separator'] ],
            ],
        ],
    );

The C<add_rules> method adds processing rules to the C<HTML::Blitz> object. It
accepts any number of rules (even 0, but calling it without arguments is a
no-op).

A I<rule> is an array reference whose first element is a selector and whose
remaining elements are processing actions. The actions will be applied to all
HTML elements in the template document that match the selector.

A I<selector> is a CSS selector in the form of a string.

An I<action> is an array reference whose first element is a string that
specifies the type of the action; the remaining elements are arguments.
Different types of actions take different kinds of arguments.

In the current implementation, only a subset of the full CSS selector
specification is supported. In particular, anything involving selector
combinators (i.e. C<S1 S2>, C<< S1 > S2 >>, C<S1 ~ S2>, or C<S1 + S2>) is not
implemented. A supported selector is a comma-separated list of one or more
simple selector sequences. It matches any element matched by any of the
sequences in the list.

A simple selector sequence is a sequence of one or more simple selectors
separated by nothing (not even whitespace). If a universal or type selector is
present, it must come first in the sequence. A sequence matches any element
that is matched by all of the simple selectors in the sequence.

A simple selector is one of the following:

=over

=item universal selector

The universal selector C<*> matches all elements. It is generally redundant and
can be omitted unless it is the only component of a selector sequence.
(Selector sequences cannot be empty.)

=item type selector

A type selector consists of a name. It matches all elements of that name. For
example, a selector of C<form> matches all form elements, C<p> matches all
paragraph elements, etc.

=item attribute presence selector

A selector of the form C<[FOO]> (where C<FOO> is a CSS identifier) matches all
elements that have a C<FOO> attribute.

=item attribute value selector

A selector of the form C<[FOO=BAR]> (where C<BAR> is a CSS identifier or a CSS
string in single or double quotes) matches all elements that have a C<FOO>
attribute whose value is exactly C<BAR>.

=item attribute prefix selector

A selector of the form C<[FOO^=BAR]> (where C<BAR> is a CSS identifier or a CSS
string in single or double quotes) matches all elements that have a C<FOO>
attribute whose value starts with C<BAR>. However, if C<BAR> is the empty
string (i.e. the selector looks like C<[FOO^=""]> or C<FOO^='']>), then it
matches nothing.

=item attribute suffix selector

A selector of the form C<[FOO$=BAR]> (where C<BAR> is a CSS identifier or a CSS
string in single or double quotes) matches all elements that have a C<FOO>
attribute whose value ends with C<BAR>. However, if C<BAR> is the empty
string (i.e. the selector looks like C<[FOO$=""]> or C<FOO$='']>), then it
matches nothing.

=item attribute infix selector

A selector of the form C<[FOO*=BAR]> (where C<BAR> is a CSS identifier or a CSS
string in single or double quotes) matches all elements that have a C<FOO>
attribute whose value contains C<BAR> as a substring. However, if C<BAR> is the
empty string (i.e. the selector looks like C<[FOO*=""]> or C<FOO*='']>), then
it matches nothing.

=item attribute word selector

A selector of the form C<[FOO~=BAR]> (where C<BAR> is a CSS identifier or a CSS
string in single or double quotes) matches all elements that have a C<FOO>
attribute whose value is a list of whitespace-separated words, one of which is
exactly C<BAR>.

=item attribute language prefix selector

A selector of the form C<[FOO|=BAR]> (where C<BAR> is a CSS identifier or a CSS
string in single or double quotes) matches all elements that have a C<FOO>
attribute whose value is either exactly C<BAR> or starts with C<BAR> followed
by a C<-> (minus) character. For example, C<[lang|=en]> would match an
attribute of the form C<lang="en">, but also C<lang="en-us">, C<lang="en-uk">,
C<lang="en-fr">, etc.

=item class selector

A selector of the form C<.FOO> (where C<FOO> is a CSS identifier) matches all
elements whose C<class> attribute contains a list of whitespace-separated
words, one of which is exactly C<FOO>. It is equivalent to C<[class~=FOO]>.

=item identity selector

A selector of the form C<#FOO> (where C<FOO> is a CSS name) matches all
elements whose C<id> attribute is exactly C<FOO>. It is equivalent to
C<[id=FOO]>.

=item I<n>th child selector

A selector of the form C<:nth-child(An+B)> or C<:nth-child(An-B)> (where C<A>
and C<B> are integers) matches all elements that are the I<An+B>th (or
I<An-B>th, respectively) child of their parent element, for any non-negative
integer I<n>. For the purposes of this selector, counting starts at 1.

The full syntax is a bit more complicated: C<A> can be negative; if C<A> is 1,
it can be omitted (i.e. C<1n> can be shortened to just C<n>); if C<A> is 0, the
whole C<An> part can be omitted; if C<B> is 0, the C<+B> (or C<-B>) part can be
omitted unless the C<An> part is also gone; C<n> can also be written C<N>.

In short, all of these are valid arguments to C<:nth-child>:

    3n+1
    3n-2
    -4n+7
    2n
    9
    n-2
    1n-0

In addition, the special keywords C<odd> and C<even> are also accepted.
C<:nth-child(odd)> is equivalent to C<:nth-child(2n+1)> and C<:nth-child(even)>
is equivalent to C<:nth-child(2n)>.

=item I<n>th child of type selector

A selector of the form C<:nth-of-type(An+B)> or C<:nth-of-type(An-B)> (where
C<A> and C<B> are integers) matches all elements that are the I<An+B>th (or
I<An-B>th, respectively) child of their parent element, only counting elements
of the same type, for any non-negative integer I<n>. Counting starts at 1.

It accepts the same argument syntax as the L</"I<n>th child selector">, which
see for details.

For example, C<span:nth-of-type(3)> matches every C<span> element whose list of
preceding sibling contains exactly two elements of type C<span>.

=item first child selector

A selector of the form C<:first-child> matches all elements that have no
preceding sibling elements. It is equivalent to C<:nth-child(1)>.

=item first child of type selector

A selector of the form C<:first-of-type> matches all elements that have no
preceding sibling elements of the same type. It is equivalent to
C<:nth-of-type(1)>.

=item negated selector

A selector of the form C<:not(FOO)> (where C<FOO> is any simple selector
excluding the negated selector itself) matches all elements that are not
matched by C<FOO>.

For example, C<img:not([alt])> matches all C<img> elements without an C<alt>
attribute, and C<:not(*)> matches nothing.

=back

Other selectors or pseudo-classes are not currently implemented.

In the following section, a I<variable name> refers to a string that starts
with a letter or C<_>) (underscore), followed by 0 or more letters, C<_>,
digits, C<.>, or C<->. Template variables identify sections that are filled in
later when the template is expanded (at runtime, so to speak).

The following types of actions are available:

=over

=item C<['remove']>

Removes the matched element. Equivalent to C<['replace_outer_text', '']>.

=item C<['remove_inner']>

Removes the contents of the matched element, leaving it empty. Equivalent to C<['replace_inner_text', '']>.

=item C<['remove_if', VAR]>

Removes the matched element if I<VAR> (a runtime variable) contains a true value.

=item C<['replace_inner_text', STR]>

Replaces the contents of the matched element by the fixed string I<STR>.

=item C<['replace_inner_var', VAR]>

Replaces the contents of the matched element by the value of the runtime
variable I<VAR>, which is interpreted as plain text (and properly HTML
escaped).

=item C<['replace_inner_template', TEMPLATE]>

Replaces the contents of the matched element by I<TEMPLATE>, which must be an
instance of L<HTML::Blitz::Template>. This action lets you include a
sub-template as part of an outer template; all variables of the inner template
become variables of the outer template.

=item C<['replace_inner_dyn_builder', VAR]>

Replaces the contents of the matched element by the value of the runtime
variable I<VAR>, which must be an instance of L<HTML::Blitz::Builder>. This is
the only way to incorporate dynamic HTML in a template (without interpreting
the HTML code as text and escaping everything).

=item C<['replace_outer_text', STR]>

Replaces the matched element (and all of its contents) by the fixed string I<STR>.

=item C<['replace_outer_var', VAR]>

Replaces the matched element (and all of its contents) by the value of the
runtime variable I<VAR>, which is interpreted as plain text (and properly HTML
escaped).

=item C<['replace_outer_template', TEMPLATE]>

Replaces the matched element by I<TEMPLATE>, which must be an instance of
L<HTML::Blitz::Template>. This action lets you include a sub-template as part
of an outer template; all variables of the inner template become variable of
the outer template.

=item C<['replace_outer_dyn_builder', VAR]>

Replaces the matched element by the value of the runtime variable I<VAR>, which
must be an instance of L<HTML::Blitz::Builder>. This is the only way to
incorporate dynamic HTML in a template (without interpreting the HTML code as
text and escaping everything).

=item C<['transform_inner_sub', SUB]>

Collects the text contents of the matched element and all of its descendants in
a string and passes it to I<SUB>, which must be a code reference (or an object
with an overloaded C<&{}> operator). The returned string replaces the previous
contents of the matched element.

It is analogous to C<elem.textContent = SUB(elem.textContent)> in JavaScript.

=item C<['transform_inner_var', VAR]>

Collects the text contents of the matched element and all of its descendants in
a string and passes it to the runtime variable I<VAR>, which must be a code
reference (or an object with an overloaded C<&{}> operator). The returned
string replaces the previous contents of the matched element.

=item C<['transform_outer_sub', SUB]>

Collects the text contents of the matched element and all of its descendants in
a string and passes it to I<SUB>, which must be a code reference (or an object
with an overloaded C<&{}> operator). The returned string replaces the entire
matched element. (Thus, if I<SUB> returns an empty string, it effectively
removes the matched element from the document.)

=item C<['transform_outer_var', VAR]>

Collects the text contents of the matched element and all of its descendants in
a string and passes it to the runtime variable I<VAR>, which must be a code
reference (or an object with an overloaded C<&{}> operator). The returned
string replaces the entire matched element.

=item C<['remove_attribute', ATTR_NAMES]>

Removes all attributes from the matched element whose names are listed in
I<ATTR_NAMES>, which must be a list of strings.

=item C<['remove_all_attributes']>

Removes all attributes from the matched elements.

=item C<['replace_all_attributes', ATTR_HASHREF]>

Removes all attributes from the matched elements and creates new attributes
based on I<ATTR_HASHREF>, which must be a reference to a hash. Its keys are
attribute names; its values are array references with two elements: The first
is either the string C<text>, in which case the second element is the attribute
value as a string, or the string C<var>, in which case the second element is a
variable name and the attribute value is substituted in at runtime.

For example:

    ['replace_all_attributes', {
        class => [text => 'button cta-1'],
        title => [var => 'btn_title'],
    }]

This specifies that the matched element should only have two attributes:
C<class>, with a value of C<button cta-1>, and C<title>, whose final value will
come from the runtime variable C<btn_title>.

=item C<['set_attribute_text', ATTR, STR]>

Creates an attribute named I<ATTR> with a value of I<STR> (a string) in the
matched element. If an attribute of that name already exists, it is replaced.

For example:

    ['set_attribute_text', href => 'https://example.com/']

=item C<['set_attribute_text', HASHREF]>

If you want to set multiple attributes at once, you can this form. The keys of
I<HASHREF> specify the attribute names, and the values specify the attribute
values.

For example:

    ['set_attribute_text', { src => $src, alt => $alt, title => $title }]

    # is equivalent to:
    ['set_attribute_text', src => $src],
    ['set_attribute_text', alt => $alt],
    ['set_attribute_text', title => $title],

=item C<['set_attribute_var', ATTR, VAR]>

Creates an attribute named I<ATTR> whose value comes from I<VAR> (a runtime
variable) in the matched element. If an attribute of that name already exists,
it is replaced.

For example:

    ['set_attribute_var', href => 'target_url']

=item C<['set_attribute_var', HASHREF]>

If you want to set multiple attributes at once, you can this form. The keys of
I<HASHREF> specify the attribute names, and the values specify the names of
runtime variables from which the attribute values will be taken.

For example:

    ['set_attribute_var', { src => 'img_src', alt => 'img_alt', title => 'img_title' }]

    # is equivalent to:
    ['set_attribute_var', src => 'img_src'],
    ['set_attribute_var', alt => 'img_alt'],
    ['set_attribute_var', title => 'img_title'],

=item C<['set_attributes', ATTR_HASHREF]>

Works exactly like L</"C<['replace_all_attributes', ATTR_HASHREF]>">, but
without removing any existing attributes from the matched element.

For example:

    ['set_attributes', {
        class => [text => 'button cta-1'],
        title => [var => 'btn_title'],
    }]

This specifies that the matched element should have two attributes: C<class>,
with a value of C<button cta-1>, and C<title>, whose final value will come from
the runtime variable C<btn_title>. All other attributes remain unchanged.

=item C<['transform_attribute_sub', ATTR, SUB]>

Calls I<SUB>, which must be a code reference (or an object with an overloaded
C<&{}> operator), with the value of the attribute named I<ATTR> in the matched
element. If there is no such attribute, C<undef> is passed instead.

The return value, normally a string, is used as the new value for I<ATTR>.
However, if I<SUB> returns C<undef> instead, the attribute is removed entirely.

=item C<['transform_attribute_var', ATTR, VAR]>

Calls the runtime variable I<VAR>, whose value must be a code reference (or an
object with an overloaded C<&{}> operator), with the value of the attribute
named I<ATTR> in the matched element. If there is no such attribute, C<undef>
is passed instead.

The return value, normally a string, is used as the new value for I<ATTR>.
However, if I<VAR> returns C<undef> instead, the attribute is removed
entirely.

=item C<['add_attribute_word', ATTR, WORDS]>

Takes the attribute named I<ATTR> from the matched element and treats it as a
list of whitespace-separated words. Any words from I<WORDS> (a list of strings)
that are not already present in I<ATTR> will be added to it. If the matched
element has no I<ATTR> attribute, it is treated as an empty list (thus all
I<WORDS> are added).

As a side effect, duplicate words in the original attribute value may be
removed.

=item C<['remove_attribute_word', ATTR, WORDS]>

Takes the attribute named I<ATTR> from the matched element and treats it as a
list of whitespace-separated words. Any words from I<WORDS> (a list of strings)
that are present in I<ATTR> will be removed from it. If the resulting value of
I<ATTR> is empty, the attribute is removed entirely. If the matched element has
no I<ATTR> attribute to begin with, nothing changes.

As a side effect, duplicate words in the original attribute value may be
removed.

=item C<['add_class', WORDS]>

Adds the words in I<WORDS> (a list of strings) to the C<class> attribute of the
matched element (unless they are already present there). Equivalent to
C<['add_attribute_word', 'class', WORDS]>.

=item C<['remove_class', WORDS]>

Removes the words in I<WORDS> (a list of strings) from the C<class> attribute
of the matched element (if they exist there). Equivalent to
C<['remove_attribute_word', 'class', WORDS]>.

=item C<['repeat_outer', VAR, ACTIONS?, RULES]>

Clones the matched element (along with its descendants), once for each element
of the runtime variable I<VAR>, which must contain an array of variable
environments. Each copy of the matched element has I<RULES> (a list of
processing rules) applied to it, with variables looked up in the corresponding
environment taken from I<VAR>.

For example:

    ['repeat_outer', 'things',
        ['.name', ['replace_inner_var', 'name']],
        ['.phone', ['replace_inner_var', 'phone']],
    ]

This specifies that the matched element should be repeated once for each
element of the C<things> variable. In each copy, elements with a class of
C<name> should have their contents replaced by the value of the C<name>
variable in the current environment (i.e. the current element of C<things>),
and elements with a class of C<phone> should have their contents replaced by
the value of the C<phone> variable in the current loop environment.

The optional I<ACTIONS> argument, if present, is a reference to a reference to
an array of actions (yes, that's a reference to a reference). It specifies what
to do with the matched element itself within the context of the repetition.

For example, consider the following rule:

    ['.foo' =>
        ['set_attribute_var', title => 'title'],
        ['replace_inner_var', 'content'],
        ['repeat_outer', 'things',
            ...
        ],
    ]

This says that elements with a class of C<foo> should have their C<title>
attribute set to the value of the string variable C<title> and their text
content replaced by the value of the string variable C<content>, and then be
repeated as directed by the array variable C<things>. While this will clone the
element as many times as there are elements in C<things>, the clones will all
have the same attributes and content.

On the other hand:

    ['.foo' =>
        ['repeat_outer', 'things',
            \[
                ['set_attribute_var', title => 'title'],
                ['replace_inner_var', 'content'],
            ],
            ...
        ],
    ]

With this rule, the C<title> attribute and contents of elements with class
C<foo> are taken from the C<title> and C<content> (sub-)variables inside
C<things>. That is, the variable references C<title> and C<content> are scoped
within the loop. This way each copy of the matched element will be different.

As a special case, if the I<ACTIONS> list only contains one action, the outer
array can be omitted. That is, instead of a reference to an array reference of
actions, you can use a reference to an action:

    ['repeat_outer', 'things',
        \[
            ['replace_inner_var', 'content'],
        ],
        ...
    ]

    # can be simplified to:

    ['repeat_outer', 'things',
        \['replace_inner_var', 'content'],
        ...
    ]

=item C<['repeat_inner', VAR, RULES]>

Clones the descendants of the matched element (but not the element itself),
once for each element of the runtime variable I<VAR>, which must contain an
array of variable environments. Each copy of the descendants has I<RULES>
(a list of processing rules) applied to it, with variables looked up in the
corresponding environment taken from I<VAR>.

This is very similar to L</"C<['repeat_outer', VAR, ACTIONS?, RULES]>">, with
the following differences:

=over

=item 1.

The matched element acts as a list container and is not repeated.

=item 2.

The I<ACTIONS> argument is not supported.

=item 3.

The I<RULES> list may contain the special L</"C<['separator']>"> action, which
is only allowed in the context of C<repeat_inner>.

=back

=item C<['separator']>

This action is only available within a L</"C<['repeat_inner', VAR, RULES]>">
section. It indicates that the matched element is to be removed from the first
copy of the repeated elements. The results are probably not useful unless the
matched element is the first child of the parent whose contents are repeated.

For example, consider the following template code:

    <div id="list">
        <hr class="sep">
        <p class="c1">other stuff</p>
        <p class="c2">more stuff</p>
    </div>

... with this set of rules:

    ['#list' =>
        ['repeat_inner', 'things',
            ['.c1' => [...]],
            ['.c2' => [...]],
            ['.sep' => ['separator']],
        ],
    ]

Since the C<hr> element targeted by the C<separator> action occurs at the
beginning of the section, it acts as a separator: It will not appear in the
first copy of the section, but every following copy will include it. The
result will look Like this:

    <div id="list">
        
        <p class="c1">...</p>
        <p class="c2">...</p>

        <hr class="sep">
        <p class="c1">...</p>
        <p class="c2">...</p>

        <hr class="sep">
        <p class="c1">...</p>
        <p class="c2">...</p>
        ...
    </div>

=back

=head2 apply_to_html

    my $template = $blitz->apply_to_html($name, $html_code);

Applies the processing rules (added in L<the constructor|/new> or via
L</add_rules>) to the specified source document. The first argument is a purely
informational string; it is used to refer to the document in error messages and
the like. The second argument is the HTML code of the source document. The
returned value is an instance of L<HTML::Blitz::Template>, which see.

There are some restrictions on the HTML code you can pass in. This module does
not implement the full HTML specification; in particular, implicit tags of any
kind are not supported. For example, the following fragment is valid HTML:

    <div>
        <p> A
        <p> B
        <p> C
    </div>

But HTML::Blitz requires you to write this instead:

    <div>
        <p> A </p>
        <p> B </p>
        <p> C </p>
    </div>

This is because implicit closing tags are not supported. In fact, HTML::Blitz
thinks C<< <p> A <p> B </p> C </p> >> is valid HTML code containing a C<p> element
nested within another C<p>. (It is not; C<p> elements don't nest and the second
C<< </p> >> tag should be a syntax error. So don't do that.)

Similarly, a real HTML parser would not create C<tr> elements as direct
children of a C<table>:

    <table
        <tr><td>A</td></tr>
    </table>

Here an implicit C<tbody> element is supposed to be inserted instead:

    <table
        <tbody>
            <tr><td>A</td></tr>
        </tbody>
    </table>

HTML::Blitz does not do that. If you have a rule with a C<tbody> selector, it
will only apply to elements explicitly written out in the source document.

In other matters, HTML::Blitz tries to follow HTML parsing rules closely. For
example, it knows about I<void elements> (i.e. elements that have no content),
like C<br>, C<img>, or C<input>. Such elements do not have closing tags:

    <!-- this is a syntax error; you cannot "close" a <br> tag  -->
    <br></br>

It is not generally possible to have a self-closing opening tag:

    <!-- syntax error: -->
    <div />

    <!-- you need to write this instead: -->
    <div></div>

However, a trailing slash in the opening tag is accepted (and ignored) in void
elements. The following are all equivalent:

    <br>
    <br/>
    <br />

Another exception applies to descendants of C<math> and C<svg> elements, which
follow slightly different rules:

    <svg>
        <!-- this is OK; it is parsed as if it were <circle></circle> -->
        <circle/>
    </svg>

    <!-- this is a syntax error: attempt to self-close a non-void tag outside of svg/math -->
    <circle />

The (utterly bonkers) special parsing rules for C<script> elements are
faithfully implemented:

    <!-- OK: -->
    <script> /* <!-- */ </script>

    <!-- OK: -->
    <script> /* <script> <!-- */ </script>

    <!-- still OK (script containing raw "</script>" text): -->
    <script> /* <!-- <script> </script> --> */ </script>

    <!-- still OK: -->
    <script> /* <!-- <script> --> */ </script>

Attributes may contain whitespace around C<=>:

    <img src = "kitten.jpg" alt = "photo of a kitten">

Attribute values don't need to be quoted if they don't contain whitespace or
"special" characters (one of C<< <>="'` >>):

    <img src=kitten.jpg alt="photo of a kitten">
    <img src = kitten.jpg alt = photo&#32;of&#32;a&#32;kitten>

Attributes without values are allowed (and implicitly assigned the empty string as a value):

    <input disabled class>
    <!-- is equivalent to -->
    <input disabled="" class="">

=head2 apply_to_file

    my $template = $blitz->apply_to_file($filename);

A convenience wrapper around L</apply_to_html>. It reads the contents of
C<$filename> (which must be UTF-8 encoded) and calls C<apply_to_html($filename, $contents)>.

=head1 EXAMPLES

The following is a complete program:

    use strict;
    use warnings;
    use HTML::Blitz ();

    my $template_html = <<'EOF';
    <!DOCTYPE html>
    <html>
        <head>
            <title>@@@ Hello, people!</title>
        </head>
        <body>
            <h1 id="greeting">@@@ placeholder heading</h1>
            <div id="list">
                <hr class="between">
                <p>
                    Name: <span class="name">@@@Bob</span> <br>
                    Age: <span class="age">@@@42</span>
                </p>
            </div>
        </body>
    </html>
    EOF

    my $blitz = HTML::Blitz->new({
        # sanity check: die() if any template parts marked '@@@' above are not
        # replaced by processing rules
        dummy_marker_re => qr/\@\@\@/,
    });

    $blitz->add_rules(
        [ 'html'             => ['set_attribute_text', lang => 'en'] ],
        [ 'title, #greeting' => ['replace_inner_var', 'title'] ],
        [ '#list' =>
            [ 'repeat_inner', 'people',
                [ '.between' => ['separator'] ],
                [ '.name'    => ['replace_inner_var', 'name'] ],
                [ '.age'     => ['replace_inner_var', 'age'] ],
            ],
        ],
    );

    my $template = $blitz->apply_to_html('(inline document)', $template_html);
    my $template_fn = $template->compile_to_sub;

    my $data = {
        title  => "Hello, friends, family & other creatures of the sea!",
        people => [
            { name => 'Edward', age => 17 },
            { name => 'Marvin', age => 510_119_077_042 },
            { name => 'Bronze', age => '<redacted>' },
        ],
    };

    my $html = $template_fn->($data);
    print $html;

It produces the following output:

    <!DOCTYPE html>
    <html lang=en>
        <head>
            <title>Hello, friends, family &amp; other creatures of the sea!</title>
        </head>
        <body>
            <h1 id=greeting>Hello, friends, family &amp; other creatures of the sea!</h1>
            <div id=list>
                
                <p>
                    Name: <span class=name>Edward</span> <br>
                    Age: <span class=age>17</span>
                </p>
            
                <hr class=between>
                <p>
                    Name: <span class=name>Marvin</span> <br>
                    Age: <span class=age>510119077042</span>
                </p>
            
                <hr class=between>
                <p>
                    Name: <span class=name>Bronze</span> <br>
                    Age: <span class=age>&lt;redacted></span>
                </p>
            </div>
        </body>
    </html>

=head1 RATIONALE

(I.e. why does this module exist?)

Template systems like L<Template::Toolkit> are both powerful and general. In my
opinion, that's a disadvantage: TT is both too powerful and too stupid for its
own good. Since TT embeds its own programming language that can call arbitrary
methods in Perl, it is possible to write "templates" that send their own
database queries, iterate over resultsets, and do pretty much anything they
want, completely bypassing the notional "controller" or "model" in an
application. On the other hand, since TT knows nothing about the document
structure it is generating (to TT it's all just strings being concatenated),
you have to make sure to manually HTML escape every piece of text. Anything you
overlook may end up being used for HTML injection and XSS exploits.

L<HTML::Zoom> offers an intriguing alternative: Templates are plain HTML
without any special template directives or variables at all. Instead, these
static HTML documents are manipulated through structure-aware selectors and
modification actions. Not only does this eliminate the disadvantages listed
above, it also means you can automatically validate your templates to make sure
they're well-formed HTML, which is basically impossible with TT.

There is only one tiny problem: L<HTML::Zoom> is slow. A template page that
seems fine when fed with 10 or 20 variables during development can suddenly
crawl to a near halt when fed with an unexpectedly large dataset (with hundreds
or thousands of entries) in production.

(In fact, I once had reports of a single page in a big web app taking 50-60
seconds to load, which is clearly unacceptable. At first I tried to optimize
the database queries behind it, but without much success. That's when I
realized that >85% of the time was spent in the L<HTML::Zoom> based view, just
slowly churning through the template, and nothing I changed in the code before
that would significantly improve loading times.)

This module was born from an attempt to retain the general concept behind
L<HTML::Zoom> (which I'm a big fan of) while reimplementing every part of the
API and code with a focus on pure execution speed.

=head1 PERFORMANCE

For benchmarking purposes I set up a simple HTML template and filled it with a
medium-sized dataset consisting of 5 "categories" with 40 "products" each (200
in total). Each "product" had a custom image, description, and other bits of
metadata.

To get a performance baseline, I timed a hand-written piece of Perl code
consisting only of string constants, variables, calls to C<encode_entities>
(from L<HTML::Entities>), concatenation, and nested loops. Everything was
hard-coded; nothing was modularized or factored out into subroutines.

Against this, I timed a few template systems (L<HTML::Blitz>, L<HTML::Zoom>,
L<Template::Toolkit>) as well as L<HTML::Blitz::Builder>, which is rather the
opposite of a template system.

Results:

=over

=item baseline

457/s (0.0022s per iteration), 100% (of baseline performance, the theoretical maximum)

=item HTML::Blitz

392/s (0.0026s per iteration), 85.8%

=item Template::Toolkit

48.0/s (0.0208s per iteration), 10.5%

=item HTML::Blitz::Builder

40.8/s (0.0245s per iteration), 8.9%

=item HTML::Zoom

1.39/s (0.7194s per iteration), 0.3%

=back

Conclusions:

=over

=item *

L<HTML::Zoom> is slooooooow. Using it in anything but the most simple cases has
a noticeable impact on performance.

=item *

HTML::Blitz is orders of magnitude faster. It can easily outperform
L<HTML::Zoom> by a factor of 200 or 300. A dataset that might take HTML::Blitz
20 milliseconds to zip through would lock up L<HTML::Zoom> for over 5 seconds.

=item *

HTML::Blitz is competitive with hand-written code that sacrifices all semblance
of maintainability for speed. In fact, it still runs at 80%-90% of that speed.

=back

=head1 WHY THE NAME

I'm German, and I<Blitz> is the German word for "lightning" or "flash" (or
"thunderbolt"). Because the main motivation behind this module is performance,
I wanted something that represents speed. Something I<lightning-fast>, in fact
(that's I<blitzschnell> in German). I didn't want to use the English name
"Flash" because that name is already taken by the infamous "Flash Player"
browser plugin (even if it is currently dead).

The second reason is also connected to speed: I wanted a template system that
assembles pages as effortlessly and efficiently as copying around blocks of
memory, with minimal additional computation. Something roughly like a
L<bit blit|https://en.wikipedia.org/wiki/Bit_blit> ("bit block transfer")
operation. HTML::Blitz "blits" in the sense that it efficiently transfers
blocks of HTML.

The third reason relates to my frustration with L<HTML::Zoom>'s performance.
When I was struggling with L<HTML::Zoom>, fruitlessly trying to come up with
ways to optimize or work around its code, I remembered a funny coincidence: It
just so happens that (Professor) Zoom is the name of a supervillain in the
superhero comic books published by DC Comics. He is the archenemy of the Flash
("the fastest man alive"), whose main ability is super-speed. When the Flash
comics were published in Germany in the 1970s and 1980s, his name was
translated as I<der Rote Blitz> ("the Red Flash"). Thus: "Blitz" is the hero
that triumphs over "Zoom" through superior speed. :-)

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2022 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU Affero General Public License|https://www.gnu.org/licenses/agpl-3.0.txt>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

=head1 SEE ALSO

L<HTML::Blitz::Template>,
L<HTML::Blitz::Builder>
