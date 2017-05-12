package Language::Expr::Compiler::js;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010;
use strict;
use warnings;

use Role::Tiny::With;
use parent 'Language::Expr::Compiler::Base';
with 'Language::Expr::CompilerRole';

sub rule_pair_simple {
    my ($self, %args) = @_;
    my $match = $args{match};
    "'$match->{key}':$match->{value}";
}

sub rule_pair_string {
    my ($self, %args) = @_;
    my $match = $args{match};
    "$match->{key}:$match->{value}";
}

sub rule_or_xor {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '||') { push @res, " || $term" }
        elsif ($op eq '//') { @res = ("(function() { let _x = (",
                                      @res, "); return _x==null ? (",
                                      $term, ") : _x })()") }
        elsif ($op eq '^^') { @res = ("(function() { let _a = (",
                                      @res, "); let _b = ($term); ",
                                      "return _a&&!_b || !_a&&_b ? _a : _b })()") }
    }
    join "", grep {defined} @res;
}

sub rule_and {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '&&') { push @res, " && $term" }
    }
    join "", grep {defined} @res;
}

sub rule_ternary {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $opd = $match->{operand};
    "($opd->[0] ? $opd->[1] : $opd->[2])";
}

sub rule_bit_or_xor {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '|') { push @res, " | $term" }
        elsif ($op eq '^') { push @res, " ^ $term" }
    }
    join "", grep {defined} @res;
}

sub rule_bit_and {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '&') { push @res, " & $term" }
    }
    join "", grep {defined} @res;
}

sub rule_comparison3 {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '<=>') { @res = ("(function() { let _a = (",
                                      @res, "); let _b = ($term); ",
                                      "return _a > _b ? 1 : (_a < _b ? -1 : 0) })()") }
        elsif ($op eq 'cmp') { @res = ("(function() { let _a = (",
                                      @res, ") + ''; let _b = ($term) + ''; ",
                                      "return _a > _b ? 1 : (_a < _b ? -1 : 0) })()") }
    }
    join "", grep {defined} @res;
}

sub _comparison1 {
    my ($opd1, $op, $opd2) = @_;
    if    ($op eq 'eq') { return "(function() { let _a = ($opd1) + ''; let _b = ($opd2) + ''; return $opd1 == $opd2 })()" }
    elsif ($op eq 'ne') { return "(function() { let _a = ($opd1) + ''; let _b = ($opd2) + ''; return $opd1 != $opd2 })()" }
    elsif ($op eq 'lt') { return "(function() { let _a = ($opd1) + ''; let _b = ($opd2) + ''; return $opd1 <  $opd2 })()" }
    elsif ($op eq 'le') { return "(function() { let _a = ($opd1) + ''; let _b = ($opd2) + ''; return $opd1 <= $opd2 })()" }
    elsif ($op eq 'gt') { return "(function() { let _a = ($opd1) + ''; let _b = ($opd2) + ''; return $opd1 >  $opd2 })()" }
    elsif ($op eq 'ge') { return "(function() { let _a = ($opd1) + ''; let _b = ($opd2) + ''; return $opd1 >= $opd2 })()" }
    else { return "($opd1 $op $opd2)" }
}

sub rule_comparison {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @opds;
    push @opds, shift @{$match->{operand}};
    return '' unless defined $opds[0];
    my @ops;
    for my $term (@{$match->{operand}}) {
        push @opds, $term;
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '==' ) { push @ops, '=='  }
        elsif ($op eq '!=' ) { push @ops, '!='  }
        elsif ($op eq 'eq' ) { push @ops, 'eq'  }
        elsif ($op eq 'ne' ) { push @ops, 'ne'  }
        elsif ($op eq '<'  ) { push @ops, '<'   }
        elsif ($op eq '<=' ) { push @ops, '<='  }
        elsif ($op eq '>'  ) { push @ops, '>'   }
        elsif ($op eq '>=' ) { push @ops, '>='  }
        elsif ($op eq 'lt' ) { push @ops, 'lt'  }
        elsif ($op eq 'le' ) { push @ops, 'le'  }
        elsif ($op eq 'gt' ) { push @ops, 'gt'  }
        elsif ($op eq 'ge' ) { push @ops, 'ge'  }
    }
    return $opds[0] unless @ops;
    my @res;
    my $lastopd;
    my ($opd1, $opd2);
    while (@ops) {
        my $op = pop @ops;
        if (defined($lastopd)) {
            $opd2 = $lastopd;
            $opd1 = pop @opds;
        } else {
            $opd2 = pop @opds;
            $opd1 = pop @opds;
        }
        if (@res) {
            @res = ("("._comparison1($opd1, $op, $opd2)." ? ", @res, " : false)");
        } else {
            push @res, _comparison1($opd1, $op, $opd2);
        }
        $lastopd = $opd1;
    }
    join "", @res;
}

sub rule_bit_shift {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '>>') { push @res, " >> $term" }
        elsif ($op eq '<<') { push @res, " << $term" }
    }
    join "", grep {defined} @res;
}

sub rule_add {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '.') { @res = ("'' + ", @res, " + $term") }
        if    ($op eq '+') { push @res, " + $term" }
        if    ($op eq '-') { push @res, " - $term" }
    }
    join "", grep {defined} @res;
}

sub rule_mult {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, shift @{$match->{operand}};
    for my $term (@{$match->{operand}}) {
        my $op = shift @{$match->{op}//=[]};
        last unless $op;
        if    ($op eq '*') { push @res, " * $term" }
        if    ($op eq '/') { push @res, " / $term" }
        if    ($op eq '%') { push @res, " % $term" }
        if    ($op eq 'x') { @res = ("(new Array(1 + $term).join(", @res, "))") }
    }
    join "", grep {defined} @res;
}

sub rule_unary {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, $match->{operand};
    for my $op (reverse @{$match->{op}//=[]}) {
        last unless $op;
        # use paren because --x or ++x is interpreted as pre-decrement/increment
        if    ($op eq '!') { @res = ("!(", @res, ")") }
        if    ($op eq '-') { @res = ("-(", @res, ")") }
        if    ($op eq '~') { @res = ("~(", @res, ")") }
    }
    join "", grep {defined} @res;
}

sub rule_power {
    my ($self, %args) = @_;
    my $match = $args{match};
    my @res;
    push @res, pop @{$match->{operand}};
    for my $term (reverse @{$match->{operand}}) {
        @res = ("Math.pow($term, ", @res, ")");
    }
    join "", grep {defined} @res;
}

sub rule_subscripting_var {
    my ($self, %args) = @_;
    $self->rule_subscripting_expr(%args);
}

sub rule_subscripting_expr {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $opd = $match->{operand};
    my @ss = @{$match->{subscript}//=[]};
    return $opd unless @ss;
    my $res;
    for my $s (@ss) {
        $opd = $res if defined($res);
        $res = $opd . "[$s]";
    }
    $res;
}

sub rule_array {
    my ($self, %args) = @_;
    my $match = $args{match};
    "[" . join(", ", @{ $match->{element} }) . "]";
}

sub rule_hash {
    my ($self, %args) = @_;
    my $match = $args{match};
    "{" . join(", ", @{ $match->{pair} }). "}";
}

sub rule_undef {
    "null";
}

sub rule_squotestr {
    my ($self, %args) = @_;
    join(" + ",
         map { $self->_quote($_->{value}) }
             @{ $self->parse_squotestr($args{match}{part}) });
}

sub rule_dquotestr {
    my ($self, %args) = @_;
    my @tmp =
        map { $_->{type} eq 'VAR' ?
                  $self->rule_var(match=>{var=>$_->{value}}) :
                      $self->_quote($_->{value})
              }
            @{ $self->parse_dquotestr($args{match}{part}) };
    if (@tmp > 1) {
        "(". join(" + ", @tmp) . ")[0]";
    } else {
        $tmp[0];
    }
}

sub rule_bool {
    my ($self, %args) = @_;
    my $match = $args{match};
    if ($match->{bool} eq 'true') { "true" } else { "false" }
}

sub rule_num {
    my ($self, %args) = @_;
    my $match = $args{match};
    if    ($match->{num} eq 'inf') { 'Infinity' }
    elsif ($match->{num} eq 'nan') { 'NaN' }
    else                           { $match->{num}+0 }
}

sub rule_var {
    my ($self, %args) = @_;
    my $match = $args{match};
    if ($self->hook_var) {
        my $res = $self->hook_var->($match->{var});
        return $res if defined($res);
    }
    return "$match->{var}";
}

sub rule_func {
    my ($self, %args) = @_;
    my $match = $args{match};
    my $f = $match->{func_name};
    my $args = $match->{args};
    if ($self->hook_func) {
        my $res = $self->hook_func->($f, @$args);
        return $res if defined($res);
    }
    my $fmap = $self->func_mapping->{$f};
    $f = $fmap if $fmap;
    my $fc = substr($f, 0, 1);
    if ($fc eq '.') {
        my $invoc = shift @$args;
        return "($invoc)$f(".join(", ", @$args).")";
    } elsif ($fc eq ':') {
        my $invoc = shift @$args;
        my $prop = substr($f, 1, length($f)-1);
        return "($invoc).$prop";
    } else {
        return "$f(".join(", ", @$args).")";
    }
}

sub _map_grep_usort {
    my ($self, $which, %args) = @_;
    my $match = $args{match};
    my $ary = $match->{array};
    my $expr = $match->{expr};

    my $uuid = $self->new_marker('subexpr', $expr);
    if ($which eq 'map') {
        return "($ary).map(function(_){ return (TODO-$uuid); })";
    } elsif ($which eq 'grep') {
        return "($ary).filter(function(_){ return (TODO-$uuid); })";
    } elsif ($which eq 'usort') {
        return "($ary).sort(function(a, b){ return (TODO-$uuid); })";
    }
}

sub rule_func_map {
    my ($self, %args) = @_;
    $self->_map_grep_usort('map', %args);
}

sub rule_func_grep {
    my ($self, %args) = @_;
    $self->_map_grep_usort('grep', %args);
}

sub rule_func_usort {
    my ($self, %args) = @_;
    $self->_map_grep_usort('usort', %args);
}

sub rule_parenthesis {
    my ($self, %args) = @_;
    my $match = $args{match};
    "(" . $match->{answer} . ")";
}

sub expr_preprocess {}

sub expr_postprocess {
    my ($self, %args) = @_;
    my $result = $args{result};
    $result;
}

# can't use regex here (perl segfaults), at least in 5.10.1, because
# we are in one big re::gr regex.
sub _quote {
    my ($self, $str) = @_;
    my @c;
    for my $c (split '', $str) {
        my $o = ord($c);
        if    ($c eq '"') { push @c, '\\"' }
        elsif ($c eq "\\") { push @c, "\\\\" }
        elsif ($o >= 32 && $o <= 127) { push @c, $c }
        elsif ($o > 255) { push @c, sprintf("\\u%04x", $o) }
        else  { push @c, sprintf("\\x%02x", $o) }
    }
    '"' . join("", @c) . '"';
}

sub compile {
    require Language::Expr::Parser;

    my ($self, $expr) = @_;
    my $res = Language::Expr::Parser::parse_expr($expr, $self);
    for my $m (@{ $self->markers }) {
        my $type = $m->[0];
        next unless $type eq 'subexpr';
        my $uuid = $m->[1];
        my $subexpr = $m->[2];
        my $subres = Language::Expr::Parser::parse_expr($subexpr, $self);
        $res =~ s/TODO-$uuid/$subres/g;
    }
    $self->markers([]);
    $res;
}

1;
# ABSTRACT: Compile Language::Expr expression to JavaScript

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr::Compiler::js - Compile Language::Expr expression to JavaScript

=head1 VERSION

This document describes version 0.29 of Language::Expr::Compiler::js (from Perl distribution Language-Expr), released on 2016-07-03.

=head1 SYNOPSIS

 use Language::Expr::Compiler::js;
 my $jsc = Language::Expr::Compiler::js->new;
 print $jsc->compile('map({$_**2}, [1, 2, 3])'); # prints: [1, 2, 3].map(function(_){ Math.pow(_, 2) })

 # map Expr function to JS function/method/property
 $jsc->func_mapping->{ceil} = 'Math.ceil';
 $jsc->func_mapping->{uc} = '.toUpperCase';
 $jsc->func_mapping->{length} = ':length';
 print $jsc->compile(q{uc("party like it's ") . ceil(1998.9)}); # prints: "party like it's ".toUpperCase() + Math.ceil(1998.9)

=head1 DESCRIPTION

Compiles Language::Expr expression to JavaScript code. Some notes:

=over 4

=item * JavaScript version

This compiler emits JavaScript 1.8.1 code (it uses several Array methods like
map() and filter() [supported since JavaScript 1.6], 'let' lexical variables
[supported since JavaScript 1.7] and native JSON [supported since JavaScript
1.8.1]).

To test emitted JavaScript code, we use Node.js.

=item * JavaScript-ness

The emitted JS code will follow JavaScript's weak typing and coercion rules,
e.g. Expr '1+"2"' will simply be translated to JavaScript '1+"2"' and will
result in "12".

=item * Variables by default simply use JavaScript variables.

E.g. $a becomes a, and so on. Be careful not to make variables which are invalid
in JavaScript, e.g. $.. or ${foo/bar}.

You can customize this behaviour by subclassing rule_var() or by providing a
hook_var() (see documentation in L<Language::Expr::Compiler::Base>).

=item * Functions by default simply use Javascript functions.

Except those mentioned in B<func_mapping> (e.g. rand() becomes Math.rand() if
func_mapping->{rand} is 'Math.rand'). You can also map to JavaScript method
(using '.meth' syntax) and property (using ':prop' syntax).

You can customize this behaviour by subclassing rule_func() or by providing a
hook_func() (see documentation in L<Language::Expr::Compiler::Base>).

=back

=for Pod::Coverage ^(rule|expr)_.+

=head1 METHODS

=head2 compile($expr) => $js_code

Convert Language::Expr expression into JavaScript code. Dies if there is syntax
error in expression.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Language-Expr>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Language-Expr>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Language-Expr>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
