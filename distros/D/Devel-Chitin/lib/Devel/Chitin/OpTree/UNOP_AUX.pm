package Devel::Chitin::OpTree::UNOP_AUX;
use base 'Devel::Chitin::OpTree::UNOP';

our $VERSION = '0.18';

use strict;
use warnings;

my @open_bracket = qw( [ { );
my @close_bracket = qw( ] } );

my %hash_actions = map { $_ => 1 }
                    ( B::MDEREF_HV_pop_rv2hv_helem, B::MDEREF_HV_gvsv_vivify_rv2hv_helem,
                      B::MDEREF_HV_padsv_vivify_rv2hv_helem, B::MDEREF_HV_vivify_rv2hv_helem,
                      B::MDEREF_HV_padhv_helem, B::MDEREF_HV_gvhv_helem );
sub pp_multideref {
    my $self = shift;

    my @aux_list = $self->op->aux_list($self->cv);

    my $deparsed = '';
    while(@aux_list) {
        my $aux = shift @aux_list;
        while (($aux & B::MDEREF_ACTION_MASK) != B::MDEREF_reload) {

            my $action = $aux & B::MDEREF_ACTION_MASK;
            my $is_hash = $hash_actions{$action} || 0;

            if ($action == B::MDEREF_AV_padav_aelem
                or $action == B::MDEREF_HV_padhv_helem
            ) {
                $deparsed .= '$' . substr( $self->_padname_sv( shift @aux_list )->PVX, 1);

            } elsif ($action == B::MDEREF_HV_gvhv_helem
                     or $action == B::MDEREF_AV_gvav_aelem
            ) {
                $deparsed .= '$' . $self->_gv_name(shift @aux_list);

            } elsif ($action == B::MDEREF_HV_padsv_vivify_rv2hv_helem
                     or $action == B::MDEREF_AV_padsv_vivify_rv2av_aelem
            ) {
                $deparsed .= $self->_padname_sv( shift @aux_list )->PVX . '->';

            } elsif ($action == B::MDEREF_HV_gvsv_vivify_rv2hv_helem
                     or $action == B::MDEREF_AV_gvsv_vivify_rv2av_aelem
            ) {
                $deparsed .= '$' . $self->_gv_name(shift @aux_list) . '->';

            } elsif ($action == B::MDEREF_HV_vivify_rv2hv_helem
                     or $action == B::MDEREF_AV_vivify_rv2av_aelem
            ) {
                $deparsed .= '->';
            }


            $deparsed .= $open_bracket[$is_hash];

            my $index = $aux & B::MDEREF_INDEX_MASK;
            if ($index == B::MDEREF_INDEX_padsv) {
                $deparsed .= $self->_padname_sv(shift @aux_list)->PV;

            } elsif ($index == B::MDEREF_INDEX_const) {
                my $sv = shift(@aux_list);
                $deparsed .= $is_hash
                                ? $self->_quote_sv($sv)
                                : $sv;
            }

            $deparsed .= $close_bracket[$is_hash];

        } continue {
            $aux >>= B::MDEREF_SHIFT;
        }
    }

    $deparsed;
}

my %multiconcat_skip_optimized_children = ( pp_padsv => 1, pp_const => 1, pp_pushmark => 1 );
sub pp_multiconcat {
    my($self, %flags) = @_;

    # Skip children that were optimized away by the multiconcat
    my @kids = grep { my $name = $_->op->name;
                      if ($name eq 'null') {
                          $name = 'ex-' . $_->_ex_name;
                      }
                      ! ( $_->is_null && $multiconcat_skip_optimized_children{ $_->_ex_name } )
                    }
                @{$self->children};

    my $is_assign;
    my $lhs = '';
    my $op = $self->op;
    my $is_append = $op->private & &B::OPpMULTICONCAT_APPEND;
    if ($op->private & B::OPpTARGET_MY) {
        # $var = ... or $var .= ...
        $lhs = $self->_padname_sv($op->targ)->PV;
        $is_assign = 1;
    } elsif ($op->flags & B::OPf_STACKED) {
        # expr = ,,, or expr .= ...
        my $expr = $is_append ? shift(@kids) : pop(@kids);
        $lhs = $expr->deparse;
        $is_assign = 1;
    }

    if ($is_assign) {
        $lhs .= $is_append ? ' .= ' : ' = ';
    }

    # extract a list of string constants from the combined string and list of substring lengths
    my($nargs, $const_str, @substr_lengths) = $self->op->aux_list($self->cv);
    my $str_idx = 0;
    my @string_parts;
    foreach my $len ( @substr_lengths ) {
        if ($len == -1) {
            push @string_parts, undef;
        } else {
            push @string_parts, substr($const_str, $str_idx, $len);
            $str_idx += $len;
        }
    }

    my $rhs = '';
    if ($op->private & &B::OPpMULTICONCAT_STRINGIFY
        or $op->parent->name eq 'substcont'
    ) {
        # A double quoted string with variable interpolation: "foo = $foo bar = $bar"
        foreach my $str_part ( @string_parts ) {
            $rhs .= $str_part if defined $str_part;
            $rhs .= shift(@kids)->deparse if @kids;
        }
        $rhs = $self->_quote_string($rhs, skip_quotes => 1, %flags);
        $rhs = "qq($rhs)" unless $flags{skip_quotes};

    } elsif ($op->private & &B::OPpMULTICONCAT_FAKE) {
        # sprintf() with only %s and %% formats
        my $format_str = join('%s', map { s/%/%%/g }
                                    map { defined ? $_ : '' }
                                    @string_parts);
        $rhs .= sprintf('sprintf(%s, %s)',
                        $format_str,
                        join(', ', map { $_->deparse } @kids));
    } else {
        # one or more explicit concats: "foo" . $foo
        my @parts;
        foreach my $str_part ( @string_parts ) {
            if (defined $str_part) {
                $str_part = $self->_quote_string($str_part) unless $flags{skip_quotes};
                push @parts, $str_part;
            }
            push @parts, shift(@kids)->deparse if @kids;
        }
        $rhs .= join(' . ', @parts);
    }

    return "${lhs}${rhs}";
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::OpTree::UNOP_AUX - Deparser class for unary OPs with auxillary data

=head1 DESCRIPTION

This package contains methods to deparse UNOP_AUXs (multideref)

=head1 SEE ALSO

L<Devel::Chitin::OpTree>, L<Devel::Chitin>, L<B>, L<B::Deparse>, L<B::DeparseTree>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
