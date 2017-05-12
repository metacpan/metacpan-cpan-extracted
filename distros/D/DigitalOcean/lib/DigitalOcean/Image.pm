use strict;
package DigitalOcean::Image;
use Mouse;

#ABSTRACT: Represents a Region object in the DigitalOcean API

our $VERSION = '0.03';

has DigitalOcean => ( 
    is => 'rw',
    isa => 'DigitalOcean',
);


has id => ( 
    is => 'ro',
    isa => 'Num',
);


has name => (
    is => 'ro',
    isa => 'Str',
);


has type => (
    is => 'ro',
    isa => 'Str',
);


has distribution => (
    is => 'ro',
    isa => 'Str',
);


has slug => ( 
    is => 'ro',
    isa => 'Undef|Str',
    coerce => 1,
);


has public => ( 
    is => 'ro',
    isa => 'Bool',
);


has regions => ( 
    is => 'ro',
    isa => 'ArrayRef[Str]',
    coerce => 1,
);


has min_disk_size => ( 
    is => 'ro',
    isa => 'Num',
);


has created_at => ( 
    is => 'ro',
    isa => 'Str',
);


has path => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD { 
    my ($self) = @_;
    
    $self->path('images/' . $self->id . '/');
}


sub actions { 
    my ($self, $per_page) = @_;
    my $init_arr = [['DigitalOcean', $self]];
    return $self->DigitalOcean->_get_collection($self->path . 'actions', 'DigitalOcean::Action', 'actions', {per_page => $per_page}, $init_arr);
}


sub update { 
    my $self = shift;
    my (%args) = @_;

    return $self->DigitalOcean->_put_object($self->path, 'DigitalOcean::Image', 'image', \%args);
}


sub delete { 
    my ($self) = @_;
    return $self->DigitalOcean->_delete(path => $self->path);
}


sub transfer { 
    my $self = shift;
    my (%args) = @_;

    $args{type} = 'transfer';
    return $self->DigitalOcean->_post_object($self->path . 'actions', 'DigitalOcean::Action', 'action', \%args);
}


sub convert { 
    my $self = shift;
    my (%args) = @_;

    $args{type} = 'convert';
    return $self->DigitalOcean->_post_object($self->path . 'actions', 'DigitalOcean::Action', 'action', \%args);
}


sub action { 
    my ($self, $id) = @_;

    return $self->DigitalOcean->_get_object($self->path . "actions/$id", 'DigitalOcean::Action', 'action');
}


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Image - Represents a Region object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 id

A unique number that can be used to identify and reference a specific image.

=head2 name

The display name that has been given to an image. This is what is shown in the control panel and is generally a descriptive title for the image in question.

=head2 type

The kind of image, describing the duration of how long the image is stored. This is one of "snapshot", "temporary" or "backup".

=head2 distribution

This attribute describes the base distribution used for this image.

=head2 slug

A uniquely identifying string that is associated with each of the DigitalOcean-provided public images. These can be used to reference a public image as an alternative to the numeric id.

=head2 public

This is a boolean value that indicates whether the image in question is public or not. An image that is public is available to all accounts. A non-public image is only accessible from your account.

=head2 regions

This attribute is an array of the regions that the image is available in. The regions are represented by their identifying slug values.

=head2 min_disk_size

The minimum 'disk' required for a size to use this image.

=head2 created_at

A time value given in ISO8601 combined date and time format that represents when the Image was created.

=head2 path

Returns the api path for this domain

=head2 actions

This will retrieve all actions that have been executed on an Image
by returning a L<DigitalOcean::Collection> that can be used to iterate through the L<DigitalOcean::Action> objects of the actions collection. 

    my $actions_collection = $image->actions;
    my $obj;

    while($obj = $actions_collection->next) { 
        print $obj->id . "\n";
    }

If you would like a different C<per_page> value to be used for this collection instead of L<per_page|DigitalOcean/"per_page">, it can be passed in as a parameter:

    #set default for all collections to be 30
    $do->per_page(30);

    #set this collection to have 2 objects returned per page
    my $actions_collection = $image->actions(2);
    my $obj;

    while($obj = $actions_collection->next) { 
        print $obj->id . "\n";
    }

=head2 update

This method edits an existing image.

=over 4

=item

B<name> Required, String, The new name that you would like to use for the image.

=back

    my $updated_image = $image->update(name => 'newname');

This method returns the updated L<DigitalOcean::Image>.

=head2 delete

This deletes an image. This will return 1 on success and undef on failure.

=head2 transfer

This method transfers an image to another region. It returns a L<DigitalOcean::Action> object.

=over 4

=item

B<region> Required, String, The region slug that represents the region target.

=back

    my $action = $image->transfer(region => 'nyc2');

=head2 convert

This method converts an image to a snapshot, such as a backup to a snapshot. It returns a L<DigitalOcean::Action> object.

    my $action = $image->convert;

=head2 action

This will retrieve an action associated with the L<DigitalOcean::Image> object by id and return a L<DigitalOcean::Action> object.

    my $action = $image->action(56789);

=head2 id

=head2 Actions

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
