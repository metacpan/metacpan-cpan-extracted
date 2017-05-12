package Jifty::DBI::Filter::Boolean;

use warnings;
use strict;

use base 'Jifty::DBI::Filter';

use constant TRUE_VALUES  => qw(1 t true y yes TRUE);
use constant FALSE_VALUES => ('', qw(0 f false n no FALSE));

sub _is_true {
    my $self = shift;
    my $value = shift;

    no warnings 'uninitialized';

    for ($self->TRUE_VALUES, map { "'$_'" } $self->TRUE_VALUES) {
        return 1 if $value eq $_;
    }

    return 0;
}

sub _is_false {
    my $self = shift;
    my $value = shift;

    return 1 if not defined $value;

    for ($self->FALSE_VALUES, map { "'$_'" } $self->FALSE_VALUES) {
        return 1 if $value eq $_;
    }

    return 0;
}

=head1 NAME

Jifty::DBI::Filter::Boolean - Encodes booleans

=head1 DESCRIPTION

=head2 decode

Transform the value into 1 or 0 so Perl's concept of the value agrees
with the database's concept of the value. (For example, 't' and 'f'
might be used in the database, but 'f' is true in Perl)

=cut

sub decode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless defined $$value_ref;

    if ($self->_is_true($$value_ref)) {
        $$value_ref = 1;
    }
    elsif ($self->_is_false($$value_ref)) {
        $$value_ref = 0;
    }
    else {
        $self->handle->log("The value '$$value_ref' does not look like a boolean. Defaulting to false.");
        $$value_ref = 0;
    }
}

=head2 encode

Transform the value to the canonical true or false value as expected by the
database.

=cut

sub encode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless defined($$value_ref) or $self->column->mandatory;
    return if uc($$value_ref||'') eq "NULL" and not $self->column->mandatory;

    if ($self->_is_true($$value_ref)) {
        $$value_ref = $self->handle->canonical_true;
    }
    elsif ($self->_is_false($$value_ref)) {
        $$value_ref = $self->handle->canonical_false;
    }
    else {
        $self->handle->log("The value '$$value_ref' does not look like a boolean. Defaulting to false.");
        $$value_ref = $self->handle->canonical_false;
    }
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>

=cut

1;
