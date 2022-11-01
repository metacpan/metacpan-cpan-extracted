package Devel::Chitin::OpTree::BINOP;
use base 'Devel::Chitin::OpTree::UNOP';

our $VERSION = '0.21';

use strict;
use warnings;

use Carp;

# probably an ex-lineseq with 2 kids
*pp_lineseq = \&Devel::Chitin::OpTree::LISTOP::pp_lineseq;

sub last {
    shift->{children}->[-1];
}

sub pp_sassign {
    my($self, %params) = @_;

    if ($self->is_null
        and
        $self->first->op->name eq 'undef'
        and
        ( $self->last->is_null and $self->last->_ex_name eq 'pp_padsv')
    ) {
        # This is an optimised undef-assignment
        $self->first->deparse();
    } else {
        # normally, the args are ordered: value, variable
        my($var, $value) = $params{is_swapped}
                            ? ($self->first->deparse, $self->last->deparse)
                            : ($self->last->deparse, $self->first->deparse);
        return join(' = ', $var, $value);
    }
}

sub pp_aassign {
    my $self = shift;

    my $container;
    if ($self->is_null
        and
            # assigning-to is optimized away
            $self->last->is_null and $self->last->_ex_name eq 'pp_list'
            and
            $self->last->children->[1]->is_null and $self->last->children->[1]->is_array_container
        and
            # value is an in-place sort: @a = sort @a;
            $self->first->is_null and $self->first->_ex_name eq 'pp_list'
            and
            $self->first->children->[1]->op->name eq 'sort'
            and
            $self->first->children->[1]->op->private & B::OPpSORT_INPLACE
    ) {
        # since we're optimized away, we can't find out what variable we're
        # assigning .  It's the variable the sort is acting on.
        $container = $self->first->children->[1]->children->[-1]->deparse;

    } else {
        $container = $self->last->deparse;
    }

    "$container = " . $self->first->deparse;
}

sub pp_refassign {
    my $self = shift;

    my $left;
    if ($self->op->flags & B::OPf_STACKED) {
        $left = $self->last->deparse;
    } else {
        $left = $self->_padname_sv->PV;
    }

    my $right = $self->first->deparse;
    "\\${left} = $right";
}

sub pp_list {
    my $self = shift;

    # 'list' is usually a LISTOP, but if we got here's it's because we're
    # actually a 'null' ex-list, and there's only one item in the list.
    # $self->first will be a pushmark
    # @list = @other_list;
    # We can emit a value without surrounding parens unless it's a scalar
    # being assigned to

    my $contents = $self->last->deparse;

    if ($self->last->is_scalar_container
        or
        $self->is_list_reference_alias
    ) {
        "(${contents})";

    } else {
        $contents;
    }
}

foreach my $cond ( [lt => '<'],
                   [le => '<='],
                   [gt => '>'],
                   [ge => '>='],
                   [eq => '=='],
                   [ne => '!='],
                   [ncmp => '<=>'],
                   [slt => 'lt'],
                   [sle => 'le'],
                   [sgt => 'gt'],
                   [sge => 'ge'],
                   [seq => 'eq'],
                   [sne => 'ne'],
                   [scmp => 'cmp'],
                )
{
    my $expr = ' ' . $cond->[1] . ' ';
    my $sub = sub {
        my $self = shift;
        return join($expr, $self->first->deparse, $self->last->deparse);
    };
    my $subname = 'pp_' . $cond->[0];
    no strict 'refs';
    *$subname = $sub;
}

sub pp_stringify {
    my $self = shift;

    unless ($self->first->op->name eq 'null'
            and
            $self->first->_ex_name eq 'pp_pushmark'
    ) {
        die "unknown stringify ".$self->first->op->name;
    }

    my $children = $self->children;
    unless (@$children == 2) {
        die "expected 2 children but got " . scalar(@$children)
            . ': ' . join(', ', map { $_->op->name } @$children);
    }

    if ($self->is_null
        and $self->op->private & B::OPpTARGET_MY
        and $children->[1]->op->name eq 'concat'
    ) {
        $children->[1]->deparse(skip_concat => 1, force_quotes => ['qq(', ')']);

    } else {
        my $target = $self->_maybe_targmy;

        "${target}qq(" . $children->[1]->deparse(skip_concat => 1, skip_quotes => 1) . ')';
    }
}

sub pp_concat {
    my $self = shift;
    my %params = @_;

    my $first = $self->first;
    if ($self->op->flags & B::OPf_STACKED
        and
        $first->op->name ne 'concat'
    ) {
        # This is an assignment-concat: $a .= 'foo'
        $first->deparse . ' .= ' . $self->last->deparse;

    } else {
        my $target = $self->_maybe_targmy;
        my $concat_str = join($params{skip_concat} ? '' : ' . ',
                        $first->deparse(%params, $params{force_quotes} ? (skip_quotes => 1) : ()),
                        $self->last->deparse(%params));
        if ($params{force_quotes}) {
            $concat_str = join($concat_str, @{$params{force_quotes}});
        }
        $target . $concat_str;
    }
}

sub pp_reverse {
    # a BINOP reverse is only acting on a single item
    # 0th child is pushmark, skip it
    'reverse(' . shift->last->deparse . ')';
}

sub pp_leaveloop {
    my $self = shift;

    if (my $deparsed = $self->_deparse_postfix_while) {
        return $deparsed;
    }

    my $enterloop = $self->first;
    if ($enterloop->op->name eq 'enteriter') {
        return $self->_deparse_foreach;

    #} elsif ($enterloop->op->name eq 'entergiven') {
    #    return $self->_deparse_given;

    } else {
        return $self->_deparse_while_until;
    }
}

# Part of the reverted given/whereso/whereis from 5.27.7
#sub _deparse_given {
#    my $self = shift;
#
#    my $enter_op = $self->first;
#    my $topic_op = $enter_op->first;
#    my $topic = $topic_op->deparse;
#    my $block_content = $topic_op->sibling->deparse(omit_braces => 1);
#
#    "given ($topic) {$block_content}";
#}

sub _deparse_while_until {
    my $self = shift;

    # while loops are structured like this:
    # leaveloop
    #   enterloop
    #   null
    #     and/or
    #       null
    #         condition
    #       lineseq
    #         loop contents
    my $condition_op = $self->last->first;  # the and/or
    my $enterloop = $self->first;
    my $loop_invocation = $condition_op->op->name eq 'and'
                            ? 'while'
                            : 'until';
    my $continue_content = '';
    my $loop_content;
    if ($enterloop->nextop->op->name eq 'unstack') {
        # no continue
        # loop contents are wrapped in a lineseq
        $loop_content = '{' . $self->_indent_block_text( $condition_op->other->deparse, force_multiline => 1 ) . '}';
    } else {
        # has continue
        # loop and continue contents are wrapped in scopes
        my $children = $condition_op->other->children;
        $loop_content = $children->[0]->deparse(force_multiline => 1);
        $continue_content = ' continue ' . $children->[1]->deparse(force_multiline => 1);
    }

    my $loop_condition = $condition_op->first->deparse;
    if ($condition_op->op->name eq 'and') {
        $loop_invocation = 'while';

    } else {
        $loop_invocation = 'until';
        $loop_condition =~ s/^!//;
    }

    "$loop_invocation ($loop_condition) ${loop_content}${continue_content}";
}

sub _deparse_foreach {
    my $self = shift;
    # foreach loops look like this:
    # leaveloop
    #   enteriter
    #       pushmark
    #       list
    #           ... (iterate-over list)
    #       iteration variable
    #   null
    #       and
    #           iter
    #           lineseq
    #               loop contents
    my $enteriter = $self->first;

    my $list_op = $enteriter->children->[1];
    my $iter_list;
    if ($enteriter->op->flags & B::OPf_STACKED
             and
             $list_op->children->[2]
    ) {
        # range
        $iter_list = '(' . join(' .. ', map { $_->deparse } @{$list_op->children}[1,2]) . ')';

    } elsif ($list_op->is_null) {# and $enteriter->op->private & B::OPpITER_REVERSED) {
        # either foreach(reverse @list) or foreach (@list)
        $iter_list = $list_op->Devel::Chitin::OpTree::LISTOP::pp_list;

    } else {
        $iter_list = $list_op->deparse;
    }

    my $var_op = $enteriter->children->[2];
    my $var = $var_op
                ? '$' . $var_op->deparse(skip_sigil => 1)
                : $enteriter->pp_padsv;

    my $loop_content_op = $enteriter->sibling->first->first->sibling; # should be a lineseq
    my $loop_content = $loop_content_op->deparse;

    if ($loop_content_op->first->isa('Devel::Chitin::OpTree::COP')) {
        $loop_content = $self->_indent_block_text( $loop_content );
        "foreach $var $iter_list {$loop_content}";
    } else {
        Carp::croak("In postfix foreach, expected loop var '\$_', but got '$var'") unless $var eq '$_';
        "$loop_content foreach $iter_list"
    }
}

# leave is normally a LISTOP, but this happens when this is run
# in the debugger
# sort { ; } @list
# The leave is turned into a null:
# ex-leave
#   enter
#   stub
*pp_leave = \&Devel::Chitin::OpTree::LISTOP::pp_leave;

# from B::Concise
use constant DREFAV => 32;
use constant DREFHV => 64;
use constant DREFSV => 96;

sub pp_helem {
    my $self = shift;

    my $first = $self->first;
    my($hash, $key) = ($first->deparse, $self->last->deparse);
    if ($self->_is_chain_deref('rv2hv', DREFHV)) {
        # This is a dereference, like $a->{foo}
        substr($hash, 1) . '->{' . $key . '}';
    } else {
        substr($hash, 0, 1) = '$';
        "${hash}{${key}}";
    }
}

sub _is_chain_deref {
    my($self, $expected_first_op, $expected_flag) = @_;
    my $child = $self->first;
    return unless $child->isa('Devel::Chitin::OpTree::UNOP');

    $child->op->name eq $expected_first_op
    and
    $child->first->op->private & $expected_flag
}

sub pp_aelem {
    my $self = shift;
    my $first = $self->first;

    my($array, $elt) = ($first->deparse, $self->last->deparse);
    if ($self->is_null
        and
        ($first->op->name eq 'aelemfast_lex' or $first->op->name eq 'aelemfast')
        and
        $self->last->is_null
    ) {
        $array;

    } elsif ($self->_is_chain_deref('rv2av', DREFAV)) {
        # This is a dereference, like $a->[1]
        substr($array, 1) . '->[' . $elt . ']';

    } else {
        substr($array, 0, 1) = '$';
        my $idx = $self->last->deparse;
        "${array}[${idx}]";
    }
}

sub pp_smartmatch {
    my $self = shift;
    $self->last->deparse;
}

sub pp_lslice {
    my $self = shift;

    my $list = $self->last->deparse(skip_parens => 1);
    my $idx = $self->first->deparse(skip_parens => 1);
    "($list)[$idx]";
}

# Operators
#               OP name         operator    targmy?
foreach my $a ( [ pp_add        => '+',     1 ],
                [ pp_i_add      => '+',     1 ],
                [ pp_subtract   => '-',     1 ],
                [ pp_i_subtract => '-',     1 ],
                [ pp_multiply   => '*',     1 ],
                [ pp_i_multiply => '*',     1 ],
                [ pp_divide     => '/',     1 ],
                [ pp_i_divide   => '/',     1 ],
                [ pp_modulo     => '%',     1 ],
                [ pp_i_modulo   => '%',     1 ],
                [ pp_pow        => '**',    1 ],
                [ pp_left_shift => '<<',    1 ],
                [ pp_right_shift => '>>',   1 ],
                [ pp_repeat     => 'x',     0 ],
                [ pp_bit_and    => '&',     0 ],
                [ pp_bit_or     => '|',     0 ],
                [ pp_bit_xor    => '^',     0 ],
                [ pp_xor        => 'xor',   0 ],
                [ pp_sbit_and   => '&.',    0 ],
                [ pp_sbit_or    => '|.',    0 ],
                [ pp_sbit_xor   => '^.',    0 ],
) {
    my($pp_name, $perl_name, $targmy) = @$a;
    my $sub = sub {
        my $self = shift;

        if ($self->op->flags & B::OPf_STACKED) {
            # This is an assignment op: +=
            my $first = $self->first->deparse;
            "$first ${perl_name}= " . $self->last->deparse;
        } else {
            my $target = $targmy ? $self->_maybe_targmy : '';
            $target . $self->first->deparse . " $perl_name " . $self->last->deparse;
        }
    };
    no strict 'refs';
    *$pp_name = $sub;
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::BINOP - Deparser class for binary OPs

=head1 DESCRIPTION

This package contains methods to deparse BINOPs (add, aelem, etc).

=head2 Methods

=over 4

=item last

Returns a L<Devel::Chitin::OpTree> instance for the second child of this node

=back

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
