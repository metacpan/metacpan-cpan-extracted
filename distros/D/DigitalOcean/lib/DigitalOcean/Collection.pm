use strict;
package DigitalOcean::Collection;
use Mouse;
use DigitalOcean::Types;

#ABSTRACT: Represents a Collection object in the DigitalOcean API

has DigitalOcean => (
    is => 'rw',
    isa => 'DigitalOcean',
    required => 1,
);

has type_name => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has json_key => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);


has objects => ( 
    is => 'rw',
    isa => 'ArrayRef[Any]',
    default => sub { [] },
);


has cur_page => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);


has last_page => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);


has params => (
    is => 'rw',
    isa => 'Undef|HashRef',
    default => undef,
);

has response => (
    is => 'rw',
    isa => 'DigitalOcean::Response',
    required => 1,
);


has pages => (
    is => 'rw',
    isa => 'DigitalOcean::Pages',
);


has next_element => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);


has total => (
    is => 'rw',
    isa => 'Int',
);


has init_objects => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef]',
    default => sub { [] },
);

sub BUILD { 
    my ($self) = @_;
    $self->_update;
}

sub _update { 
    my ($self) = @_;

    #if no request have been made yet, just set current page to 1
    if($self->cur_page == 0) {
        $self->cur_page($self->cur_page + 1);
    }
    #otherwise, set to our next page
    elsif($self->pages->next) { 
        my ($path, $cur_page) = $self->_get_path_and_page($self->pages->next);
        $self->cur_page($cur_page);
    }

    #get returned objects
    $self->objects($self->DigitalOcean->_decode_many($self->type_name, $self->response->json->{$self->json_key}));

    $self->_init_obj;

    if($self->response->links and $self->response->links->pages) {
        $self->pages($self->response->links->pages);
    }

    #only if last page was returned
    if($self->pages and $self->pages->last) {
        my ($path, $last_page) = $self->_get_path_and_page($self->pages->last);

        $self->last_page($last_page);
    }

    $self->next_element(0);

    $self->total($self->response->meta->total);
}

sub _init_obj { 
    my ($self) = @_;
    return unless $self->init_objects;

    for my $obj (@{$self->objects}) { 
        for my $arr (@{$self->init_objects}) {
            my ($init_obj_name, $init_obj) = @$arr;
            $obj->$init_obj_name($init_obj);
        }
    }
}


sub next { 
    my ($self) = @_;
    
    my $object;

    my $next_element = $self->next_element;
    my $last_index = $#{$self->objects};

    #if next element is within the array of objects we already have, just return the object
    if($next_element <= $last_index) { 
        $object = $self->objects->[$next_element];
    }
    #if we are out of elements in this set of objects and we are not on the last page, request the next page of objects
    elsif($self->cur_page < $self->last_page and $self->pages->next) { 
        $self->_request_next_page;
        $object = $self->objects->[$self->next_element];
    }
    #otherwise we are out of total elements. and will return undef

    $self->next_element($self->next_element + 1);
    return $object;
}

sub _request_next_page { 
    my ($self) = @_;
    return unless $self->pages->next;

    my ($path, $cur_page) = $self->_get_path_and_page($self->pages->next);
    $self->params->{page} = $cur_page;

    #request next set of objects
    my $do_response = $self->DigitalOcean->_GET(path => $path, params => $self->params);
    $self->response($do_response);

    $self->_update;
}

sub _get_path_and_page { 
    my ($self, $url) = @_;

    my $uri = URI->new($url);
    my $path = substr($uri->path, 4);
    my %form = $uri->query_form;

    return ($path, $form{page});
}


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::Collection - Represents a Collection object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 objects

This method returns the objcets for the current page that the collection is on.

    for my $obj (@{$collection->objects}) { 
        #do something with $obj
    } 

=head2 cur_page

This method returns the current page number that this collection is on. 0 is the default value.

=head2 last_page

This method returns the last page number of this collection is on. 1 is the default value.

=head2 params

This method is used to set the parameters in the URLs used to request the next set of objects in the collection. This should not be
called by the user directly, but rather will be passed in by L<DigitalOcean> when a subroutine that returns a collection is called.
It should be passed in when the L<DigitalOcean::Collection> object is created, because it will mess
with the paging of the objects if changed after paging has begun.

    my $do_collection = DigitalOcean::Collection->new(params => {per_page => 2});

=head2 pages

This method returns the current L<DigitalOcean::Pages> object that is associated with the L</cur_page>

=head2 next_element 

This method returns the index of the next element to be retrieved within the current array of L</objects>.
If it is greater than the last index of L</objects>, then the next page will be requested if there is one. 

=head2 total

This method returns the total number of objects in this collection.

=head2 init_objects

This should be set when creating the L<DigitalOcean::Collection>. The format is

    ArrayRef[ArrayRef]

Where the inner array references are of this format:

    ['name_of_setter_method', 'value to set the setter method to'].

Since L<DigitalOcean::Collection> classes are generic and can hold any object, this can be used to initialize 
the setter method of all objects in the collection to a certain value. For example, if you wanted a collection of
L<DigitalOcean::Domain> objects to have their DigitalOcean property set to the L<DigitalOcean> object, you could do this when creating
the collection:

    my $collection = DigitalOcean::Collection->new(
        init_objects => [['DigitalOcean', $do]],
        ... #other initialization stuff
    );

This is mainly just for use by the L<DigitalOcean> module when creating L<DigitalOcean::Collection>s.

=head2 next

This method will return the next object in the collection, and will return undef when there are no more objects
in the collection. The L</next> method automatically makes requests to the Digital Ocean API when it is time to
get the next set of elements on the next page.

    my $obj;
    while($obj = $do_collection->next) { 
        print $obj->id . "\n";
    }

    #now went through entire collection and $obj holds undef

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
