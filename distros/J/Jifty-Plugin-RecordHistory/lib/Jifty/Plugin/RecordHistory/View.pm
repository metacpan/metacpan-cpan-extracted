package Jifty::Plugin::RecordHistory::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

sub mount_view {
    my ($class, $model, $vclass, $path) = @_;
    my $caller = caller(0);

    # Sanitize the arguments
    $model = ucfirst($model);
    $vclass ||= $caller.'::'.$model;
    $path ||= '/'.lc($model);

    # Load the view class, alias it, and define its object_type method
    Jifty::Util->require($vclass);
    eval qq{package $caller;
            alias $vclass under '$path'; 1} or die $@;

    # Override object_type
    no strict 'refs';
    my $object_type = $vclass."::object_type";

    # Avoid the override if object_type() is already defined
    *{$object_type} = sub { $model } unless defined *{$object_type};
}

sub object_type {
    my $self = shift;
    my $object_type = $self->package_variable('object_type') || get('object_type');

    warn "No object type found for $self"
        if !$object_type;

    return $object_type;
}

sub page_title {
    my $self = shift;
    return _('History for %1: %2',
             $self->object_type,
             $self->load_record->brief_description);
}

sub record_class {
    my $self = shift;

    # If object_type is set via set, don't cache
    if (!$self->package_variable('object_type') && get('object_type')) {
        return Jifty->app_class('Model', $self->object_type);
    }

    # Otherwise, assume object_type is permanent
    else {
        return ($self->package_variable('record_class')
            or ($self->package_variable( record_class =>
                    Jifty->app_class('Model', $self->object_type))));
    }
}

sub load_record {
    my $self = shift;

    my $id = get('id');

    my $record = $self->record_class->new;
    $record->load($id);
    return $record;
}

sub changes_for {
    my $self   = shift;
    my $record = shift;
    return $record->changes;
}

template 'index.html' => page { title => shift->page_title } content {
    show 'list';
};

template 'header' => sub {
};

template 'footer' => sub {
};

template 'list' => sub {
    my $self = shift;
    set record => $self->load_record;
    show 'header';
    show 'changes';
    show 'footer';
};

template 'no-changes' => sub {
    p {
        { class is 'no-changes' };
        _("No changes.")
    };
};

template 'changes' => sub {
    my $self    = shift;
    my $record  = get 'record';
    my $changes = get('changeset') || $self->changes_for($record);

    if ($changes->count == 0) {
        show 'no-changes';
        return;
    }

    dl {
        { class is 'changes' };

        my $prev_date = '';
        while (my $change = $changes->next) {
            my $date = $change->created_on->ymd;
            if ($date ne $prev_date) {
                dt {
                    { class is 'date' };
                    $date
                };
                $prev_date = $date;
            }

            show 'change' => $change;
        }
    };
};

template 'change' => sub {
    my $self   = shift;
    my $change = shift;

    my $template = 'change-' . $change->type;

    dd {
        { class is 'change change-' . $change->type };
        div {
            { class is 'time' };
            $change->created_on->hms
        };
        div {
            { class is 'change-details' };
            show $template => $change
        };
    };
};

template 'change-create' => sub {
    my $self   = shift;
    my $change = shift;

    span {
        show 'record_type' => $change->record;
        outs _(' created by ');
        show 'actor' => $change->created_by;
    };
};

template 'change-update' => sub {
    my $self   = shift;
    my $change = shift;

    my $change_fields = $change->change_fields;
    return if !$change_fields->count;

    show 'change-update-record' => $change;
    show 'change-update-fields' => $change;
};

template 'change-update-record' => sub {
    my $self   = shift;
    my $change = shift;
    span {
        show 'record_type' => $change->record;
        outs _(' updated by ');
        show 'actor' => $change->created_by;
    };
};

template 'change-update-fields' => sub {
    my $self   = shift;
    my $change = shift;

    my $record = $change->record;

    my @change_fields = grep { !$record->hide_change_field($_) }
                        @{ $change->change_fields->items_array_ref };

    return if !@change_fields;

    ul {
        { class is 'change-fields' };
        for my $change_field (@change_fields) {
            show 'change_field' => $change_field;
        }
    };
};

template 'change_field' => sub {
    my $self         = shift;
    my $change_field = shift;

    my $field = $change_field->field;
    my $old   = $change_field->old_value;
    my $new   = $change_field->new_value;

    li {
        { class is 'change-field' };
        span {
            class is 'field-name';
            outs $field;
        };
        outs " changed from ";
        span {
            if (!defined($old)) {
                class is 'old-value no-value';
                outs '(no value)';
            }
            else {
                class is 'old-value';
                outs $old;
            }
        };
        outs " to ";
        span {
            if (!defined($new)) {
                class is 'new-value no-value';
                outs '(no value)';
            }
            else {
                class is 'new-value';
                outs $new;
            }
        };
    };
};

template 'record_type' => sub {
    my $self   = shift;
    my $record = shift;

    (my $class = ref $record) =~ s/.*:://;
    return outs $class;
};

template 'actor' => sub {
    my $self  = shift;
    my $actor = shift;

    return outs $actor if !ref($actor);

    return outs _('somebody') if !$actor->id || !$actor->current_user_can('read');
    return outs $actor->email if $actor->can('email');
    return outs _('user #%1', $actor->id);
};

1;

