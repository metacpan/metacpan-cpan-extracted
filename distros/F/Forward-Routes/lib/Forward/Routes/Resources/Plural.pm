package Forward::Routes::Resources::Plural;
use strict;
use warnings;
use parent qw/Forward::Routes::Resources/;


sub add_collection_route {
    my $self = shift;
    my ($pattern, @params) = @_;

    my $child = Forward::Routes->new($pattern, @params);
    $self->collection->add_child($child);

    # name
    my $collection_route_name = $pattern;
    $collection_route_name =~s|^/||;
    $collection_route_name =~s|/|_|g;


    # Auto set controller and action params and name
    $child->to($self->{_ctrl}  . '#' . $collection_route_name);
    $child->name($self->{name} . '_' . $collection_route_name);

    return $child;
}


sub collection {
    my $self = shift;
    return $self->{collection} ||= $self->add_route;
}


sub enabled_routes {
    my $self = shift;

    my $only = $self->{only};

    my %selected = (
        index       => 1,
        create      => 1,
        show        => 1,
        update      => 1,
        delete      => 1,
        create_form => 1,
        update_form => 1,
        delete_form => 1
    );

    if ($self->{only}) {
        %selected = ();
        foreach my $type (@$only) {
            $selected{$type} = 1;
        }
    }

    return \%selected;
}


sub id_constraint {
    my $self = shift;
    my (@params) = @_;

    return $self->{id_constraint} unless @params;

    $self->{id_constraint} = $params[0];

    return $self;
}


sub id_name {
    my $self = shift;
    my (@params) = @_;

    return $self->{id_name} unless @params;

    $self->{id_name} = $params[0];

    return $self;
}


sub inflate {
    my $self = shift;

    my $enabled_routes = $self->enabled_routes;
    my $route_name     = $self->name;
    my $ctrl           = $self->_ctrl;

    # collection
    my $collection = $self->collection
      if $enabled_routes->{index} || $enabled_routes->{create} || $enabled_routes->{create_form};

    $collection->add_route
      ->via('get')
      ->to($ctrl."#index")
      ->name($route_name.'_index')
      if $enabled_routes->{index};

    $collection->add_route
      ->via('post')
      ->to($ctrl."#create")
      ->name($route_name.'_create')
      if $enabled_routes->{create};

    # new resource item
    $collection->add_route('/new')
      ->via('get')
      ->to($ctrl."#create_form")
      ->name($route_name.'_create_form')
      if $enabled_routes->{create_form};


    # members
    if (    $enabled_routes->{show} || $enabled_routes->{update} || $enabled_routes->{delete}
         || $enabled_routes->{update_form} || $enabled_routes->{delete_form}
    ) {
        my $members = $self->members;

        $members->add_route
          ->via('get')
          ->to($ctrl."#show")
          ->name($route_name.'_show')
          if $enabled_routes->{show};

        $members->add_route
          ->via('put')
          ->to($ctrl."#update")
          ->name($route_name.'_update')
          if $enabled_routes->{update};

        $members->add_route
          ->via('delete')
          ->to($ctrl."#delete")
          ->name($route_name.'_delete')
          if $enabled_routes->{delete};

        $members->add_route('edit')
          ->via('get')
          ->to($ctrl."#update_form")
          ->name($route_name.'_update_form')
          if $enabled_routes->{update_form};

        $members->add_route('delete')
          ->via('get')
          ->to($ctrl."#delete_form")
          ->name($route_name.'_delete_form')
          if $enabled_routes->{delete_form};
    }

    return $self;
}


sub members {
    my $self = shift;

    return $self->{members} if $self->{members};

    my $id_constraint = $self->{id_constraint} || die 'missing id constraint';

    my $id_name = $self->id_name || 'id';

    $self->{members} = $self->add_route(':' . $id_name)
      ->constraints($id_name => $id_constraint);

    return $self->{members};
}


1;
