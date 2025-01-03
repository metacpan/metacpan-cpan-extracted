package Fey::SQL::Fragment::Where::Comparison;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Fey::Exceptions qw( param_error );
use Fey::Literal;
use Fey::Placeholder;
use Fey::Types qw( ArrayRef WhereClauseSide Str );
use Scalar::Util qw( blessed );

use Moose 2.1200;

has '_lhs' => (
    is       => 'ro',
    isa      => WhereClauseSide,
    required => 1,
);

has '_operator' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has '_rhs' => (
    is       => 'ro',
    isa      => ArrayRef [WhereClauseSide],
    required => 1,
);

has '_bind_params' => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

our $eq_comp_re = qr/^(?:=|!=|<>)$/;
our $in_comp_re = qr/^(?:not\s+)?in$/i;

sub BUILDARGS {
    my $class             = shift;
    my $auto_placeholders = shift;
    my $lhs               = shift;
    my $operator          = shift;
    my @rhs               = @_;

    my @bind;
    for ( $lhs, @rhs ) {
        if ( defined $_ && blessed $_ && $_->can('is_comparable') ) {
            if ( $_->can('bind_params') ) {
                push @bind, $_->bind_params();
            }

            next;
        }

        if ( defined $_ && blessed $_ ) {
            if ( overload::Overloaded($_) ) {

                # This "de-references" the value, which will make
                # things simpler when we pass it to DBI, test
                # code, etc. It works fine with numbers, more or
                # less (see Fey::Literal).
                $_ .= q{};
            }
            else {
                param_error
                    "Cannot pass an object as part of a where clause comparison"
                    . " unless that object does Fey::Role::Comparable or is overloaded.";
            }
        }

        if ( defined $_ && $auto_placeholders ) {
            push @bind, $_;

            $_ = Fey::Placeholder->new();
        }
        else {
            $_ = Fey::Literal->new_from_scalar($_);
        }

    }

    if ( grep { $_->does('Fey::Role::SQL::ReturnsData') } @rhs ) {
        param_error
            "Cannot use a subselect on the right-hand side with $operator"
            unless $operator =~ /$eq_comp_re|$in_comp_re/;
    }

    if ( defined $operator && lc $operator eq 'between' ) {
        param_error "The BETWEEN operator requires two arguments"
            unless @rhs == 2;
    }

    if ( @rhs > 1 ) {
        param_error
            "Cannot pass more than one right-hand side argument with $operator"
            unless $operator =~ /^(?:$in_comp_re|between)$/i;
    }

    return {
        _lhs         => $lhs,
        _operator    => $operator,
        _rhs         => \@rhs,
        _bind_params => \@bind,
    };
}

sub sql {
    my $self = shift;
    my $dbh  = shift;

    my $sql = $self->_lhs()->sql_or_alias($dbh);

    if (   $self->_operator() =~ /$eq_comp_re/
        && $self->_rhs()->[0]->isa('Fey::Literal::Null') ) {
        return (
            $sql
                . (
                $self->_operator() eq '='
                ? ' IS NULL'
                : ' IS NOT NULL'
                )
        );
    }

    if ( lc $self->_operator() eq 'between' ) {
        return (  $sql
                . ' BETWEEN '
                . $self->_rhs()->[0]->sql_or_alias($dbh) . ' AND '
                . $self->_rhs()->[1]->sql_or_alias($dbh) );
    }

    if ( $self->_operator() =~ /$in_comp_re/ ) {
        return (
                  $sql . ' '
                . ( uc $self->_operator() ) . ' ('
                . (
                join ', ',
                map { $_->sql_or_alias($dbh) } @{ $self->_rhs() }
                )
                . ')'
        );
    }

    if (   $self->_operator() =~ /$eq_comp_re/
        && @{ $self->_rhs() } == 1
        && blessed $self->_rhs()->[0]
        && $self->_rhs()->[0]->does('Fey::Role::SQL::ReturnsData') ) {
        return (  $sql . ' '
                . $self->_operator() . ' ('
                . $self->_rhs()->[0]->sql_or_alias($dbh)
                . ')' );
    }

    return (  $sql . ' '
            . $self->_operator() . ' '
            . $self->_rhs()->[0]->sql_or_alias($dbh) );
}

sub bind_params {
    return @{ $_[0]->_bind_params() };
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a comparison in a WHERE clause

__END__

=pod

=encoding UTF-8

=head1 NAME

Fey::SQL::Fragment::Where::Comparison - Represents a comparison in a WHERE clause

=head1 VERSION

version 0.44

=head1 DESCRIPTION

This class represents a comparison in a WHERE clause.

It is intended solely for internal use in L<Fey::SQL> objects, and as
such is not intended for public use.

=head1 BUGS

See L<Fey> for details on how to report bugs.

Bugs may be submitted at L<https://github.com/ap/Fey/issues>.

=head1 SOURCE

The source code repository for Fey can be found at L<https://github.com/ap/Fey>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
