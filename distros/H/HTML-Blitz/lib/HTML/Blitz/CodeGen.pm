# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::CodeGen;
use HTML::Blitz::pragma;
use HTML::Blitz::Atom qw(
    OP_RAW
    OP_VAR
    OP_VAR_QQ
    OP_VAR_HTML
    OP_CALL
    OP_CALL_QQ
    OP_MANGLE_ATTR
    OP_LOOP
    OP_COND
);
use Carp qw(croak);

use constant {
    MAX_NESTED_CONCAT => 100,
};

method new($class: :$_scope = 0) {
    bless {
        depth => $_scope,
        code  => [
            { type => OP_RAW, str => '' },
        ],
    }, $class
}

method scope() {
    $self->{depth}
}

method _emit_raw($str) {
    return if $str eq '';
    if ((my $op = $self->{code}[-1])->{type} eq OP_RAW) {
        $op->{str} .= $str;
    } else {
        push @{$self->{code}}, { type => OP_RAW, str => $str };
    }
}

method emit_doctype() {
    $self->_emit_raw('<!DOCTYPE html>');
}

method emit_comment($content) {
    $content =~ /\A(-?>)/
        and croak "HTML comment must not start with '$1': '$content'";
    $content =~ /(<!--|--!?>)/
        and croak "HTML comment must not contain '$1': '$content'";
    $self->_emit_raw("<!--$content-->");
}

method emit_text($text) {
    $text =~ s{([<&])}{ $1 eq '<' ? '&lt;' : '&amp;' }eg;
    $self->_emit_raw($text);
}

method emit_style_text($text) {
    $text =~ m{(</style[\s/>])}aai
        and croak "contents of <style> tag must not contain '$1': '$text'";
    $self->_emit_raw($text);
}

method emit_script_text($text) {
    my $script_content_error = fun ($str) {
        SCRIPT_DATA: {
            $str =~ m{ ( <!-- (?! -?> ) ) | ( </script [ \t\r\n\f/>] ) }xaaigc
                or return undef;
            $1 or return "contents of <script> tag must not contain '$2': '$str'";
            SCRIPT_DATA_ESCAPED: {
                $str =~ m{ (-->) | ( < (/?) script [ \t\r\n\f/>] ) }xaaigc
                    or return undef;
                $1 and redo SCRIPT_DATA;
                $3 and return "contents of <script> tag must not contain '$2': '$str'";

                $str =~ m{ (-->) | </script [ \t\r\n\f/>] }xaaigc
                    or return "missing '-->' or '</script>' after '<!-- ... <script>' in contents of <script> tag";
                $1 and redo SCRIPT_DATA;
                redo SCRIPT_DATA_ESCAPED;
            }
        }
        undef
    };

    if (defined(my $error = $script_content_error->($text))) {
        croak $error;
    }

    $self->_emit_raw($text);
}

method emit_close_tag($name) {
    $name =~ m{\A[a-zA-Z][^\s/>[:cntrl:]]*\z}
        or croak "invalid HTML tag name: '$name'";
    $self->_emit_raw("</$name>");
}

method emit_open_tag_name_fragment($name) {
    $name =~ m{\A[a-zA-Z][^\s/>[:cntrl:]]*\z}
        or croak "invalid HTML tag name: '$name'";

    $self->_emit_raw("<$name");
}

method emit_open_tag_attr_name_fragment($attr) {
    $attr =~ m{\A[^\s/>="'<[:cntrl:]]+\z}
        or croak "invalid HTML attribute name: '$attr'";
    $self->_emit_raw(" $attr");
}

method emit_open_tag_attr_fragment($attr, $value) {
    $self->emit_open_tag_attr_name_fragment($attr);
    return if $value eq '';

    my $esc_cntrl = fun ($str) {
        $str =~ s{([\x00-\x1f\x7f-\x9f])}{ '&#' . ord($1) . ';' }egr
    };

    $self->_emit_raw("=");
    my $html;
    if ($value !~ m{[\s"'=<>`]}) {
        $html = $esc_cntrl->($value =~ s/&/&amp;/gr);
    } elsif ($value =~ tr/"// > $value =~ tr/'//) {
        $html = "'" . $esc_cntrl->($value =~ s{([&'])}{ $1 eq '&' ? '&amp;' : '&apos;' }egr) . "'";
    } else {
        $html = '"' . $esc_cntrl->($value =~ s{([&"])}{ $1 eq '&' ? '&amp;' : '&quot;' }egr) . '"';
    }
    $self->_emit_raw($html);
}

method emit_open_tag_attr_var_fragment($attr, $var) {
    $self->emit_open_tag_attr_name_fragment($attr);
    $self->_emit_raw('="');
    $self->emit_variable_qq($var);
    $self->_emit_raw('"');
}

method emit_open_tag_attr_transform_fragment($attr, $names, $value) {
    $attr =~ m{\A[^\s/>="'<[:cntrl:]]+\z}
        or croak "invalid HTML attribute name: '$attr'";
    push @{$self->{code}}, { type => OP_MANGLE_ATTR, attr => $attr, names => $names, value => $value };
}

method emit_open_tag_close_fragment() {
    $self->_emit_raw(">");
}

method emit_open_tag($name, $attrs, :$self_closing = 0) {
    $self->emit_open_tag_name_fragment($name);

    for my $attr (sort keys %$attrs) {
        $self->emit_open_tag_attr_fragment($attr, $attrs->{$attr});
    }

    $self->_emit_raw(" /") if $self_closing;
    $self->emit_open_tag_close_fragment;
}

method emit_variable($var) {
    push @{$self->{code}}, { type => OP_VAR, name => $var };
}

method emit_variable_qq($var) {
    push @{$self->{code}}, { type => OP_VAR_QQ, name => $var };
}

method emit_variable_html($var) {
    push @{$self->{code}}, { type => OP_VAR_HTML, name => $var };
}

method emit_call($names, $value) {
    push @{$self->{code}}, { type => OP_CALL, names => $names, value => $value };
}

method emit_call_qq($names, $value) {
    push @{$self->{code}}, { type => OP_CALL_QQ, names => $names, value => $value };
}

method insert_loop($var) {
    my $nested = ref($self)->new(_scope => $self->scope + 1);
    push @{$self->{code}}, { type => OP_LOOP, name => $var, body => $nested };
    $nested
}

method insert_cond($vars) {
    my $nested = ref($self)->new(_scope => $self->scope);
    push @{$self->{code}}, { type => OP_COND, names => $vars, body => $nested };
    $nested
}

method rescoped_onto($scope) {
    my @code;
    for my $op (@{$self->{code}}) {
        if ($op->{type} eq OP_RAW) {
            push @code, { %$op };
        } elsif ($op->{type} eq OP_VAR || $op->{type} eq OP_VAR_QQ || $op->{type} eq OP_VAR_HTML) {
            push @code, { %$op, name => [$op->{name}[0] + $scope, $op->{name}[1]] };
        } elsif ($op->{type} eq OP_CALL || $op->{type} eq OP_CALL_QQ || $op->{type} eq OP_MANGLE_ATTR) {
            my @names = map [$_->[0] + $scope, $_->[1]], @{$op->{names}};
            push @code, { %$op, names => \@names };
        } elsif ($op->{type} eq OP_LOOP) {
            push @code, { %$op, name => [$op->{name}[0] + $scope, $op->{name}[1]], body => $op->{body}->rescoped_onto($scope) };
        } elsif ($op->{type} eq OP_COND) {
            my @names = map [$_->[0] + $scope, $_->[1]], @{$op->{names}};
            push @code, { %$op, names => \@names, body => $op->{body}->rescoped_onto($scope) };
        } else {
            die "Internal error: unknown op type $op->{type}";
        }
    }
    my $new = ref($self)->new(_scope => $scope);
    $new->{code} = \@code;
    $new
}

method incorporate($other) {
    my $inner = $other->rescoped_onto($self->scope);
    my $code = $inner->{code};
    if ($code->[0]{type} eq OP_RAW && $self->{code}[-1]{type} eq OP_RAW) {
        $self->{code}[-1]{str} .= shift(@$code)->{str};
    }
    push @{$self->{code}}, @$code;
}

my %perl_esc = (
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\r" => "\\r",
    "\f" => "\\f",
    '"'  => '\\"',
    '\\' => '\\\\',
    '$'  => '\\$',
    '@'  => '\\@',
);

fun _as_perl_string($str) {
    '"' . $str =~ s{([^ -~]|[\$\@\\"])}{ $perl_esc{$1} // sprintf('\\x{%x}', ord $1) }egr . '"'
}

fun _perl_identifier($str) {
    (my $id = "_$str") =~ tr/A-Za-z0-9/_/cs;
    length($id) <= 102
        ? $id
        : '__' . substr $id, -100
}

my @types = sort qw(
    array
    bool
    func
    html
    str
);

method assemble(:$data_format, :$data_format_mapping) {
    $data_format eq 'nested' || $data_format eq 'sigil'
        or croak "Invalid data format: '$data_format'";
    ref($data_format_mapping) eq 'HASH'
        or croak "Invalid data format mapping: '$data_format_mapping'";
    {
        my $i = 0;
        my @keys = sort keys %$data_format_mapping;
        for my $t (@keys) {
            $i >= @types || $t lt $types[$i]
                and croak "Invalid key '$t' in data format mapping";
            $t gt $types[$i]
                and croak "Missing key '$types[$i]' in data format mapping";
        } continue {
            $i++;
        }
        $i == @types
            or croak "Missing key '$types[$i]' in data format mapping";
    }

    my $need_html_esc;
    my $inline_esc_in_place = fun ($var) {
        $need_html_esc++;
        "$var =~ s/([<&])/\$html_esc{\$1}/g"
    };
    my $inline_esc = fun ($var) {
        $inline_esc_in_place->($var) . 'r'
    };
    my $inline_esc_qq = fun ($var) {
        $need_html_esc++;
        "$var =~ s/([<&\"])/\$html_esc{\$1}/gr"
    };

    my %gen_vars;
    my $template_var_name = fun ($type, $scope, $name) {
        my $sigil = $data_format eq 'sigil' ? $data_format_mapping->{$type} : '';
        my $vname = $sigil . $name;
        my $scope_name = $gen_vars{$scope}{name};
        "*$scope_name/$vname"
    };

    my $gen_seed = 'a';
    my $mk_varid = fun ($type, $var) {
        $type = "_$type" if length $type;
        '$V_' . $gen_seed++ . $type . _perl_identifier($gen_vars{$var->[0]}{name} . '/' . $var->[1])
    };
    my $str_var = fun ($var) {
        $gen_vars{$var->[0]}{html}{$var->[1]} //= $mk_varid->('', $var)
    };
    my $str_var_qq = fun ($var) {
        $str_var->($var);
        $gen_vars{$var->[0]}{html_qq}{$var->[1]} //= $mk_varid->('qq', $var)
    };
    my $func_var = fun ($var) {
        $gen_vars{$var->[0]}{func}{$var->[1]} //= $mk_varid->('fn', $var)
    };

    my %needs_iter;

    my $ref_of_type = fun ($type, $param) {
        my $scope = $param->[0];
        my $name = $param->[1];
        if (ref($name) eq 'SCALAR') {
            $type eq 'bool' && $$name eq 'iter0'
                or die "Internal error: bad variable reference ($type) $$name";
            $scope > 0
                or die "Internal error: scope $scope shouldn't have an iterator";
            $needs_iter{$scope}++;
            return '($iter_' . $scope . ' == 0)';
        }
        $gen_vars{$scope}{by_type}{$type}++;
        if ($data_format eq 'sigil') {
            my $typeof = $gen_vars{$scope}{typeof} //= {};
            my $vname = $data_format_mapping->{$type} . $name;
            if (!defined(my $otype = $typeof->{$vname})) {
                $typeof->{$vname} = $type;
            } elsif ($type ne $otype) {
                croak "Can't use template variable '" . $template_var_name->($type, $scope, $name) . "' at two different types: '$otype', '$type'";
            }
            return '$env_' . $scope . '->{' . _as_perl_string($vname) . '}';
        }
        '$env_' . $scope . '_' . $type . '->{' . _as_perl_string($name) . '}'
    };

    my $build_call = fun ($op) {
        my $code = defined $op->{value} ? _as_perl_string $op->{value} : 'undef';
        my $scalar = 0;
        for my $fn (reverse @{$op->{names}}) {
            $code = "scalar $code" if $scalar++;
            #$code = $ref_of_type->('func', $fn) . '->(' . $code . ')';
            $code = $func_var->($fn) . '->(' . $code . ')';
        }
        $code
    };

    my $bclass = 'HTML::Blitz::Builder';
    my $need_builder = 0;
    my $need_err_callable = 0;

    my $do_assemble = fun ($scope_parent, $scope, $code, :$in_new_scope_env = 1) {
        my $new_scope_env = {
            name    => (defined $scope_parent->[0] ? $gen_vars{$scope_parent->[0]}{name} . '/' : '') . $scope_parent->[1],
            by_type => \my %seen_ref,
            html    => \my %local_vars_html,
            html_qq => \my %local_vars_html_qq,
            func    => \my %local_vars_func,
            # typeof => {},
        };
        local $gen_vars{$scope} = $new_scope_env
            if $in_new_scope_env;

        my $gen_code = '';

        my $last_concat = '';
        my $last_concat_depth = 0;
        my $last_concat_flush = fun () {
            if ($last_concat_depth) {
                $gen_code .= "$last_concat;\n";
                $last_concat = '';
                $last_concat_depth = 0;
            }
        };
        my $gen_concat = fun ($text) {
            $last_concat = $last_concat_depth ? "($last_concat)" : '$r';
            $last_concat .= " .= $text";
            $last_concat_depth++;
            $last_concat_flush->() if $last_concat_depth >= MAX_NESTED_CONCAT;
        };

        for my $op (@$code) {
            if ($op->{type} eq OP_RAW) {
                $gen_concat->(_as_perl_string($op->{str})) if length $op->{str};
            } elsif ($op->{type} eq OP_VAR) {
                $gen_concat->($str_var->($op->{name}));
            } elsif ($op->{type} eq OP_VAR_QQ) {
                $gen_concat->($str_var_qq->($op->{name}));
            } elsif ($op->{type} eq OP_CALL) {
                $gen_concat->($inline_esc->($build_call->($op)));
            } elsif ($op->{type} eq OP_CALL_QQ) {
                $gen_concat->($inline_esc_qq->($build_call->($op)));
            } elsif ($op->{type} eq OP_VAR_HTML) {
                $gen_concat->("${bclass}::to_html(" . $ref_of_type->('html', $op->{name}) . ')');
                $need_builder++;
            } elsif ($op->{type} eq OP_MANGLE_ATTR) {
                $last_concat_flush->();
                $gen_code .= ''
                    . 'if (defined(my $v = ' . $build_call->($op) . ")) {\n"
                    . '    $r .= ' . _as_perl_string(" $op->{attr}=\"") . ' . ' . $inline_esc_qq->('$v') . " . '\"';\n"
                    . "}\n";
            } elsif ($op->{type} eq OP_LOOP) {
                $last_concat_flush->();
                my $subscope = $op->{body}->scope;
                local $needs_iter{$subscope} = 0;
                my $loop_code = ''
                    . 'for my $env_' . $subscope . ' (@{' . $ref_of_type->('array', $op->{name}) . "}) {\n"
                    . __SUB__->($op->{name}, $subscope, $op->{body}{code}) =~ s/^/    /mgr
                    . "}";
                if ($needs_iter{$subscope}) {
                    $loop_code = ''
                        . "do {\n"
                        . "    my \$iter_$subscope = 0;\n"
                        . $loop_code =~ s/^/    /mgr
                        . " continue {\n"
                        . "        \$iter_$subscope++;\n"
                        . "    }\n"
                        . "};";
                }
                $gen_code .= $loop_code;
                $gen_code .= "\n";
            } elsif ($op->{type} eq OP_COND) {
                $last_concat_flush->();
                $gen_code .= ''
                    . 'unless (' . join(' || ', map $ref_of_type->('bool', $_), @{$op->{names}}) . ") {\n"
                    . __SUB__->($scope_parent, $scope, $op->{body}{code}, in_new_scope_env => 0) =~ s/^/    /mgr
                    . "}\n";
            } else {
                die "Internal error: unknown op type $op->{type}";
            }
        }
        $last_concat_flush->();

        if ($in_new_scope_env) {
            my $decl = '';
            for my $rvar (sort keys %local_vars_html) {
                my $pvar = $local_vars_html{$rvar};
                $decl .= $inline_esc_in_place->("(my $pvar = " . $ref_of_type->('str', [$scope, $rvar]) . ")") . ";\n";
            }
            for my $rvar (sort keys %local_vars_html_qq) {
                my $pvar = $local_vars_html_qq{$rvar};
                $decl .= "(my $pvar = $local_vars_html{$rvar}) =~ s/\"/&quot;/g;\n";
            }
            for my $rvar (sort keys %local_vars_func) {
                my $pvar = $local_vars_func{$rvar};
                $decl .= "my $pvar = " . $ref_of_type->('func', [$scope, $rvar]) . ";\n";
                $decl .= "$pvar = ref($pvar) ? \\&$pvar : \$err_callable->(" . _as_perl_string($template_var_name->('func', $scope, $rvar)) . ", $pvar);\n";
                $need_err_callable++;
            }

            $gen_code = "$decl\n$gen_code" if length $decl;

            if ($data_format eq 'nested') {
                $decl = '';
                for my $type (sort keys %seen_ref) {
                    $decl .= "my \$env_${scope}_${type} = \$env_$scope" . "->{" . _as_perl_string($data_format_mapping->{$type}) . "};\n";
                }
                $gen_code = "$decl\n$gen_code" if length $decl;
            }
        }

        $gen_code
    };

    my $gen_code = $do_assemble->([undef, ''], $self->scope, $self->{code});

    "use strict; use warnings;\n"
    . ($need_err_callable
        ? "use Carp ();\n"
        : ''
    )
    . ($need_builder
        ? "use $bclass ();\n"
        : ''
    )
    . "sub {\n"
    . '    my ($env_' . $self->scope . ") = \@_;\n"
    . ($need_err_callable
        ? q{    my $err_callable = sub { Carp::croak "Template function variable '$_[0]' must be callable, not " . (defined $_[1] ? "'$_[1]'" : "undef"); };} . "\n"
        : ''
    )
    . ($need_html_esc
        ? "    my %html_esc = ('<' => '&lt;', '&' => '&amp;', '\"' => '&quot;');\n"
        : ''
    )
    . "    my \$r = '';\n"
    . "\n"
    . $gen_code =~ s/^/    /mgr
    . "    \$r\n"
    . "}\n"
}

1
