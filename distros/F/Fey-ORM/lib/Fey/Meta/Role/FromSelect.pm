package Fey::Meta::Role::FromSelect;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::ORM::Types qw( Bool CodeRef );
use Moose::Util::TypeConstraints qw( find_type_constraint );

use Moose::Role;

has select => (
    is       => 'ro',
    required => 1,
    does     => 'Fey::Role::SQL::ReturnsData',
);

has bind_params => (
    is  => 'ro',
    isa => CodeRef,
);

has is_multi_column => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _make_sub_from_select {
    my $class        = shift;
    my $select       = shift;
    my $bind_sub     = shift;
    my $is_multi_col = shift;

    die 'The select parameter must be do the Fey::Role::SQL::ReturnsData role'
        unless blessed $select
        && $select->can('does')
        && $select->does('Fey::Role::SQL::ReturnsData');

    if (@_) {
        return $class->_make_default_from_select_with_type(
            $select,
            $bind_sub,
            $is_multi_col,
            shift,
        );
    }
    else {
        return $class->_make_default_from_select_without_type(
            $select,
            $bind_sub,
            $is_multi_col
        );
    }
}
## use critic

sub _make_default_from_select_with_type {
    my $class        = shift;
    my $select       = shift;
    my $bind_sub     = shift;
    my $is_multi_col = shift;
    my $type         = shift;

    my $wantarray = 0;
    $wantarray = 1
        if defined $type
        && find_type_constraint($type)->is_a_type_of('ArrayRef');

    my $select_meth
        = $is_multi_col ? 'selectall_arrayref' : 'selectcol_arrayref';

    return sub {
        my $self = shift;

        my $dbh = $self->_dbh($select);

        my @select_p = (
            $select->sql($dbh), {},
            $bind_sub ? $self->$bind_sub() : (),
        );

        my $return = $dbh->$select_meth(@select_p)
            or return;

        return $wantarray ? $return : $return->[0];
    };
}

sub _make_default_from_select_without_type {
    my $class        = shift;
    my $select       = shift;
    my $bind_sub     = shift;
    my $is_multi_col = shift;

    my $select_meth
        = $is_multi_col ? 'selectall_arrayref' : 'selectcol_arrayref';

    return sub {
        my $self = shift;

        my $dbh = $self->_dbh($select);

        my @select_p = (
            $select->sql($dbh), {},
            $bind_sub ? $self->$bind_sub() : (),
        );

        my $return = $dbh->$select_meth(@select_p)
            or return;

        return wantarray ? @{$return} : $return->[0];
    };
}

1;
