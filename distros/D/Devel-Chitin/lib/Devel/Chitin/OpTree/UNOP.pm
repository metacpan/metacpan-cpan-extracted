package Devel::Chitin::OpTree::UNOP;
use base 'Devel::Chitin::OpTree';

our $VERSION = '0.16';

use strict;
use warnings;

sub first {
    shift->{children}->[0];
}

sub pp_leavesub {
    my $self = shift;
    $self->first->deparse;
}

foreach my $d ( [ pp_leavegiven => 'given' ],
                [ pp_leavewhen => 'when' ],
) {
    my($pp_name, $perl_name) = @$d;
    my $sub = sub {
        my $self = shift;
        my $enter = $self->first;  # entergiven/enterwhen
        if ($enter->other) {
            my $term = $enter->first->deparse;
            $self->_enter_scope;
            my $block = $enter->other->deparse;
            $self->_leave_scope;
            "$perl_name ($term) $block";
        } else {
            'default ' . $enter->first->deparse;
        }
    };
    no strict 'refs';
    *$pp_name = $sub;
}


# Normally, pp_list is a LISTOP, but this happens when a pp_list is turned
# into a pp_null by the optimizer, and it has one child
sub pp_list {
    my $self = shift;
    $self->first->deparse;
}

sub pp_refgen {
    my $self = shift;
    my $first = $self->first;
    my $anoncode;
    if ($first->is_null and $first->_ex_name eq 'pp_list') {
        # Perl 5.22 puts the anoncode OP first, older Perls have a pushmark
        # then the anoncode
        foreach my $op ( @{ $first->children } ) {
            if ($op->op->name eq 'anoncode') {
                $anoncode = $op;
                last;
            }
        }
    }

    if ($anoncode) {
        my $subref = $self->_padval_sv($anoncode->op->targ);
        my $deparser = Devel::Chitin::OpTree->build_from_location($subref->object_2svref);
        my $deparsed = $deparser->deparse;
        if ($deparsed =~ m/\n/) {
            return join('', 'sub {', $self->_indent_block_text($deparsed), '}');
        } else {
            return join('', 'sub { ', $deparsed, ' }');
        }

    } elsif ($first->is_null
             and $first->_ex_name eq 'pp_list'
             and @{$first->children} == 2
             and $first->children->[-1]->is_array_container
             and $first->children->[-1]->op->flags & B::OPf_REF
    ) {
        # This catches the case of \@list.  Falling through to the default
        # case, it'll deparse as \(@list)
        '\\' . $first->children->[-1]->deparse;

    } else {
        '\\' . $first->deparse;
    }
}
*pp_srefgen = \&pp_refgen;

sub pp_rv2sv { '$' . shift->first->deparse }
sub pp_rv2av { '@' . shift->first->deparse }
sub pp_rv2hv { '%' . shift->first->deparse }
sub pp_rv2cv {
    my $self = shift;
    # The null case is the most common.  not-null happens
    # with undef(&function::name) and generates this optree:
    # undef
    #   rv2cv
    #     ex-list
    #       ex-pushmark
    #       ex-rv2cv
    #           gv(*function::name)
    # We only want the sigil prepended once
    my $sigil = $self->is_null ? '' : '&';
    $sigil . $self->first->deparse;
}

sub pp_rv2gv {
    my($self, %params) = @_;
    if ($self->op->flags & B::OPf_SPECIAL    # happens in syswrite($fh, ...) and other I/O functions
        or
        $self->op->private & B::OPpDEREF_SV  # happens in select($fh)
        or
        $params{skip_sigil}  # this is a hack for "print F ..." to deparse correctly :(
    ) {
        return $self->first->deparse;
    } else {
        return '*' . $self->first->deparse;
    }
}

sub pp_entersub {
    my $self = shift;

    my @params_ops;
    if ($self->first->op->flags & B::OPf_KIDS) {
        # normal sub call
        # first is a pp_list containing a pushmark, followed by the arg
        # list, followed by the sub name
        (undef, @params_ops) = @{ $self->first->children };

    } elsif ($self->first->op->name eq 'pushmark'
            or
            $self->first->op->name eq 'padrange'
    ) {
        # method call
        # the args are children of $self: a pushmark/padrange, invocant, then args, then method_named() with the method name
        (undef, undef, @params_ops) = @{ $self->children };

    } else {
        die "unknown entersub first op " . $self->first->op->name;
    }
    my $sub_name_op = pop @params_ops;

    my $prefix = '';
    if ($self->op->flags & B::OPf_SPECIAL) {
        $prefix = 'do ';
    } elsif ($self->op->private & B::OPpENTERSUB_AMPER) {
        $prefix = '&';
    }

    my $function_args;
    if ($self->op->flags & B::OPf_STACKED) {
        $function_args = join(', ', map { $_->deparse } @params_ops) || '';
    }

    my $sub_invocation = $prefix . _deparse_sub_invocation($sub_name_op);

    if ($sub_name_op->op->private & B::OPpENTERSUB_NOPAREN) {
        $function_args
            ? join(' ', $sub_invocation, $function_args)
            : $sub_invocation;

    } elsif (defined $function_args) {
        "$sub_invocation($function_args)";
    } else {
        $sub_invocation;
    }
}

sub _deparse_sub_invocation {
    my $op = shift;

    my $op_name = $op->op->name;
    if ($op_name eq 'rv2cv'
        or
        ( $op->is_null and $op->_ex_name eq 'pp_rv2cv' )
    ) {
        # subroutine call

        if ($op->first->op->name eq 'gv') {
            # normal sub call: Some::Sub::named(...)
            $op->deparse;
        } else {
            # subref call
            $op->deparse . '->';
        }

    } elsif ($op_name eq 'method_named' or $op_name eq 'method') {
        join('->',  $op->parent->children->[1]->deparse(skip_quotes => 1),  # class
                    $op->deparse(skip_quotes => 1));

    } else {
        die "unknown sub invocation for $op_name";
    }
}

sub pp_method {
    my $self = shift;
    $self->first->deparse;
}

sub pp_av2arylen {
    my $self = shift;

    substr(my $list_name = $self->first->deparse, 0, 1, ''); # remove sigil
    '$#' . $list_name;
}

sub pp_delete {
    my $self = shift;
    my $local = ($self->op->private & B::OPpLVAL_INTRO
                 || $self->first->op->private & B::OPpLVAL_INTRO)
                    ? 'local '
                    : '';
    "delete(${local}" . $self->first->deparse . ')';
}

sub pp_exists {
    my $self = shift;
    my $arg = $self->first->deparse;
    if ($self->op->private & B::OPpEXISTS_SUB) {
        $arg = "&${arg}";
    }
    "exists($arg)";
}

# goto expr
sub pp_goto {
    my $target = shift->first->deparse;
    # goto &sub will deparse to goto \&sub
    $target =~ s/^\\&/&/;
    'goto ' . $target;
}

sub pp_readline {
    my $self = shift;
    my $arg = $self->first->deparse;
    my $first = $self->first;

    my $flags = $self->op->flags;
    if ($flags & B::OPf_SPECIAL) {
        $arg eq 'ARGV'
            ? '<<>>'
            : "<${arg}>";

    } elsif ($self->first->op->name eq 'gv') {
        # <F>
        "<${arg}>"

#    } elsif ($flags & B::OPf_STACKED) {
#        # readline(*F)
#        "readline(${arg})"
#
#    } else {
#        # readline($fh)
#        "readline(${arg})";
#    }
    } else {
        "readline(${arg})";
    }
}

sub pp_undef {
    #'undef(' . shift->first->deparse . ')'
    my $self = shift;
    my $arg = $self->first->deparse;
    if ($arg =~ m/::/) {
        $arg = $self->first->deparse;
    }
    "undef($arg)";
}

# backtick is strange... It's an UNOP, but can have 2 children
# seems that if it has one child, it was originally readpipe
# if it has 2 (an ex-pushmark, then the real child), it was baskticks or qx//
# since UNOPs don't have a last() method, we have to use $self->first->sibling
sub pp_backtick {
    my $self = shift;
    if (my $content_op = $self->first->sibling) {
        '`' . $content_op->deparse(skip_quotes => 1) . '`';
    } else {
        'readpipe(' . $self->first->deparse .')';
    }
}

# Functions that can operate on $_
#                   OP name        Perl fcn    targmy?
foreach my $a ( [ pp_entereval  => 'eval',      0 ],
                [ pp_schomp     => 'chomp',     1 ],
                [ pp_schop      => 'chop',      1 ],
                [ pp_chr        => 'chr',       1 ],
                [ pp_hex        => 'hex',       1 ],
                [ pp_lc         => 'lc',        0 ],
                [ pp_lcfirst    => 'lcfirst',   0 ],
                [ pp_uc         => 'uc',        0 ],
                [ pp_ucfirst    => 'ucfirst',   0 ],
                [ pp_length     => 'length',    1 ],
                [ pp_oct        => 'oct',       1 ],
                [ pp_ord        => 'ord',       1 ],
                [ pp_abs        => 'abs',       1 ],
                [ pp_cos        => 'cos',       1 ],
                [ pp_sin        => 'sin',       1 ],
                [ pp_exp        => 'exp',       1 ],
                [ pp_int        => 'int',       1 ],
                [ pp_log        => 'log',       1 ],
                [ pp_sqrt       => 'sqrt',      1 ],
                [ pp_quotemeta  => 'quotemeta', 1 ],
                [ pp_chroot     => 'chroot',    1 ],
                [ pp_readlink   => 'readlink',  0 ],
                [ pp_rmdir      => 'rmdir',     1 ],
                [ pp_defined    => 'defined',   0 ],
                [ pp_pos        => 'pos',       0 ],
                [ pp_alarm      => 'alarm',     0 ],
                [ pp_ref        => 'ref',       0 ],
) {
    my($pp_name, $perl_name, $targmy) = @$a;
    my $sub = sub {
        my $self = shift;
        my $arg = $self->first->deparse;

        my $target = $targmy ? $self->_maybe_targmy : '';
        "${target}${perl_name}("
            . ($arg eq '$_' ? '' : $arg)
            . ')';
    };
    no strict 'refs';
    *$pp_name = $sub;
}

# Functions that don't operate on $_
#                   OP name        Perl fcn    targmy?
foreach my $a ( [ pp_scalar     => 'scalar',    0 ],
                [ pp_rand       => 'rand',      1 ],
                [ pp_srand      => 'srand',     1 ],
                [ pp_each       => 'each',      0 ],
                [ pp_keys       => 'keys',      0 ],
                [ pp_values     => 'values',    0 ],
                [ pp_akeys      => 'keys',      0 ],
                [ pp_avalues    => 'values',    0 ],
                [ pp_aeach      => 'each',      0 ],
                [ pp_reach      => 'each',      0 ],
                [ pp_rkeys      => 'keys',      0 ],
                [ pp_rvalues    => 'values',    0 ],
                [ pp_ggrgid     => 'getgrgid',  0 ],
                [ pp_gpwuid     => 'getpwuid',  0 ],
                [ pp_gpwnam     => 'getpwnam',  0 ],
                [ pp_gpwent     => 'getpwent',  0 ],
                [ pp_ggrnam     => 'getgrnam',  0 ],
                [ pp_close      => 'close',     0 ],
                [ pp_closedir   => 'closedir',  0 ],
                [ pp_dbmclose   => 'dbmclose',  0 ],
                [ pp_eof        => 'eof',       0 ],
                [ pp_fileno     => 'fileno',    0 ],
                [ pp_getc       => 'getc',      0 ],
                [ pp_readdir    => 'readdir',   0 ],
                [ pp_rewinddir  => 'rewinddir', 0 ],
                [ pp_tell       => 'tell',      0 ],
                [ pp_telldir    => 'telldir',   0 ],
                [ pp_enterwrite => 'write',     0 ],
                [ pp_ghbyname   => 'gethostbyname', 0 ],
                [ pp_gnbyname   => 'getnetbyname', 0 ],
                [ pp_gpbyname   => 'getprotobyname', 0 ],
                [ pp_shostent   => 'sethostent', 0 ],
                [ pp_snetent    => 'setnetent', 0 ],
                [ pp_sprotoent  => 'setprotoent', 0 ],
                [ pp_sservent   => 'setservent', 0 ],
                [ pp_getpgrp    => 'getpgrp',   1 ],
                [ pp_tied       => 'tied',      0 ],
                [ pp_untie      => 'untie',     0 ],
                [ pp_getpeername=> 'getpeername',   0 ],
                [ pp_getsockname=> 'getsockname',   0 ],
                [ pp_caller     => 'caller',    0 ],
                [ pp_exit       => 'exit',      0 ],
) {
    my($pp_name, $perl_name, $targmy) = @$a;
    my $sub = sub {
        my $self = shift;
        my $arg = $self->first->deparse;

        my $target = $targmy ? $self->_maybe_targmy : '';
        "${target}${perl_name}($arg)";
    };
    no strict 'refs';
    *$pp_name = $sub;
}

# These look like keywords but take an argument
foreach my $a ( [ pp_dump       => 'dump' ],
                [ pp_next       => 'next' ],
                [ pp_last       => 'last' ],
                [ pp_redo       => 'redo' ],
) {
    my($pp_name, $perl_name) = @$a;
    my $sub = sub {
        my $self = shift;
        my $arg = $self->first->deparse;
        "${perl_name} $arg";
    };
    no strict 'refs';
    *$pp_name = $sub;
}

sub pp_umask {
    my $self = shift;
    'umask(' . $self->_as_octal( $self->first->deparse(skip_quotes => 1) ) . ')';
}

# Note that there's no way to tell the difference between "!" and "not"
sub pp_not {
    my $first = shift->first;
    my $first_deparsed = $first->deparse;

    if ($first->op->name eq 'match'
        and
        $first->_get_bound_variable_for_match
    ) {
        $first_deparsed;  # The match op will turn it into $var !~ m/.../
    } else {
        '!' . $first_deparsed;
    }
}

sub pp_flop {
    my $self = shift;
    my $flip = $self->first;
    my $op = ($flip->op->flags & B::OPf_SPECIAL) ? '...' : '..';

    my $range = $flip->first;
    my $start = $range->first->deparse;
    my $end = $range->other->deparse;

    "$start $op $end";
}

sub pp_dofile {
    'do ' . shift->first->deparse;
}

sub pp_require {
    my $self = shift;

    my $first = $self->first;
    my $name = $first->deparse;
    if ($first->op->name eq 'const'
        and
        $first->op->private & B::OPpCONST_BARE
    ) {
        $name =~ s#/#::#g;
        $name =~ s/\.pm$//;
    }

    'require ' . $name;
}

*pp_aelem = *pp_helem = sub {
    # This is likely an optimized-out op where ->first is a pp_multideref
    # that'll do all the work for us
    shift->first->deparse;
};

sub pp_sassign {
    my $self = shift;
    # This is likely an optimized-out assignment where substr is being
    # used as an lvalue.  pp_substr will be our only child and take care of
    # deparsing the assignment for us
    $self->first->deparse;
}

# 5.12 and earlier Perls used glob as an optimized-out UNOP and looks like
# a call to CORE::GLOBAL__glob()
# This glob is compiled like this:
# ex-pp_glob
#   entersub
#     ex-list
#       pushmark
#       argument-to-glob
#       const integer 0
#     ex-rv2cv
#       gv *CORE::GLOBAL::glob
# 5.14 is wierder - it has the same ex-glob/entersub, but then a real glob OP
# inside there
# ex-pp_glob
#   entersub
#     ex-list
#       pushmark
#       glob (listOP)
#         ex-pushmark
#         argument-to-glob
#         const integer 0
#     ex-rv2cv
#       gv *CORE::GLOBAL::glob
# Newer perls just have the inner LISTOP and encode the params differently.
sub pp_glob {
    my $self = shift;
    ($^V lt v5.14)
        ? 'glob(' . $self->first->first->children->[1]->deparse . ')'
        : $self->first->first->children->[1]->deparse;
}

# Operators
#               OP name         perl op   pre?  targmy?
foreach my $a ( [ pp_preinc     => '++',    1,  0 ],
                [ pp_i_preinc   => '++',    1,  0 ],
                [ pp_postinc    => '++',    0,  1 ],
                [ pp_i_postinc  => '++',    0,  1 ],
                [ pp_predec     => '--',    1,  0 ],
                [ pp_i_predec   => '--',    1,  0 ],
                [ pp_postdec    => '--',    0,  1 ],
                [ pp_i_postdec  => '--',    0,  1 ],
                [ pp_complement => '~',     1,  1 ],
                [ pp_scomplement => '~.',   1,  1 ],
) {
    my($pp_name, $op, $is_prefix, $is_targmy) = @$a;

    my $sub = sub {
        my $self = shift;
        my $deparsed = $is_prefix
            ? ($op . $self->first->deparse)
            : ($self->first->deparse . $op);
        if ($is_targmy) {
            $deparsed = $self->_maybe_targmy . $deparsed;
        }
        $deparsed;
    };
    no strict 'refs';
    *$pp_name = $sub;
}

#sub pp_leavewhereso {
#    my $self = shift;
#
#    my $enter_op = $self->first;
#    my $condition_op = $enter_op->first;
#    my $condition_deparsed = $condition_op->deparse;
#    my $block_op = $condition_op->sibling;
#
#    my $keyword = $condition_op->op->name eq 'smartmatch'
#                    ? 'whereis'
#                    : 'whereso';
#
#    if ($self->_is_postfix_whereso) {
#        my $block_deparsed = $block_op->deparse(omit_braces => 1, skip => 0, noindent => 1);
#        "$block_deparsed $keyword ($condition_deparsed);" # ; because there's no COPs inside given to generate them
#    } else {
#        my $block_deparsed = $block_op->deparse(force_multiline => 1);
#        "$keyword ($condition_deparsed) $block_deparsed";
#    }
#}
#
## "regular" whereso has a format like:
## 1-line with braces:
##   leavewhereso
##       enterwhereso
##           condition-op(s)
##           scope
##               (ex-)nextstate
##               block-op(s)
## or multiline with braces:
##   leavewhereso
##       enterwhereso
##           condition-op(s)
##           leave
##               enter
##               block-op(s)
## postfix whereso looks like the first one, but missing the nextstate that's
## the first part of the scope
#sub _is_postfix_whereso {
#    my $self = shift;
#    my $scope_op = $self->first->first->sibling;
#    my $scope_name = $scope_op->op->name;
#
#    my $first_in_scope_op = $scope_name eq 'scope' ? $scope_op->first : undef;
#    return( $scope_name eq 'scope'
#            and $first_in_scope_op
#            and ! $first_in_scope_op->is_null
#            and ! ($first_in_scope_op->_ex_name eq 'pp_nextstate')
#        );
#}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::UNOP - Deparser class for unary OPs

=head1 DESCRIPTION

This package contains methods to deparse UNOPs (refgen, rv2sv, etc)

=head2 Methods

=over 4

=item first

Returns a L<Devel::Chitin::OpTree> instance for the child of this node

=back

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
