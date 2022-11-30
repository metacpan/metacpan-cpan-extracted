# This code can be redistributed and modified under the terms of the GNU Affero
# General Public License as published by the Free Software Foundation, either
# version 3 of the License, or (at your option) any later version.
# See the "COPYING" file for details.
package HTML::Blitz::RuleSet;
use HTML::Blitz::pragma;
use HTML::Blitz::Matcher ();
use HTML::Blitz::Parser ();
use HTML::Blitz::CodeGen ();
use HTML::Blitz::TokenType qw(
    TT_TAG_OPEN
    TT_TAG_CLOSE
    TT_TEXT
    TT_COMMENT
    TT_DOCTYPE
);
use HTML::Blitz::ActionType qw(
    AT_P_IMMEDIATE
    AT_P_VARIABLE
    AT_P_TRANSFORM
    AT_P_FRAGMENT
    AT_P_VARHTML

    AT_A_REMOVE_ATTR
    AT_A_SET_ATTR
    AT_A_MODIFY_ATTR

    AT_AS_REPLACE_ATTRS
    AT_AS_MODIFY_ATTRS

    AT_REMOVE_IF
    AT_REPLACE_OUTER
    AT_REPEAT_OUTER
    AT_REPLACE_INNER
);
use List::Util qw(all reduce);

method new($class:) {
    bless {
        rules            => [],
        keep_doctype     => 1,
        keep_comments_re => qr/\A/,
        dummy_marker_re  => qr/\A(?!)/,
    }, $class
}

method set_keep_doctype($val) {
    $self->{keep_doctype} = !!$val;
}

method set_keep_comments_re($keep_comments_re) {
    $self->{keep_comments_re} = qr/(?#)$keep_comments_re/;
}

method set_dummy_marker_re($dummy_marker_re) {
    $self->{dummy_marker_re} = qr/(?#)$dummy_marker_re/;
}

fun _combine_params_plain($p1, $p2) {
    if ($p1->{type} eq AT_P_IMMEDIATE) {
        if ($p2->{type} eq AT_P_IMMEDIATE) {
            return length($p1->{value}) <= length($p2->{value}) ? $p1 : $p2;
        }
        return $p1;
    }
    if ($p2->{type} eq AT_P_IMMEDIATE) {
        return $p2;
    }
    $p1->{type} eq AT_P_VARIABLE && $p2->{type} eq AT_P_VARIABLE
        or die "Internal error: unexpected parameter types '$p1->{type}', '$p2->{type}'";
    return $p1;
}

fun _combine_transforms($t1, $t2) {
    $t1->{type} eq AT_P_TRANSFORM && $t2->{type} eq AT_P_TRANSFORM
        or die "Internal error: unexpected transform types '$t1->{type}', '$t2->{type}'";
    return {
        type    => AT_P_TRANSFORM,
        static  => do {
            my ($f1, $f2) = ($t1->{static}, $t2->{static});
            fun ($x) { $f1->($f2->($x)) }
        },
        dynamic => [@{$t1->{dynamic}}, @{$t2->{dynamic}}],
    };
}

fun _combine_params($p1, $p2) {
    if ($p1->{type} eq AT_P_FRAGMENT) {
        if ($p2->{type} eq AT_P_FRAGMENT || $p2->{type} eq AT_P_TRANSFORM) {
            return $p1;
        }
        $p2->{type} eq AT_P_IMMEDIATE || $p2->{type} eq AT_P_VARIABLE || $p2->{type} eq AT_P_VARHTML
            or die "Internal error: unexpected parameter type '$p2->{type}'";
        return $p2;
    }

    if ($p2->{type} eq AT_P_FRAGMENT) {
        if ($p1->{type} eq AT_P_TRANSFORM) {
            return $p2;
        }
        $p1->{type} eq AT_P_IMMEDIATE || $p1->{type} eq AT_P_VARIABLE || $p1->{type} eq AT_P_VARHTML
            or die "Internal error: unexpected parameter type '$p1->{type}'";
        return $p1;
    }

    if ($p1->{type} eq AT_P_VARHTML) {
        if ($p2->{type} eq AT_P_VARHTML || $p2->{type} eq AT_P_TRANSFORM) {
            return $p1;
        }
        $p2->{type} eq AT_P_IMMEDIATE || $p2->{type} eq AT_P_VARIABLE
            or die "Internal error: unexpected parameter type '$p2->{type}'";
    }

    if ($p2->{type} eq AT_P_VARHTML) {
        if ($p1->{type} eq AT_P_TRANSFORM) {
            return $p2;
        }
        $p1->{type} eq AT_P_IMMEDIATE || $p1->{type} eq AT_P_VARIABLE
            or die "Internal error: unexpected parameter type '$p1->{type}'";
        return $p1;
    }

    if ($p1->{type} eq AT_P_TRANSFORM) {
        if ($p2->{type} eq AT_P_TRANSFORM) {
            return _combine_transforms($p1, $p2);
        }
        $p2->{type} eq AT_P_IMMEDIATE || $p2->{type} eq AT_P_VARIABLE
            or die "Internal error: unexpected parameter type '$p2->{type}'";
        return $p2;
    }

    if ($p2->{type} eq AT_P_TRANSFORM) {
        $p1->{type} eq AT_P_IMMEDIATE || $p1->{type} eq AT_P_VARIABLE
            or die "Internal error: unexpected parameter type '$p1->{type}'";
        return $p1;
    }

    _combine_params_plain $p1, $p2
}

fun _combine_contents($p1, $p2) {
    return $p1 if !defined $p2;
    return $p2 if !defined $p1;
    _combine_params $p1, $p2
}

fun _combine_attr_actions($aa1, $aa2) {
    return $aa1 if $aa1->{type} eq AT_A_REMOVE_ATTR;
    return $aa2 if $aa2->{type} eq AT_A_REMOVE_ATTR;
    if ($aa1->{type} eq AT_A_SET_ATTR) {
        if ($aa2->{type} eq AT_A_SET_ATTR) {
            return { type => AT_A_SET_ATTR, param => _combine_params_plain($aa1->{param}, $aa2->{param}) };
        }
        $aa2->{type} eq AT_A_MODIFY_ATTR
            or die "Internal error: unexpected attr action type '$aa2->{type}'";
        return $aa1;
    }
    if ($aa2->{type} eq AT_A_SET_ATTR) {
        $aa1->{type} eq AT_A_MODIFY_ATTR
            or die "Internal error: unexpected attr action type '$aa1->{type}'";
        return $aa2;
    }
    $aa1->{type} eq AT_A_MODIFY_ATTR && $aa2->{type} eq AT_A_MODIFY_ATTR
        or die "Internal error: unexpected attr action types '$aa1->{type}', '$aa2->{type}'";
    return { type => AT_A_MODIFY_ATTR, param => _combine_transforms($aa1->{param}, $aa2->{param}) };
}

fun _combine_attrset_actions($asa1, $asa2) {
    if ($asa1->{type} eq AT_AS_REPLACE_ATTRS) {
        if ($asa2->{type} eq AT_AS_REPLACE_ATTRS) {
            return
                (all { $_->{type} eq AT_P_IMMEDIATE } values %{$asa1->{content}}) ? $asa1 :
                (all { $_->{type} eq AT_P_IMMEDIATE } values %{$asa2->{content}}) ? $asa2 :
                keys(%{$asa1->{content}}) <= keys(%{$asa2->{content}}) ? $asa1 :
                $asa2;
        }
        $asa2->{type} eq AT_AS_MODIFY_ATTRS
            or die "Internal error: unexpected attrset replacement type '$asa2->{type}'";
        return $asa1;
    }
    if ($asa2->{type} eq AT_AS_REPLACE_ATTRS) {
        $asa1->{type} eq AT_AS_MODIFY_ATTRS
            or die "Internal error: unexpected attrset replacement type '$asa1->{type}'";
        return $asa2;
    }
    $asa1->{type} eq AT_AS_MODIFY_ATTRS && $asa2->{type} eq AT_AS_MODIFY_ATTRS
        or die "Internal error: unexpected attrset replacement types '$asa1->{type}', '$asa2->{type}'";
    my %content = %{$asa1->{content}};
    for my $k (keys %{$asa2->{content}}) {
        my $v = $asa2->{content}{$k};
        $content{$k} = exists $content{$k} ? _combine_attr_actions($content{$k}, $v) : $v;
    }
    return { type => AT_AS_MODIFY_ATTRS, content => \%content };
}

fun _combine_actions_maybe($act1, $act2) {
    defined($act1) && defined($act2)
        ? _combine_actions($act1, $act2)
        : $act1 // $act2
}

fun _combine_actions($act1, $act2) {
    if ($act1->{type} eq AT_REMOVE_IF) {
        if ($act2->{type} eq AT_REMOVE_IF) {
            return { type => AT_REMOVE_IF, cond => [@{$act1->{cond}}, @{$act2->{cond}}], else => _combine_actions_maybe($act1->{else}, $act2->{else}) };
        }
        return { type => AT_REMOVE_IF, cond => $act1->{cond}, else => _combine_actions_maybe($act1->{else}, $act2) };
    }
    if ($act2->{type} eq AT_REMOVE_IF) {
        return { type => AT_REMOVE_IF, cond => $act2->{cond}, else => _combine_actions_maybe($act1, $act2->{else}) };
    }
    if ($act1->{type} eq AT_REPLACE_OUTER) {
        if ($act2->{type} eq AT_REPLACE_OUTER) {
            return { type => AT_REPLACE_OUTER, param => _combine_params($act1->{param}, $act2->{param}) };
        }
        return $act1;
    }
    if ($act2->{type} eq AT_REPLACE_OUTER) {
        return $act2;
    }
    if ($act1->{type} eq AT_REPEAT_OUTER) {
        return { %$act1, nested => _combine_actions($act1->{nested}, $act2) };
    }
    if ($act2->{type} eq AT_REPEAT_OUTER) {
        return { %$act2, nested => _combine_actions($act1, $act2->{nested}) };
    }
    $act1->{type} eq AT_REPLACE_INNER && $act2->{type} eq AT_REPLACE_INNER
        or die "Internal error: unexpected action types '$act1->{type}', '$act2->{type}'";
    return {
        type    => AT_REPLACE_INNER,
        repeat  => [@{$act1->{repeat}}, @{$act2->{repeat}}],
        attrset => _combine_attrset_actions($act1->{attrset}, $act2->{attrset}),
        content => _combine_contents($act1->{content}, $act2->{content}),
    };
}

fun _reduce_actions(@actions) {
    reduce { _combine_actions $a, $b } @actions
}

fun _bind_scope($scope, $action) {
    if ($action->{type} eq AT_REMOVE_IF) {
        return {
            type => AT_REMOVE_IF,
            cond => [map [$_->[0] // $scope, $_->[1]], @{$action->{cond}}],
            else => $action->{else} && _bind_scope($scope, $action->{else}),
        };
    } elsif ($action->{type} eq AT_REPLACE_OUTER) {
        my $param = $action->{param};
        if ($param->{type} eq AT_P_VARIABLE || $param->{type} eq AT_P_VARHTML) {
            my $value = $param->{value};
            if (!defined $value->[0]) {
                return { %$action, param => { %$param, value => [$scope, $value->[1]] } };
            }
        } elsif ($param->{type} eq AT_P_TRANSFORM) {
            if (@{$param->{dynamic}}) {
                return { %$action, param => { %$param, dynamic => [ map [$_->[0] // $scope, $_->[1]], @{$param->{dynamic}} ] } };
            }
        }
    } elsif ($action->{type} eq AT_REPEAT_OUTER) {
        if (!defined $action->{var}[0]) {
            return { %$action, var => [$scope, $action->{var}[1]] };
        }
    } else {
        $action->{type} eq AT_REPLACE_INNER
            or die "Internal error: unexpected action type '$action->{type}'";

        my $did_replace = 0;
        my $scope_var = fun ($var) {
            defined $var->[0] ? $var : do {
                $did_replace++;
                [$scope, $var->[1]]
            }
        };
        my %replacement = (type => AT_REPLACE_INNER, attrset => {}, content => undef, repeat => []);

        my $asa = $action->{attrset};
        if ($asa->{type} eq AT_AS_REPLACE_ATTRS) {
            $replacement{attrset}{type} = AT_AS_REPLACE_ATTRS;
            my $content = $asa->{content};
            $replacement{attrset}{content} = \my %copy;
            for my $key (keys %$content) {
                my $value = $content->{$key};
                if ($value->{type} eq AT_P_VARIABLE && !defined $value->{value}[0]) {
                    $copy{$key} = { type => AT_P_VARIABLE, value => [$scope, $value->{value}[1]] };
                    $did_replace++;
                } else {
                    $copy{$key} = $value;
                }
            }
        } else {
            $asa->{type} eq AT_AS_MODIFY_ATTRS
                or die "Internal error: unexpected attrset replacement type '$asa->{type}'";
            $replacement{attrset}{type} = AT_AS_MODIFY_ATTRS;
            my $content = $asa->{content};
            $replacement{attrset}{content} = \my %copy;
            for my $key (keys %$content) {
                my $value = $content->{$key};
                if ($value->{type} eq AT_A_SET_ATTR && $value->{param}{type} eq AT_P_VARIABLE && !defined $value->{param}{value}[0]) {
                    $copy{$key} = { type => AT_A_SET_ATTR, param => { type => AT_P_VARIABLE, value => [$scope, $value->{param}{value}[1]] } };
                    $did_replace++;
                } elsif ($value->{type} eq AT_A_MODIFY_ATTR && (my $param = $value->{param})->{dynamic}->@*) {
                    $param->{type} eq AT_P_TRANSFORM
                        or die "Internal error: unexpected parameter type '$param->{type}'";
                    $copy{$key} = {
                        type  => AT_A_MODIFY_ATTR,
                        param => {
                            type    => AT_P_TRANSFORM,
                            static  => $param->{static},
                            dynamic => [
                                map $scope_var->($_), @{$param->{dynamic}}
                            ],
                        },
                    };
                } else {
                    $copy{$key} = $value;
                }
            }
        }

        if (defined(my $param = $action->{content})) {
            if (($param->{type} eq AT_P_VARIABLE || $param->{type} eq AT_P_VARHTML) && !defined $param->{value}[0]) {
                $replacement{content} = { %$param, value => [$scope, $param->{value}[1]] };
                $did_replace++;
            } elsif ($param->{type} eq AT_P_TRANSFORM && @{$param->{dynamic}}) {
                $replacement{content} = {
                    type    => AT_P_TRANSFORM,
                    static  => $param->{static},
                    dynamic => [
                        map $scope_var->($_), @{$param->{dynamic}}
                    ],
                };
            } else {
                $replacement{content} = $param;
            }
        }

        if (@{$replacement{repeat}} = @{$action->{repeat}}) {
            my $rfirst = \$replacement{repeat}[0];
            if (!defined $$rfirst->{var}[0]) {
                $$rfirst = { var => $scope_var->($$rfirst->{var}), rules => $$rfirst->{rules} };
                $did_replace++;
            }
        }

        return \%replacement if $did_replace;
    }
    $action
}

method add_rule($selector, $action, @actions) {
    push @{$self->{rules}}, {
        selector => $selector,
        result   => _reduce_actions($action, @actions),
    };
}

fun _skip_children($name, $parser, :$collect_content = undef) {
    my $content = '';
    my $depth = 0;
    while () {
        my $token = $parser->parse // die "Internal error: missing '</$name>' in parser results";
        if ($token->{type} eq TT_TAG_CLOSE) {
            last if $depth == 0;
            $depth--;
        } elsif ($token->{type} eq TT_TAG_OPEN) {
            $depth++ if !$token->{is_self_closing};
        } elsif ($collect_content && $token->{type} eq TT_TEXT) {
            $content .= $token->{content};
        }
    }
    $collect_content ? $content : undef
}

method compile($name, $html) {
    my $codegen = HTML::Blitz::CodeGen->new;
    my $matcher = HTML::Blitz::Matcher->new([map +{ selector => $_->{selector}, result => _bind_scope($codegen->scope, $_->{result}) }, @{$self->{rules}}]);
    my $parser  = HTML::Blitz::Parser->new($name, $html);

    while (my $token = $parser->parse) {
        if ($token->{type} eq TT_DOCTYPE) {
            if ($self->{keep_doctype}) {
                $codegen->emit_doctype;
            }
        } elsif ($token->{type} eq TT_COMMENT) {
            if ($token->{content} =~ /$self->{keep_comments_re}/) {
                $codegen->emit_comment($token->{content});
            }
        } elsif ($token->{type} eq TT_TEXT) {
            if ($token->{content} =~ /$self->{dummy_marker_re}/) {
                $parser->throw_for($token, "raw text contains forbidden dummy marker $self->{dummy_marker_re}");
            }
            my $cur_tag = $parser->current_tag;
            if ($cur_tag eq 'script') {
                $codegen->emit_script_text($token->{content});
            } elsif ($cur_tag eq 'style') {
                $codegen->emit_style_text($token->{content});
            } else {
                $codegen->emit_text($token->{content});
            }
        } elsif ($token->{type} eq TT_TAG_CLOSE) {
            $matcher->leave(\my %ret);
            ($ret{codegen} // $codegen)->emit_close_tag($token->{name});
        } elsif ($token->{type} eq TT_TAG_OPEN) {
            my $action = _reduce_actions $matcher->enter($token->{name}, $token->{attrs});

            if (defined($action) && $action->{type} eq AT_REMOVE_IF) {
                my $cond_gen = $codegen->insert_cond($action->{cond});
                $action = $action->{else};

                my $outer_gen = $codegen;
                $codegen = $cond_gen;
                $matcher->on_leave(fun ($ret = {}) {
                    $ret->{codegen} //= $cond_gen;
                    $codegen = $outer_gen;
                });
            }

            if (!defined $action) {
                my $attrs = $token->{attrs};
                my @bad_attrs = sort grep $attrs->{$_} =~ /$self->{dummy_marker_re}/, keys %$attrs;
                if (@bad_attrs) {
                    $parser->throw_for($token, "'$token->{name}' tag contains forbidden dummy marker $self->{dummy_marker_re} in the following attribute(s): " . join(', ', @bad_attrs));
                }
                $codegen->emit_open_tag($token->{name}, $attrs, self_closing => $token->{is_self_closing} && !$token->{is_void});
                $matcher->leave if $token->{is_self_closing};
                next;
            }

            if ($action->{type} eq AT_REPLACE_OUTER) {
                my $param = $action->{param};
                my $skipped = 0;
                if ($param->{type} eq AT_P_IMMEDIATE) {
                    $codegen->emit_text($param->{value});
                } elsif ($param->{type} eq AT_P_VARIABLE) {
                    $codegen->emit_variable($param->{value});
                } elsif ($param->{type} eq AT_P_FRAGMENT) {
                    $codegen->incorporate($param->{value});
                } elsif ($param->{type} eq AT_P_VARHTML) {
                    $codegen->emit_variable_html($param->{value});
                } else {
                    $param->{type} eq AT_P_TRANSFORM
                        or die "Internal error: unexpected parameter type '$param->{type}'";
                    if (!$token->{is_void}) {
                        my $text_content = $token->{is_self_closing} ? '' : _skip_children $token->{name}, $parser, collect_content => 1;
                        $skipped = 1;
                        $text_content = '' . $param->{static}->($text_content);
                        if (@{$param->{dynamic}}) {
                            $codegen->emit_call($param->{dynamic}, $text_content);
                        } else {
                            $codegen->emit_text($text_content);
                        }
                    }
                }

                _skip_children $token->{name}, $parser if !$skipped && !$token->{is_self_closing};
                $matcher->leave;
                next;
            }

            while ($action->{type} eq AT_REPEAT_OUTER) {
                my $loop_gen = $codegen->insert_loop($action->{var});

                for my $proto_rule (@{$action->{rules}}) {
                    my ($selector, @actions) = @$proto_rule;
                    my $action = _bind_scope $loop_gen->scope, _reduce_actions @actions;
                    $matcher->add_temp_rule({ selector => $selector, result => $action });
                }

                my $inplace = _reduce_actions @{$action->{inplace}};
                $action = defined($inplace)
                    ? _combine_actions $action->{nested}, _bind_scope $loop_gen->scope, $inplace
                    : $action->{nested};

                my $outer_gen = $codegen;
                $codegen = $loop_gen;
                $matcher->on_leave(fun ($ret = {}) {
                    $ret->{codegen} //= $loop_gen;
                    $codegen = $outer_gen;
                });
            }

            $action->{type} eq AT_REPLACE_INNER
                or die "Internal error: unexpected action type '$action->{type}'";

            $codegen->emit_open_tag_name_fragment($token->{name});

            my $attrset = $action->{attrset};
            if ($attrset->{type} eq AT_AS_REPLACE_ATTRS) {
                my $attrs = $attrset->{content};
                for my $attr (sort keys %$attrs) {
                    my $param = $attrs->{$attr};
                    if ($param->{type} eq AT_P_IMMEDIATE) {
                        $codegen->emit_open_tag_attr_fragment($attr, $param->{value});
                    } else {
                        $param->{type} eq AT_P_VARIABLE
                            or die "Internal error: unexpected parameter type '$param->{type}'";
                        $codegen->emit_open_tag_attr_var_fragment($attr, $param->{value});
                    }
                }
            } else {
                $attrset->{type} eq AT_AS_MODIFY_ATTRS
                    or die "Internal error: unexpected attrset replacement type '$attrset->{type}'";

                my $token_attrs = $token->{attrs};
                my %attrs = map +(
                    $_ => {
                        type     => AT_P_IMMEDIATE,
                        value    => $token_attrs->{$_},
                        pristine => 1,
                    }
                ), keys %$token_attrs;

                my $attr_actions = $attrset->{content};
                for my $attr (keys %$attr_actions) {
                    my $attr_action = $attr_actions->{$attr};
                    if ($attr_action->{type} eq AT_A_REMOVE_ATTR) {
                        delete $attrs{$attr};
                    } elsif ($attr_action->{type} eq AT_A_SET_ATTR) {
                        $attrs{$attr} = $attr_action->{param};
                    } else {
                        $attr_action->{type} eq AT_A_MODIFY_ATTR
                            or die "Internal error: unexpected attr action type '$attr_action->{type}'";
                        my $param = $attr_action->{param};
                        $param->{type} eq AT_P_TRANSFORM
                            or die "Internal error: unexpected parameter type '$param->{type}'";
                        my $value = $param->{static}->($attrs{$attr}{value});
                        if (@{$param->{dynamic}}) {
                            $attrs{$attr} = { type => AT_P_TRANSFORM, dynamic => $param->{dynamic}, value => $value };
                        } elsif (!defined $value) {
                            delete $attrs{$attr};
                        } else {
                            $attrs{$attr} = { type => AT_P_IMMEDIATE, value => '' . $value };
                        }
                    }
                }

                my @bad_attrs;
                for my $attr (sort keys %attrs) {
                    my $param = $attrs{$attr};
                    if ($param->{type} eq AT_P_IMMEDIATE) {
                        if ($param->{pristine} && $param->{value} =~ /$self->{dummy_marker_re}/) {
                            push @bad_attrs, $attr;
                        }
                        $codegen->emit_open_tag_attr_fragment($attr, $param->{value});
                    } elsif ($param->{type} eq AT_P_VARIABLE) {
                        $codegen->emit_open_tag_attr_var_fragment($attr, $param->{value});
                    } else {
                        $param->{type} eq AT_P_TRANSFORM
                            or die "Internal error: unexpected parameter type '$param->{type}'";
                        $codegen->emit_open_tag_attr_transform_fragment($attr, $param->{dynamic}, $param->{value});
                    }
                }
                @bad_attrs
                    and $parser->throw_for($token, "<$token->{name}> tag contains forbidden dummy marker $self->{dummy_marker_re} in the following attribute(s): " . join(', ', @bad_attrs));
            }

            $codegen->emit_open_tag_close_fragment;

            for my $repeat (@{$action->{repeat}}) {
                my $loop_gen = $codegen->insert_loop($repeat->{var});
                for my $proto_rule (@{$repeat->{rules}}) {
                    my ($selector, @actions) = @$proto_rule;
                    my $action = _bind_scope $loop_gen->scope, _reduce_actions @actions;
                    $matcher->add_temp_rule({ selector => $selector, result => $action });
                }

                my $outer_gen = $codegen;
                $codegen = $loop_gen;
                $matcher->on_leave(fun (@) { $codegen = $outer_gen; });
            }

            if (defined(my $param = $action->{content})) {
                $token->{is_void}
                    and $parser->throw_for($token, "<$token->{name}> tag cannot have content");

                my $skipped = 0;
                if ($param->{type} eq AT_P_IMMEDIATE) {
                    $codegen->emit_text($param->{value});
                } elsif ($param->{type} eq AT_P_VARIABLE) {
                    $codegen->emit_variable($param->{value});
                } elsif ($param->{type} eq AT_P_FRAGMENT) {
                    $codegen->incorporate($param->{value});
                } elsif ($param->{type} eq AT_P_VARHTML) {
                    $codegen->emit_variable_html($param->{value});
                } else {
                    $param->{type} eq AT_P_TRANSFORM
                        or die "Internal error: unexpected parameter type '$param->{type}'";
                    my $text_content = $token->{is_self_closing} ? '' : _skip_children $token->{name}, $parser, collect_content => 1;
                    $skipped = 1;
                    $text_content = '' . $param->{static}->($text_content);
                    if (@{$param->{dynamic}}) {
                        $codegen->emit_call($param->{dynamic}, $text_content);
                    } else {
                        $codegen->emit_text($text_content);
                    }
                }

                _skip_children $token->{name}, $parser if !$skipped && !$token->{is_self_closing};
                $matcher->leave(\my %ret);
                ($ret{codegen} // $codegen)->emit_close_tag($token->{name});
            } elsif ($token->{is_self_closing}) {
                $matcher->leave;
                $codegen->emit_close_tag($token->{name}) if !$token->{is_void};
            }

        } else {
            die "Internal error: unhandled token type '$token->{type}'";
        }
    }

    $codegen
}

1
