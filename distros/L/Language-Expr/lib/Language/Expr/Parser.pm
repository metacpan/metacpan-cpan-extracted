package Language::Expr::Parser;

our $DATE = '2016-07-03'; # DATE
our $VERSION = '0.29'; # VERSION

use 5.010001;
# now can't compile with this on?
#use strict;
#use warnings;

use Regexp::Grammars;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_expr);

my $MAX_LEVELS = 3;

# WARN: this is not thread-safe!?
our $obj;

sub parse_expr {
    my ($str, $obj_arg, $level) = @_;

    $level //= 0;
    die "Recursion level ($level) too deep (max $MAX_LEVELS)" if $level >= $MAX_LEVELS;

    # WARN: this is not thread-safe!?
    local $subexpr_stack = [];

    # create not just 1 but 0..$MAX_LEVELS-1 of grammar objects, each
    # for each recursion level (e.g. for map/grep/usort), fearing that
    # the grammar is not reentrant. but currently no luck yet, still
    # results in segfault/bus error.

    state $grammars = [ map { qr{
        ^\s*<answer>\s*$

        <rule: answer>
            <MATCH=or_xor>

# precedence level: left     =>
        <rule: pair>
            <key=(\w++)> =\> <value=answer>
            (?{ $MATCH = $obj->rule_pair_simple(match=>\%MATCH) })
          | <key=squotestr> =\> <value=answer>
            (?{ $MATCH = $obj->rule_pair_string(match=>\%MATCH) })
          | <key=dquotestr> =\> <value=answer>
            (?{ $MATCH = $obj->rule_pair_string(match=>\%MATCH) })

# precedence level: left     || // ^^
        <rule: or_xor>
            <[operand=ternary]> ** <[op=(\|\||//|\^\^)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_or_xor(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: right    ?:
        <rule: ternary>
            <[operand=and]> ** <[op=(\?|:)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    unless (@{ $MATCH{op} } == 2 &&
                            $MATCH{op}[0] eq '?' &&
                            $MATCH{op}[1] eq ':') {
                        die "Invalid syntax for ternary, please use X ? Y : Z syntax";
                    }
                    $MATCH = $obj->rule_ternary(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left     &&
        <rule: and>
            <[operand=bit_or_xor]> ** <[op=(&&)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_and(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left     | ^
        <rule: bit_or_xor>
            <[operand=bit_and]> ** <[op=(\||\^)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_bit_or_xor(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left     &
        <rule: bit_and>
            <[operand=comparison3]> ** <[op=(&)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_bit_and(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

            # NOTE: \x3c = "<", \x3e = ">"

# precedence level: nonassoc (currently the grammar says assoc) <=> cmp
        <rule: comparison3>
            <[operand=comparison]> ** <[op=(\x3c=\x3e|cmp)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_comparison3(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left == != eq ne < > <= >= ge gt le lt
        <rule: comparison>
            <[operand=bit_shift]> ** <[op=(==|!=|eq|ne|\x3c=?|\x3e=?|lt|gt|le|ge)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_comparison(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left     << >>
        <rule: bit_shift>
            <[operand=add]> ** <[op=(\x3c\x3c|\x3e\x3e)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_bit_shift(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left     + - .
        <rule: add>
            <[operand=mult]> ** <[op=(\+|-|\.)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_add(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left     * / % x
        <rule: mult>
            <[operand=unary]> ** <[op=(\*|/|%|x)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_mult(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: right    ! ~ unary+ unary-
        <rule: unary>
            <[op=(!|~|\+|-)]>* <operand=power>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_unary(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand};
                }
            })

# precedence level: right    **
        <rule: power>
            <[operand=subscripting]> ** <[op=(\*\*)]>
            (?{
                if ($MATCH{op} && @{ $MATCH{op} }) {
                    $MATCH = $obj->rule_power(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand}[0];
                }
            })

# precedence level: left    hash[s], array[i]
        <rule: subscripting>
            <operand=var0> <[subscript]>*
            (?{
                if ($MATCH{subscript} && @{ $MATCH{subscript} }) {
                    $MATCH = $obj->rule_subscripting_var(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand};
                }
            })
          | <operand=term> <[subscript]>*
            (?{
                if ($MATCH{subscript} && @{ $MATCH{subscript} }) {
                    $MATCH = $obj->rule_subscripting_expr(match=>\%MATCH);
                } else {
                    $MATCH = $MATCH{operand};
                }
            })

        <rule: subscript>
              \[ <MATCH=term> \]

# precedence level: left     term (variable, str/num literals, func(), (paren))
        <rule: term>
            <MATCH=func>
          | <MATCH=var0>
          | <MATCH=str0>
          | <MATCH=undef>
          | <MATCH=num0>
          | <MATCH=bool0>
          | <MATCH=array>
          | <MATCH=hash>
          | \( <answer> \)
            (?{ $MATCH = $obj->rule_parenthesis(match=>\%MATCH) // $MATCH{answer} })

        <rule: array>
            \[ \]
            (?{ $MATCH = $obj->rule_array(match=>{element=>[]}) })
          | \[ <[element=answer]> ** (,) \]
            (?{ $MATCH = $obj->rule_array(match=>\%MATCH) })

        <rule: hash>
            \{ \}
            (?{ $MATCH = $obj->rule_hash(match=>{pair=>[]}) })
          | \{ <[pair]> ** (,) \}
            (?{ $MATCH = $obj->rule_hash(match=>\%MATCH) })

        <token: undef>
            undef
            (?{ $MATCH = $obj->rule_undef() })

        <token: bool0>
            <bool=(true|false)>
            (?{ $MATCH = $obj->rule_bool(match=>\%MATCH) })

        <token: num0>
            <sign0a=([+-]?+)> 0x <num0a=([0-9A-Fa-f]++)>
            (?{ $MATCH = $obj->rule_num(match=>{num=>
                ($MATCH{sign0a} eq '-' ? -1:1) * hex($MATCH{num0a})}) })
          | <sign0b=([+-]?+)> 0o <num0b=([0-7]++)>
            (?{ $MATCH = $obj->rule_num(match=>{num=>
                ($MATCH{sign0b} eq '-' ? -1:1) * oct($MATCH{num0b})}) })
          | <sign0c=([+-]?+)> 0b <num0c=([0-1]++)>
            (?{ $MATCH = $obj->rule_num(match=>{num=>
                ($MATCH{sign0c} eq '-' ? -1:1) * oct("0b".$MATCH{num0c})}) })
          | <num0c=( [+-]?\d++(?:\.\d++)?+ | inf | nan)>
            (?{ $MATCH = $obj->rule_num(match=>{num=>$MATCH{num0c}}) })

        <rule: str0>
            <MATCH=squotestr>
          | <MATCH=dquotestr>

        <token: squotestr>
            '<[part=(\\\\|\\'|\\|[^\\']++)]>*'
            (?{ $MATCH = $obj->rule_squotestr(match=>\%MATCH) })

        <token: dquotestr>
            "<[part=([^"\044\\]++|\$\.\.?|\$\w+|\$\{[^\}]+\}|\\\\|\\'|\\"|\\[tnrfbae\$]|\\[0-7]{1,3}|\\x[0-9A-Fa-f]{1,2}|\\x\{[0-9A-Fa-f]{1,4}\}|\\)]>*"
            (?{ $MATCH = $obj->rule_dquotestr(match=>\%MATCH) })

        <rule: var0>
            \$ <var=(\w++(?:::\w+)*+)>
            (?{ $MATCH = $obj->rule_var(match=>\%MATCH) })
          | \$ \{ <var=([^\}]++)> \}
            (?{ $MATCH = $obj->rule_var(match=>\%MATCH) })

        <rule: func>
            <func_name=([A-Za-z_]\w*+)> \( \)
            (?{ $MATCH = $obj->rule_func(match=>{func_name=>$MATCH{func_name}, args=>[]}) })
          | <func_name=(map|grep|usort)> \( \{ <expr=answer> \} (?{ push @$subexpr_stack, $CONTEXT }), <input_array=answer> \)
            (?{ my $meth = "rule_func_$MATCH{func_name}";
                $MATCH = $obj->$meth(match=>{expr=>pop(@$subexpr_stack), array=>$MATCH{input_array}}) })
          | <func_name=([A-Za-z_]\w*+)> \( <[args=answer]> ** (,) \)
            (?{ $MATCH = $obj->rule_func(match=>\%MATCH) })

    }xms } 0..($MAX_LEVELS-1)];

    $obj = $obj_arg;
    $obj_arg->expr_preprocess(string_ref => \$str, level => $level);
    #print "DEBUG: Parsing expression `$str` with grammars->[$level] ...\n";
    die "Invalid syntax in expression `$str`" unless $str =~ $grammars->[$level];
    $obj_arg->expr_postprocess(result => $/{answer});
}

1;
# ABSTRACT: Parse Language::Expr expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Expr::Parser - Parse Language::Expr expression

=head1 VERSION

This document describes version 0.29 of Language::Expr::Parser (from Perl distribution Language-Expr), released on 2016-07-03.

=head1 KNOWN BUGS

=over 4

=item * Ternary operator is not chainable yet.

=back

=head1 METHODS

=head2 parse_expr($str, $obj)

Parse expression in $str. Will call various rule_*() methods in $obj.

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
