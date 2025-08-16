# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Editor;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.11;

use constant {
    STATUS_PENDING      => 'pending',
    STATUS_ALL_DONE     => 'all_done',
    STATUS_SOME_DONE    => 'some_done',
    STATUS_NONE_DONE    => 'none_done',
    STATUS_ERROR        => 'error',
};

my %_default_options = (
    lifecycle => undef,
);


sub instance {
    my ($self) = @_;
    return $self->{instance};
}


sub parent {
    my ($self) = @_;
    return $self->{parent};
}


sub status {
    my ($self) = @_;
    return $self->_self_or_super->{status};
}


sub tagpool {
    my ($self) = @_;
    # We use hash here so we can de-duplicate later on.
    my %tagpools = map {$_ => $_} eval {$self->inode->tagpool};
    return values %tagpools;
}


sub apply {
    my ($self) = @_;

    if ($self->status eq STATUS_PENDING) {
        if (defined $self->{super}) {
            $self->{super}->_queue_request(@{$self->{queue}});
            @{$self->{queue}} = ();
        } else {
            croak 'Not supported';
        }
    } else {
        croak 'Cannot apply as the editor is not pending, current state: '.$self->status;
    }
}


#@returns __PACKAGE__
sub for {
    my ($self, %opts) = @_;
    my $n = __PACKAGE__->_new(parent => $self->parent, super => $self);

    foreach my $key (keys %opts) {
        croak 'Bad key: '.$key unless exists $_default_options{$key};
    }

    $n->{options} = {%{$self->{options}}, %opts};

    return $n;
}

# ----------------

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    $self->{instance} = $self->{parent}->instance unless defined $self->{instance};

    croak 'No instance is given'    unless defined $self->{instance};
    croak 'No parent is given'      unless defined $self->{parent};

    $self->{status}  = STATUS_PENDING;
    $self->{options} = {%_default_options};
    $self->{queue}   = [];

    return $self;
}

sub _self_or_super {
    my ($self) = @_;
    return defined($self->{super}) ? $self->{super} : $self;
}

sub _inode {
    my ($self) = @_;

    unless (exists $self->{inode}) {
        my $parent = $self->_self_or_super->parent;
        if ($parent->can('inode')) {
            return $self->{inode} = $parent->inode;
        } elsif ($parent->isa('File::Information::Inode') || $parent->isa('File::Information::Remote')) {
            return $self->{inode} = $parent;
        }
    }

    return $self->{inode};
}

sub _queue_request {
    my ($self, @requests) = @_;
    my $options = $self->{options};
    my @options_keys = keys %{$options};

    foreach my $request (@requests) {
        $request->{options} //= {};
        $request->{options}->{$_} //= $options->{$_} foreach @options_keys;
        push(@{$self->{queue}}, $request);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Editor - generic module for extracting information from filesystems

=head1 VERSION

version v0.11

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Editor $editor = $obj->editor;

    # ...
    
    $editor->apply;

This represents an editor that allows to edit another object.

=head1 METHODS

=head2 instance

    my File::Information $instance = $editor->instance;

Returns the instance that was used to create this object.

=head2 parent

    my $parent = $editor->parent;

Returns the parent that was used to create this object.

=head2 status

    my $status = $editor->status;

Returns the status of the editor.

=head2 tagpool

    my @tagpool = $editor->tagpool;

Returns the list of tagpools found relevant to this editor if any (See L<File::Information::Tagpool>).

B<Note:>
There is no order to the returned values. The order may change between any two calls.

=head2 apply

    $editor->apply;

Applies the changes to the file for a root editor.
Queues changes for apply on sub-editors to the root editor.

B<Note:>
When using sub-editors one must call this on all sub-editors and
then on the root editor to apply the changes.

See also:
L</for>.

=head2 for

    my File::Information::Editor $sub_editor = $editor->for(key => value, ...);

Returns an sub-editor with altered options.

See also:
L</apply>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
