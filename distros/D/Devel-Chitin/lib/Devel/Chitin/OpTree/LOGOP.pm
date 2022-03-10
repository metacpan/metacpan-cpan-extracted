package Devel::Chitin::OpTree::LOGOP;
use base 'Devel::Chitin::OpTree::UNOP';

our $VERSION = '0.19';

use strict;
use warnings;

sub other {
    shift->{children}->[1];
}

sub pp_entertry { '' }

sub pp_regcomp {
    my $self = shift;
    my %params = @_;

    my $rx_op = $self->first;
    my $rx_op_name = $rx_op->op->name;
    $rx_op = $rx_op->first if ($rx_op_name eq 'regcmaybe'
                                or $rx_op_name eq 'regcreset');

    my $deparsed;
    join('', $rx_op->deparse(skip_parens => 1,
                             skip_quotes => 1,
                             skip_concat => 1,
                             join_with => '',
                             %params));
}

sub pp_substcont {
    my $self = shift;
    join('', $self->first->deparse(skip_concat => 1, skip_quotes => 1));
}

# The arrangement looks like this
# mapwhile
#    mapstart
#        padrange
#        null
#            block-or-expr
#                ...
#            list-0
#            list-1
#            ...
sub pp_mapwhile {
    _deparse_map_grep(shift, 'map');
}

sub pp_grepwhile {
    _deparse_map_grep(shift, 'grep');
}

sub _deparse_map_grep {
    my($self, $function) = @_;

    my $mapstart = $self->first;
    my $children = $mapstart->children;

    my $block_or_expr = $mapstart->children->[1]->first;
    $block_or_expr = $block_or_expr->first if $block_or_expr->is_null;

    my @map_params = map { $_->deparse } @$children[2 .. $#$children];
    if ($block_or_expr->is_scopelike) {
        # map { ... } @list
        my $use_parens = (@map_params > 1 or substr($map_params[0], 0, 1) ne '@');

        "${function} " . $block_or_expr->deparse . ' '
            . ($use_parens ? '(' : '')
            . join(', ', @map_params)
            . ($use_parens ? ')' : '');

    } else {
        # map(expr, @list)

        "${function}("
            . $block_or_expr->deparse
            . ', '
            . join(', ', @map_params)
        . ')';
    }
}

sub pp_and {
    my $self = shift;
    my $left = $self->first->deparse;
    my $right = $self->other->deparse(force_multiline => 1);
    if ($self->is_if_statement) {
        $left = _format_if_conditional($left);
        "if ($left) $right";

    } elsif ($self->is_postfix_if) {
        "$right if $left";

    } else {
        "$left && $right";
    }
}

sub pp_or {
    my $self = shift;
    if ($self->is_if_statement) {
        my $condition;
        if ($self->first->is_null
            and $self->first->_ex_name eq 'pp_not'
        ) {
            # starting with 5.12
            $condition = $self->first->first->deparse;
        } else {
            # perl 5.10.1 and older
            $condition = $self->first->deparse;
        }
        $condition = _format_if_conditional($condition);
        my $code = $self->other->deparse(force_multiline => 1);
        "unless ($condition) $code";

    } elsif ($self->is_postfix_if) {
        $self->other->deparse . ' unless ' . $self->first->deparse;

    } else {
        $self->first->deparse . ' || ' . $self->other->deparse;
    }
}

sub pp_dor {
    my $self = shift;
    $self->first->deparse . ' // ' . $self->other->deparse;
}

sub _format_if_conditional {
    my $code = shift;
    if (index($code, ';') == 0) {
        substr($code, 1);
    } else {
        $code;
    }
}

sub pp_andassign { _and_or_assign(shift, '&&=') }
sub pp_orassign { _and_or_assign(shift, '||=') }
sub pp_dorassign { _and_or_assign(shift, '//=') }
sub _and_or_assign {
    my($self, $op) = @_;
    my $var = $self->first->deparse;
    my $value = $self->other->first->deparse;  # skip over sassign (other)
    join(' ', $var, $op, $value);
}

sub pp_cond_expr {
    my $self = shift;
    my $children = $self->children;

    my($cond, $true, $false) = @$children;
    my $cond_code = $cond->deparse();
    my $true_code = $true->deparse(force_multiline => 1);
    my $false_code = $false->deparse(force_multiline => 1);

    if ($true->is_scopelike and $false->is_scopelike) {
        $cond_code = _format_if_conditional($cond_code);
        "if ($cond_code) $true_code else $false_code";

    } elsif ($true->is_scopelike
            and $false->is_null
            and ( $false->first->op->name eq 'cond_expr' or $false->first->op->name eq 'and' )
    ) {
        $cond_code = _format_if_conditional($cond_code);
        "if ($cond_code) $true_code els$false_code";

    } else {
        $cond->deparse . ' ? ' . $true->deparse . ' : ' . $false->deparse;
    }
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::LOGOP - Deparser class for logical OPs

=head1 DESCRIPTION

This package contains methods to deparse LOGOPs (and, grepwhile, etc).

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
