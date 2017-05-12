package Jifty::Plugin::RecordHistory::Model::ChangeField;
use warnings;
use strict;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column change =>
        refers_to Jifty::Plugin::RecordHistory::Model::Change,
        label is 'Change',
        is immutable;

    column field =>
        type is 'varchar',
        label is 'Field',
        is immutable;

    column old_value =>
        type is 'text',
        label is 'Old value',
        is immutable;

    column new_value =>
        type is 'text',
        label is 'New value',
        is immutable;
};

sub record {
    my $self = shift;
    return $self->change->record;
}

sub delegate_current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    my $change = $args{change} || $self->change;

    $change->delegate_current_user_can($right, %args);
}

1;

