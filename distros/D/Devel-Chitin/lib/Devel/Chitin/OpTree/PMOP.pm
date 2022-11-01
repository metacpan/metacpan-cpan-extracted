package Devel::Chitin::OpTree::PMOP;
use base 'Devel::Chitin::OpTree::LISTOP';

our $VERSION = '0.21';

use B qw(PMf_CONTINUE PMf_ONCE PMf_GLOBAL PMf_MULTILINE PMf_KEEP PMf_SINGLELINE
         PMf_EXTENDED PMf_FOLD OPf_KIDS);

use strict;
use warnings;

sub pp_qr {
    shift->_match_op('qr')
}

sub pp_match {
    my $self = shift;

    $self->_get_bound_variable_for_match
        . $self->_match_op('m');
}

sub pp_pushre {
    shift->_match_op('', @_);
}

sub _get_bound_variable_for_match {
    my $self = shift;

    my($var, $op) = ('', '');
    if ($self->op->flags & B::OPf_STACKED) {
        $var = $self->first->deparse;
        $op = $self->parent->op->name eq 'not'
                    ? ' !~ '
                    : ' =~ ';
    } elsif (my $targ = $self->op->targ) {
        $var = $self->_padname_sv($targ)->PV;
        $op = ' =~ ';

    }
    $var . $op;
}

sub pp_subst {
    my $self = shift;

    my @children = @{ $self->children };

    # children always come in this order, though they're not
    # always present: bound-variable, replacement, regex
    my $var = $self->_get_bound_variable_for_match;

    shift @children if $self->op->flags & B::OPf_STACKED; # bound var was the first child

    my $re;
    if ($children[1] and $children[1]->op->name eq 'regcomp') {
        $re = $children[1]->deparse(in_regex => 1,
                                    regex_x_flag => $self->op->pmflags & PMf_EXTENDED);
    } else {
        $re = $self->op->precomp;
    }

    my $replacement = $children[0]->deparse(skip_quotes => 1, skip_concat => 1);

    my $flags = _match_flags($self);
    "${var}s/${re}/${replacement}/${flags}";
}

sub _match_op {
    my($self, $operator, %params) = @_;

    my $re = $self->op->precomp;
    if (defined($re)
        and $self->op->name eq 'pushre'
        and $self->op->flags & B::OPf_SPECIAL
    ) {
        return q(' ') if $re eq '\s+';
        return q('') if $re eq '';
    }

    my $children = $self->children;
    foreach my $child ( @$children ) {
        if ($child->op->name eq 'regcomp') {
            $re = $child->deparse(in_regex => 1,
                                  regex_x_flag => $self->op->pmflags & PMf_EXTENDED);
            last;
        }
    }

    my $flags = _match_flags($self);

    my $delimiter = exists($params{delimiter}) ? $params{delimiter} : '/';

    join($delimiter, $operator, $re, $flags);
}

my @MATCH_FLAGS;
BEGIN {
    @MATCH_FLAGS = ( PMf_CONTINUE,      'c',
                     PMf_ONCE,          'o',
                     PMf_GLOBAL,        'g',
                     PMf_FOLD,          'i',
                     PMf_MULTILINE,     'm',
                     PMf_KEEP,          'o',
                     PMf_SINGLELINE,    's',
                     PMf_EXTENDED,      'x',
                   );
    if ($^V ge v5.10.0) {
        push @MATCH_FLAGS, B::RXf_PMf_KEEPCOPY(), 'p';
    }
    if ($^V ge v5.22.0) {
        push @MATCH_FLAGS, B::RXf_PMf_NOCAPTURE(), 'n';
    }
}

sub _match_flags {
    my $self = shift;

    my $match_flags = $self->op->pmflags;
    my $flags = '';
    for (my $i = 0; $i < @MATCH_FLAGS; $i += 2) {
        $flags .= $MATCH_FLAGS[$i+1] if ($match_flags & $MATCH_FLAGS[$i]);
    }
    $flags;
}

sub _resolve_split_expr {
    my $self = shift;

    return $self->_match_op('', @_);
}

sub _resolve_split_target {
    my $self = shift;

    my $target = '';
    if ($self->op->private & B::OPpSPLIT_ASSIGN()) {
        if ($self->op->flags & B::OPf_STACKED()) {
            # target is encoded as the last child op
            $target = $self->children->[-1]->deparse;

        } elsif ($self->op->private & B::OPpSPLIT_LEX()) {
            $target = $self->_padname_sv($self->op->pmreplroot)->PV;

        } else {
            my $gv = $self->op->pmreplroot();
            $gv = $self->_padval_sv($gv) if !ref($gv);
            $target = '@' . $self->_gv_name($gv);
        }
    }
    $target .= ' = ' if $target;
}

sub _resolve_split_target_pmop { $_[0] }

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::PMOP - Deparser class for patten-matching OPs

=head1 DESCRIPTION

This package contains methods to deparse PMOPs (qr, match, etc)

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
