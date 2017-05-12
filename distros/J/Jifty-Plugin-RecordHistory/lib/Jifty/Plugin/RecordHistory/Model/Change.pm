package Jifty::Plugin::RecordHistory::Model::Change;
use warnings;
use strict;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column record_class =>
        type is 'varchar',
        is mandatory,
        is immutable;

    column record_id =>
        type is 'integer',
        is mandatory,
        is immutable;

    # XXX: associate this with the app's user modl
    column created_by =>
        type is 'integer',
        label is 'Created by',
        is immutable;

    column created_on =>
        type is 'timestamp',
        label is 'Created on',
        filters are qw(Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
        is immutable;

    column type =>
        type is 'text',
        label is 'Type',
        is immutable;

    column change_fields =>
        refers_to Jifty::Plugin::RecordHistory::Model::ChangeFieldCollection by 'change';
};

sub create {
    my $self = shift;
    my %args = (
        created_by => $self->current_user->id,
        @_,
        created_on => DateTime->now->iso8601,
    );
    return $self->SUPER::create(%args);
}

sub deferred_create {
    my $self = shift;
    return $self->{deferred_create} = { @_ };
}

# a "record" method that walks around ACLs
sub __record {
    my $self = shift;
    my %args = @_;

    my $class = $args{record_class} || $self->__value('record_class');
    my $id    = $args{record_id}    || $self->__value('record_id');

    my $record = $class->new;
    $record->load($id);

    return $record;
}

sub record {
    my $self = shift;
    my $record = $self->record_class->new;
    $record->load($self->record_id);
    return $record;
}

sub delegate_current_user_can {
    my $self  = shift;
    my $right = shift;
    my %args  = @_;

    return $self->__record(%args)->current_user_can($right) if $right eq 'read';

    # only superuser can create, update, and delete change entries
    return $self->current_user->is_superuser;
}

sub add_change_field {
    my $self = shift;
    my %args = @_;

    if (my $args = delete $self->{deferred_create}) {
        $self->create(%$args);
    }

    my $change_field = Jifty::Plugin::RecordHistory::Model::ChangeField->new;
    $change_field->create(
        %args,
        change => $self,
    );
}

sub created_by {
    my $self = shift;
    my $id = $self->_value('created_by');
    my $class = Jifty->app_class('Model', 'User');

    # if there's no User class then just continue returning the id
    return $id unless $class->can('new');

    my $user = $class->new;
    $user->load($id);
    return $user;
}

1;

