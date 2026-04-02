package IPC::Manager::Base::FS::Handle;
use strict;
use warnings;

our $VERSION = '0.000010';

use Carp qw/croak/;

use parent 'IPC::Manager::Base::FS';
use Object::HashBase qw{
    +buffer
};

sub fill_buffer { croak "Not Implemented" }

sub pending_messages {
    my $self = shift;

    $self->pid_check;

    return 1 if $self->have_resume_file;
    return 1 if @{$self->{+BUFFER} // []};

    if ($self->can_select) {
        return 1 if $self->select->can_read(0);
    }
    else {
        return 1 if $self->fill_buffer;
    }

    return 0;
}

sub ready_messages {
    my $self = shift;

    $self->pid_check;

    return 1 if $self->have_resume_file;
    return 1 if @{$self->{+BUFFER} // []};

    return 0 unless $self->pending_messages;

    return 1 if $self->fill_buffer;

    return 0;
}

1;
