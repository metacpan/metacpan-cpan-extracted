package Forward::Routes::Resources::Singular;
use strict;
use warnings;
use parent qw/Forward::Routes::Resources/;


sub enabled_routes {
    my $self = shift;

    my $only = $self->{only};

    my %selected = (
        create      => 1,
        show        => 1,
        update      => 1,
        delete      => 1,
        create_form => 1,
        update_form => 1
    );

    if ($self->{only}) {
        %selected = ();
        foreach my $type (@$only) {
            $selected{$type} = 1;
        }
    }

    return \%selected;
}


sub inflate {
    my $self = shift;
    
    my $enabled_routes = $self->enabled_routes;
    my $route_name     = $self->name;
    my $ctrl           = $self->_ctrl;

    # members
    $self->add_route('/new')
      ->via('get')
      ->to("$ctrl#create_form")
      ->name($route_name.'_create_form')
      if $enabled_routes->{create_form};;

    $self->add_route('/edit')
      ->via('get')
      ->to("$ctrl#update_form")
      ->name($route_name.'_update_form')
      if $enabled_routes->{update_form};

    $self->add_route
      ->via('post')
      ->to("$ctrl#create")
      ->name($route_name.'_create')
      if $enabled_routes->{create};

    $self->add_route
      ->via('get')
      ->to("$ctrl#show")
      ->name($route_name.'_show')
      if $enabled_routes->{show};

    $self->add_route
      ->via('put')
      ->to("$ctrl#update")
      ->name($route_name.'_update')
      if $enabled_routes->{update};

    $self->add_route
      ->via('delete')
      ->to("$ctrl#delete")
      ->name($route_name.'_delete')
      if $enabled_routes->{delete};

    return $self;
}


1;
