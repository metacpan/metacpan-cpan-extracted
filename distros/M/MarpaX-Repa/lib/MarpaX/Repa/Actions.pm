use 5.010; use strict; use warnings;

package MarpaX::Repa::Actions;

=head1 NAME

MarpaX::Repa::Actions - set of actions to begin with

=head1 DESCRIPTION

Some actions to start with that just present rules as various
perl structures. Just to help you concentrate on grammar at the
beginning.

=head1 METHODS

=head2 import

Marpa at the moment doesn't use inheritance to lookup actions, so instead
of subclassing this module exports all actions and new method, but only
if '-base' is passed:

    package MyActions;
    use MarpaX::Repa::Actions '-base';

=cut

sub import {
    my $class = shift;
    my $into = scalar caller;
    return unless grep $_ eq '-base', @_;


    no strict 'refs';
    foreach my $name (grep /^new$|^do_/, keys %{$class."::"}) {
        my $src = $class .'::'. $name;
        my $dst = $into.'::'.$name;
        next if defined &$dst;
        *$dst = *$src;
    }
}

=head2 new

Just returns a new hash based instance of the class. See 'action_object'
in L<Marpa::R2::Grammar>.

=cut

sub new {
    my $self = shift;
    return bless {}, ref($self)||$self;
}

=head2 do_what_I_mean

Returns:

    { rule => 'rule name', value => $child || \@children }

=cut

sub do_what_I_mean {
    shift;
    my $grammar = $Marpa::R2::Context::grammar;
    my ($lhs)   = $grammar->rule( $Marpa::R2::Context::rule );
    my @children = grep defined, @_;
    my $ret = { rule => $lhs, value => scalar @children > 1 ? \@children : shift @children };
    return $ret;
}

sub do_rule_list {
    shift;
    my $grammar = $Marpa::R2::Context::grammar;
    my ($lhs)   = $grammar->rule( $Marpa::R2::Context::rule );
    return { rule => $lhs, value => [grep defined, @_] };
}

=head2 do_join_children

Returns:

    { rule => 'rule name', value => join '', @children }

=cut

sub do_join_children {
    shift;
    my $grammar = $Marpa::R2::Context::grammar;
    my ($lhs)   = $grammar->rule($Marpa::R2::Context::rule);
    return { rule => $lhs, value => join '', grep defined, @_ };
}

=head2 do_join

Returns:

    join '', @children

=cut

sub do_join {
    shift;
    return join '', grep defined, @_;
}

=head2 do_list

Returns:

    \@children

=cut

sub do_list {
    shift;
    return [ grep defined, @_ ];
}

=head2 do_scalar_or_list

Returns:

    $child || \@children

=cut

sub do_scalar_or_list {
    shift;
    @_ = grep defined, @_;
    return @_>1? \@_ : shift;
}

=head2 do_flat_to_list

Returns (pseudo code):

    [ map @$_||%$_||$_, grep defined, @_ ]

=cut

sub do_flat_to_list {
    shift;
    return [ map { ref $_ eq 'ARRAY'? @$_ : ref $_ eq 'HASH'? %$_ : $_ } grep defined, @_ ];
}

=head2 do_ignore

Returns:

    undef

=cut

sub do_ignore { undef }

1;
