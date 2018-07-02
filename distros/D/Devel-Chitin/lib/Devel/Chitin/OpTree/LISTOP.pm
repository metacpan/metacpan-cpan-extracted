package Devel::Chitin::OpTree::LISTOP;
use base Devel::Chitin::OpTree::BINOP;

our $VERSION = '0.16';

use Fcntl qw(:DEFAULT :flock SEEK_SET SEEK_CUR SEEK_END);
use POSIX qw(:sys_wait_h);
use Socket ();

use strict;
use warnings;

sub pp_lineseq {
    my $self = shift;
    my %params = @_;

    my $children = $self->children;

    my $start = $params{skip} || 0;
    my $end = $#$children;
    if ($children->[-1]->op->name eq 'unstack'
        or
        $children->[-1]->is_implicit_break_at_end_of_when_block
    ) {
        $end--;
    }

    my $deparsed;
    for (my $i = $start; $i <= $end; $i++) {
        my $this_child_deparsed;
        if ($children->[$i]->is_for_loop) {
            $this_child_deparsed = $children->[$i]->_deparse_for_loop;
            $i += $children->[$i]->_num_ops_in_for_loop;
        } else {
            $this_child_deparsed = $children->[$i]->deparse;
        }
        next unless length $this_child_deparsed;
        $deparsed .= $this_child_deparsed;
        $deparsed .= ';' if _should_insert_semicolon_after($children->[$i]);
        $deparsed .= "\n" unless $i == $end;
    }
    $deparsed;
}

# Don't put a semi after a block, or after the last statement (has no sibling)
# It determines if this op decodes as a block by recursing into this OPs
# children and looking at the last child to see if it's scope-like
sub _should_insert_semicolon_after {
    my $op = shift;

    return if ($op->op->sibling->isa('B::NULL')
                or
                $op->op->sibling->name eq 'unstack' && $op->op->sibling->sibling->isa('B::NULL')
                or
                $op->next->is_implicit_break_at_end_of_when_block);
    while($op) {
        return 1 if $op->is_postfix_loop;
        return if $op->is_scopelike;
        return if $op->isa('Devel::Chitin::OpTree::COP');
        $op = $op->children->[-1];
    }
    return 1;
}

sub pp_leave {
    my $self = shift;
    my %params = @_;

    if (my $deparsed = $self->_deparse_postfix_while) {
        return $deparsed;
    }

    $self->_enter_scope;
    my $deparsed = $self->pp_lineseq(@_, skip => 1, %params) || ';';
    $self->_leave_scope;

    my $parent = $self->parent;
    my $do = ($parent and $parent->is_null and $parent->op->flags & B::OPf_SPECIAL)
                ? 'do '
                : '';

    my $block_declaration = '';
    if ($parent and $parent->is_null and $parent->op->flags & B::OPf_SPECIAL) {
        $block_declaration = 'do ';
    } elsif ($self->op->name eq 'leavetry') {
        $block_declaration = 'eval ';
    }

    $deparsed = $self->_indent_block_text($deparsed, %params);

    my($open_brace, $close_brace) = $params{omit_braces} ? ('','') : ('{', '}');

    join('', $block_declaration, $open_brace, $deparsed, $close_brace);
}
*pp_scope = \&pp_leave;
*pp_leavetry = \&pp_leave;

sub pp_anonhash {
    my $self = shift;
    my @children = @{$self->children};
    shift @children; # skip pushmark

    my $deparsed = '{';
    for (my $i = 0; $i < @children; $i+=2) {
        (my $key = $children[$i]->deparse) =~ s/^'|'$//g; # remove quotes around the key
        $deparsed .= $key
                     . ' => '
                     . $children[$i+1]->deparse;
        $deparsed .= ', ' unless ($i+2) >= @children;
    }
    $deparsed . '}';
}

sub pp_anonlist {
    my $self = shift;
    my @children = @{$self->children};
    shift @children;  # skip pushmark
    '[' . join(', ', map { $_->deparse } @children) . ']';
}

sub pp_list {
    my $self = shift;
    my %params = @_;

    my $children = $self->children;
    my $joiner = exists($params{join_with}) ? $params{join_with} : ', ';

    ($params{skip_parens} ? '' : '(')
        . join($joiner, map { $_->deparse(%params) } @$children[1 .. $#$children]) # skip the first op: pushmark
        . ($params{skip_parens} ? '' :')');
}

sub pp_aslice {
    push(@_, '[', ']'),
    goto &_aslice_hslice_builder;
}
*pp_kvaslice = \&pp_aslice;

sub pp_hslice {
    push(@_, '{', '}');
    goto &_aslice_hslice_builder;
}
*pp_kvhslice = \&pp_hslice;

sub pp_lvrefslice {
    my $self = shift;
    $self->last->op->name =~ m/av$/
        ? $self->pp_aslice
        : $self->pp_hslice;
}

my %aslice_hslice_allowed_ops = map { $_ => 1 } qw( padav padhv rv2av rv2hv );
sub _aslice_hslice_builder {
    my($self, $open_paren, $close_paren) = @_;

    # first child is no-op pushmark, followed by slice elements, last is the array to slice
    my $children = $self->children;

    my($child1, $child2, $child3) = @$children;
    unless (@$children == 3
            and
            $child1->op->name eq 'pushmark'
            and
            ( $child2->op->name eq 'list'
                or $child2->_ex_name eq 'pp_list'
                or $child2->op->name eq 'padav'
            )
            and
            $aslice_hslice_allowed_ops{ $child3->op->name }
    ) {
        die "unexpected aslice/hslice for $open_paren $close_paren";
    }

    my $op_name = $self->op_name;
    my $sigil = ($op_name eq 'kvhslice'
                 or $op_name eq 'kvaslice') ? '%' : '@';

    my $array_name = substr($self->children->[2]->deparse, 1); # remove the sigil
    "${sigil}${array_name}" . $open_paren . $children->[1]->deparse(skip_parens => 1) . $close_paren;
}

sub pp_unpack {
    my $self = shift;
    my $children = $self->children;
    my @args = map { $_->deparse } @$children[1, 2];
    pop @args if $args[1] eq '$_';
    'unpack('
        . join(', ', @args)
        . ')';
}

sub pp_sort {
    _deparse_sortlike(shift, 'sort', @_);
}

sub pp_print {
    _deparse_sortlike(shift, 'print', is_printlike => 1, @_);
}

sub pp_prtf {
    _deparse_sortlike(shift, 'printf', is_printlike => 1, @_);
}

sub pp_say {
    _deparse_sortlike(shift, 'say', is_printlike => 1, @_);
}

# deparse something that may have a block or expression as
# its first arg:
#     sort { ... } @list
#     print $f @messages;
sub _deparse_sortlike {
    my($self, $function, %params) = @_;

    my $children = $self->children;

    my $is_stacked = $self->op->flags & B::OPf_STACKED;

    if ($params{is_printlike}
        and
        ! $is_stacked
        and
        @$children == 2  # 0th is pushmark
        and
        $children->[1]->deparse eq '$_'
    ) {
        return "$function()";
    }

    # Note the space:
    # sort (items, in, list)
    # print(items, in, list)
    my $block = $function eq 'sort' ? ' ' : '';
    my $first_value_child_op_idx = 1; # skip pushmark
    if ($is_stacked) {
        my $block_op = $children->[1]; # skip pushmark
        $block_op = $block_op->first if $block_op->is_null;

        if ($block_op->op->name eq 'const') {
            # it's a function name
            $block = ' ' . $block_op->deparse(skip_quotes => 1) . ' ';

        } else {
            # a block or some other expression
            $block = ' ' . $block_op->deparse(skip_sigil => 1) . ' ';
        }
        $first_value_child_op_idx = 2;  # also skip block

    } elsif ($function eq 'sort') {
        # using some default sort sub
        my $priv_flags = $self->op->private;
        if ($priv_flags & B::OPpSORT_NUMERIC) {
            $block = $priv_flags & B::OPpSORT_DESCEND
                            ? ' { $b <=> $a } '
                            : ' { $a <=> $b } ';
        } elsif ($priv_flags & B::OPpSORT_DESCEND) {
            $block = ' { $b cmp $a } ';  # There's no $a cmp $b because it's the default sort
        }

    } elsif (@$children == 2) {
        # a basic print "string\n":
        $block = ' ' ;
    }

    my @values = map { $_->deparse }
                    @$children[$first_value_child_op_idx .. $#$children];

    # now handled by aassign
    #if ($self->op->private & B::OPpSORT_INPLACE) {
    #    $assignment = $sort_values[0] . ' = ';
    #}

    "${function}${block}"
        . ( @values > 1 ? '(' : '' )
        . join(', ', @values )
        . ( @values > 1 ? ')' : '' );
}

sub pp_dbmopen {
    my $self = shift;
    my $children = $self->children;
    'dbmopen('
        . $children->[1]->deparse . ', '   # hash
        . $children->[2]->deparse . ', '   # file
        . sprintf('0%3o', $children->[3]->deparse)
    . ')';
}

sub pp_flock {
    my $self = shift;
    my $children = $self->children;

    my $target = $self->_maybe_targmy;

    my $flags = $self->_deparse_flags($children->[2]->deparse(skip_quotes => 1),
                                      [ LOCK_SH => LOCK_SH,
                                        LOCK_EX => LOCK_EX,
                                        LOCK_UN => LOCK_UN,
                                        LOCK_NB => LOCK_NB ]);
    "${target}flock("
        . $children->[1]->deparse
        . ", $flags)";
}

sub pp_seek { shift->_deparse_seeklike('seek') }
sub pp_sysseek { shift->_deparse_seeklike('sysseek') }

my %seek_flags = (
        SEEK_SET() => 'SEEK_SET',
        SEEK_CUR() => 'SEEK_CUR',
        SEEK_END() => 'SEEK_END',
    );
sub _deparse_seeklike {
    my($self, $function) = @_;
    my $children = $self->children;

    my $whence = $children->[3]->deparse(skip_quotes => 1);

    "${function}(" . join(', ', $children->[1]->deparse,
                         $children->[2]->deparse,
                         (exists($seek_flags{$whence}) ? $seek_flags{$whence} : $whence))
        . ')';
}

sub _generate_flag_list {
    map { local $@;
          my $val = eval "$_";
          $val ? ( $_ => $val ) : ()
    } @_
}

my @sysopen_flags = _generate_flag_list(
                         qw( O_RDONLY O_WRONLY O_RDWR O_NONBLOCK O_APPEND O_CREAT
                             O_TRUNC O_EXCL O_SHLOCK O_EXLOCK O_NOFOLLOW O_SYMLINK
                             O_EVTONLY O_CLOEXEC));
sub pp_sysopen {
    my $self = shift;
    my $children = $self->children;

    my $mode = $self->_deparse_flags($children->[3]->deparse(skip_quotes => 1),
                                     \@sysopen_flags);
    $mode ||= 'O_RDONLY';
    my @params = (
            # skip pushmark
            $children->[1]->deparse,  # filehandle
            $children->[2]->deparse,  # file name
            $mode,
        );

    if ($children->[4]) {
        # perms
        push @params, $self->_as_octal($children->[4]->deparse(skip_quotes => 1));
    }
    'sysopen(' . join(', ', @params) . ')';
}

my @waitpid_flags = _generate_flag_list(qw( WNOHANG WUNTRACED ));
sub pp_waitpid {
    my $self = shift;
    my $children = $self->children;
    my $flags = $self->_deparse_flags($children->[2]->deparse(skip_quotes=> 1),
                                      \@waitpid_flags);
    $flags ||= '0';
    my $target = $self->_maybe_targmy;
    "${target}waitpid(" . join(', ', $children->[1]->deparse, # PID
                            $flags) . ')';
}

sub pp_truncate {
    my $self = shift;
    my $children = $self->children;

    my $fh;
    if ($self->op->flags & B::OPf_SPECIAL) {
        # 1st arg is a bareword filehandle
        $fh = $children->[1]->deparse(skip_quotes => 1);

    } else {
        $fh = $children->[1]->deparse;
    }

    "truncate(${fh}, " . $children->[2]->deparse . ')';
}

sub pp_chmod {
    my $self = shift;
    my $children = $self->children;
    my $mode = $self->_as_octal($children->[1]->deparse);
    my $target = $self->_maybe_targmy;
    "${target}chmod(${mode}, " . join(', ', map { $_->deparse } @$children[2 .. $#$children]) . ')';
}

sub pp_mkdir {
    my $self = shift;
    my $children = $self->children;
    my $target = $self->_maybe_targmy;
    my $dir = $children->[1]->deparse;  # 0th is pushmark
    if (@$children == 2) {
        if ($dir eq '$_') {
            "${target}mkdir()";
        } else {
            "${target}mkdir($dir)";
        }
    } else {
        my $mode = $self->_as_octal($children->[2]->deparse);
        "${target}mkdir($dir, $mode)";
    }
}

# strange... glob is a LISTOP, but always has 3 children
# 1. ex-pushmark
# 2. arg containing the pattern
# 3. a gv SVOP refering to a bogus glob in no package with no name
# There's no way to distinguish glob(...) from <...>
sub pp_glob {
    my $self = shift;
    'glob(' . $self->children->[1]->deparse . ')';
}

# pp_split is a LISTOP up through 5.25.5 and became a PMOP in
# 5.25.6
sub pp_split {
    my $self = shift;

    my $children = $self->children;

    my $regex = $self->_resolve_split_expr;

    my @params = ( $regex );

    my $i = 0;
    $i++ if ($children->[0]->op->name eq 'pushre'
             or
             $children->[0]->op->name eq 'regcomp');

    push @params, $children->[$i++]->deparse;  # string

    if (my $n_fields = $children->[ $i++ ]->deparse) {
        push(@params, $n_fields) if $n_fields > 0;
    }

    my $target = $self->_resolve_split_target;

    "${target}split(" . join(', ', @params) . ')';
}

sub _resolve_split_expr {
    my $self = shift;

    my $regex_op = $self->children->[0];
    my $regex = ( $regex_op->op->flags & B::OPf_SPECIAL
                  and
                  ! @{$regex_op->children}
                )
                    ? $regex_op->deparse(delimiter => "'") # regex was given as a string
                    : $regex_op->deparse;
    return $regex;
}


sub _resolve_split_target {
    my $self = shift;
    my $children = $self->children;

    my $pmreplroot_op = $self->_resolve_split_target_pmop;
    my $pmreplroot = $pmreplroot_op->op->pmreplroot;
    my $gv;
    if (ref($pmreplroot) eq 'B::GV') {
        $gv = $pmreplroot;
    } elsif (!ref($pmreplroot) and $pmreplroot > 0) {
        $gv = $self->_padval_sv($pmreplroot);
    }

    my $target = '';
    if ($gv) {
        $target = '@' . $self->_gv_name($gv);

    } elsif (my $targ = $pmreplroot_op->op->targ) {
        $target = $pmreplroot_op->_padname_sv($targ)->PV;

    } elsif ($self->op->flags & B::OPf_STACKED) {
        $target = $children->[-1]->deparse;
    }

    $target .= ' = ' if $target;
}

sub _resolve_split_target_pmop {
    my $self = shift;
    return $self->children->[0];
}

foreach my $d ( [ pp_exec => 'exec' ],
                [ pp_system => 'system' ],
) {
    my($pp_name, $function) = @$d;
    my $sub = sub {
        my $self = shift;

        my @children = @{ $self->children };
        shift @children; # skip pushmark

        my $exec = $function;
        if ($self->op->flags & B::OPf_STACKED) {
            # has initial non-list agument
            my $program = shift(@children)->first;
            $exec .= ' ' . $program->deparse . ' ';
        }
        my $target = $self->_maybe_targmy;
        $target . $exec . '(' . join(', ', map { $_->deparse } @children) . ')'
    };

    no strict 'refs';
    *$pp_name = $sub;
}

my %addr_types = map { my $val = eval "Socket::$_"; $@ ? () : ( $val => $_ ) }
                    qw( AF_802 AF_APPLETALK AF_INET AF_INET6 AF_ISO AF_LINK
                        AF_ROUTE AF_UNIX AF_UNSPEC AF_X25 );
foreach my $d ( [ pp_ghbyaddr => 'gethostbyaddr' ],
                [ pp_gnbyaddr => 'getnetbyaddr' ],
) {
    my($pp_name, $perl_name) = @$d;
    my $sub = sub {
        my $children = shift->children;
        my $addr = $children->[1]->deparse;
        my $type = $addr_types{ $children->[2]->deparse(skip_quotes => 1) }
                    || $children->[2]->deparse;
        "${perl_name}($addr, $type)";
    };
    no strict 'refs';
    *$pp_name = $sub;
}

my %sock_domains = map { my $val = eval "Socket::$_"; $@ ? () : ( $val => $_ ) }
                    qw( PF_802 PF_APPLETALK PF_INET PF_INET6 PF_ISO PF_LINK
                        PF_ROUTE PF_UNIX PF_UNSPEC PF_X25 );
my %sock_types = map { my $val = eval "Socket::$_"; $@ ? () : ( $val => $_ ) }
                    qw( SOCK_DGRAM SOCK_RAW SOCK_RDM SOCK_SEQPACKET SOCK_STREAM );
sub pp_socket {
    my $children = shift->children;
    my $domain = $sock_domains{ $children->[2]->deparse(skip_quotes => 1) }
                    || $children->[2]->deparse;
    my $type = $sock_types{ $children->[3]->deparse(skip_quotes => 1) }
                    || $children->[3]->deparse;
    'socket(' . join(', ',  $children->[1]->deparse,
                            $domain, $type,
                            $children->[4]->deparse) . ')';
}

sub pp_sockpair {
    my $children = shift->children;
    my $domain = $addr_types{ $children->[3]->deparse(skip_quotes => 1) }
                    || $children->[3]->deparse;
    my $type = $sock_types{ $children->[4]->deparse(skip_quotes => 1) }
                    || $children->[4]->deparse;
    my $proto = $sock_domains{ $children->[5]->deparse(skip_quotes => 1) }
                    || $children->[5]->deparse;

    'socketpair(' . join(', ',  $children->[1]->deparse,
                                $children->[2]->deparse,
                                $domain, $type, $proto) . ')';
}

sub pp_substr {
    my $self = shift;
    my $children = $self->children;
    if ($^V ge v5.16.0 and $self->op->private & B::OPpSUBSTR_REPL_FIRST()) {
        # using subtr as an lvalue
        my @substr_params = @{$children}[2..4];
        'substr('
            . join(', ', map { $_->deparse } @substr_params)
            . ') = '
            . $children->[1]->deparse;
    } else {
        'substr('
            . join(', ', map { $_->deparse } @$children[1 .. $#$children]) # [0] is pushmark
            . ')';
    }
}

sub pp_mapstart { 'map' }
sub pp_grepstart { 'grep' }

#                 OP name           Perl fcn    targmy?
foreach my $a ( [ pp_crypt      => 'crypt',     1 ],
                [ pp_index      => 'index',     1 ],
                [ pp_rindex     => 'rindex',    1 ],
                [ pp_pack       => 'pack',      0 ],
                [ pp_reverse    => 'reverse',   0 ],
                [ pp_sprintf    => 'sprintf',   0 ],
                [ pp_atan2      => 'atan2',     1 ],
                [ pp_push       => 'push',      1 ],
                [ pp_unshift    => 'unshift',   1 ],
                [ pp_splice     => 'splice',    1 ],
                [ pp_join       => 'join',      1 ],
                [ pp_binmode    => 'binmode',   0 ],
                [ pp_die        => 'die',       0 ],
                [ pp_warn       => 'warn',      0 ],
                [ pp_read       => 'read',      0 ],
                [ pp_sysread    => 'sysread',   0 ],
                [ pp_syswrite   => 'syswrite',  0 ],
                [ pp_seekdir    => 'seekdir',   0 ],
                [ pp_syscall    => 'syscall',   0 ],
                [ pp_select     => 'select',    0 ],
                [ pp_sselect    => 'select',    0 ],
                [ pp_vec        => 'vec',       0 ],
                [ pp_chown      => 'chown',     1 ],
                [ pp_fcntl      => 'fcntl',     1 ],
                [ pp_ioctl      => 'ioctl',     1 ],
                [ pp_open       => 'open',      0 ],
                [ pp_open_dir   => 'opendir',   0 ],
                [ pp_rename     => 'rename',    0 ],
                [ pp_link       => 'link',      1 ],
                [ pp_symlink    => 'symlink',   1 ],
                [ pp_unlink     => 'unlink',    1 ],
                [ pp_utime      => 'utime',     1 ],
                [ pp_formline   => 'formline',  0 ],
                [ pp_gpbynumber => 'getprotobynumber', 0 ],
                [ pp_gsbyname   => 'getservbyname', 0 ],
                [ pp_gsbyport   => 'getservbyport', 0 ],
                [ pp_return     => 'return', 0 ],
                [ pp_kill       => 'kill',      1 ],
                [ pp_pipe_op    => 'pipe',      0 ],
                [ pp_getpriority=> 'getpriority',   1 ],
                [ pp_setpriority=> 'setpriority',   1 ],
                [ pp_setpgrp    => 'setpgrp',   1 ],
                [ pp_bless      => 'bless',     0 ],
                [ pp_tie        => 'tie',       0 ],
                [ pp_accept     => 'accept',    0 ],
                [ pp_bind       => 'bind',      0 ],
                [ pp_connect    => 'connect',   0 ],
                [ pp_listen     => 'listen',    0 ],
                [ pp_gsockopt   => 'getsockopt',0 ],
                [ pp_ssockopt   => 'setsockopt',0 ],
                [ pp_send       => 'send',      0 ],
                [ pp_recv       => 'recv',      0 ],
                [ pp_shutdown   => 'shutdown',  0 ],
                [ pp_msgctl     => 'msgctl',    0 ],
                [ pp_msgget     => 'msgget',    0 ],
                [ pp_msgsnd     => 'msgsnd',    0 ],
                [ pp_msgrcv     => 'msgrcv',    0 ],
                [ pp_semctl     => 'semctl',    0 ],
                [ pp_semget     => 'semget',    0 ],
                [ pp_semop      => 'semop',     0 ],
                [ pp_shmctl     => 'shmctl',    0 ],
                [ pp_shmget     => 'shmget',    0 ],
                [ pp_shmread    => 'shmread',   0 ],
                [ pp_shmwrite   => 'shmwrite',  0 ],
) {
    my($pp_name, $perl_name, $targmy) = @$a;
    my $sub = sub {
        my $self = shift;
        my $children = $self->children;

        my $target = $targmy ? $self->_maybe_targmy : '';
        "${target}${perl_name}("
            . join(', ', map { $_->deparse } @$children[1 .. $#$children]) # [0] is pushmark
            . ')';
    };
    no strict 'refs';
    *$pp_name = $sub;
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::LISTOP - Deparser class for list OPs

=head1 DESCRIPTION

This package contains methods to deparse LISTOPs (lineseq, list, etc).

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
