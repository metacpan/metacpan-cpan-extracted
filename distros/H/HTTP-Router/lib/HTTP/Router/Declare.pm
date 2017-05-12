package HTTP::Router::Declare;

use strict;
use warnings;
use Carp 'croak';
use Storable 'dclone';
use Devel::Caller::Perl 'called_args';
use String::CamelCase 'decamelize';
use Lingua::EN::Inflect::Number 'to_S';
use HTTP::Router;
use HTTP::Router::Route;

sub import {
    my $caller = caller;

    no strict 'refs';
    no warnings 'redefine';

    *{ $caller . '::router' } = \&routing;
    *{ $caller . '::routes' } = \&routing; # alias router

    # lexical bindings
    *{ $caller . '::match' } = sub { goto &match };
    *{ $caller . '::with'  } = sub { goto &with  };
    *{ $caller . '::to'    } = sub ($) { goto &to   };
    *{ $caller . '::then'  } = sub (&) { goto &then };
    # resource(s)
    *{ $caller . '::resource'  } = sub { goto &resource  };
    *{ $caller . '::resources' } = sub { goto &resources };
}

sub _stub {
    my $name = shift;
    return sub { croak "Can't call $name() outside routing block" };
}

{
    my @Declarations = qw(match with to then resource resources);
    for my $keyword (@Declarations) {
        no strict 'refs';
        *$keyword = _stub $keyword;
    }
}

sub routing (&) {
    my $block  = shift;
    my $router = HTTP::Router->new;

    if ($block) {
        no warnings 'redefine';

        local *match = create_match($router);
        local *with  = create_with($router);
        local *to    = sub { params => $_[0] };
        local *then  = sub { $_[0] };

        local *resource  = create_resource($router);
        local *resources = create_resources($router);

        my $root = HTTP::Router::Route->new;
        $block->($root);
    }

    return $router;
}

sub _map {
    my ($router, $block, %args) = @_;

    my $route = dclone called_args(1)->[0];
    $route->append_path($args{path})               if exists $args{path};
    $route->add_conditions(%{ $args{conditions} }) if exists $args{conditions};
    $route->add_params(%{ $args{params} })         if exists $args{params};

    return defined $block ? $block->($route) : $router->add_route($route);
}

sub create_match {
    my $router = shift;
    return sub {
        my $block = ref $_[-1] eq 'CODE' ? pop : undef;
        my %args  = ();
        $args{path}       = shift unless ref $_[0];
        $args{conditions} = shift if     ref $_[0] eq 'HASH';
        _map $router, $block, %args, @_;
    };
}

sub create_with {
    my $router = shift;
    return sub {
        my $block = ref $_[-1] eq 'CODE' ? pop : undef;
        _map $router, $block, params => @_;
    };
}

{
    my $Resource = {
        collection => {},
        member => {
            create  => { method => 'POST',   suffix => '',        action => 'create'  },
            show    => { method => 'GET',    suffix => '',        action => 'show'    },
            update  => { method => 'PUT',    suffix => '',        action => 'update'  },
            destroy => { method => 'DELETE', suffix => '',        action => 'destroy' },
            new     => { method => 'GET',    suffix => '/new',    action => 'post'    },
            edit    => { method => 'GET',    suffix => '/edit',   action => 'edit'    },
            delete  => { method => 'GET',    suffix => '/delete', action => 'delete'  },
        },
    };
    sub _resource_collection { $Resource->{collection} }
    sub _resource_member     { $Resource->{member}     }

    my $Resources = {
        collection => {
            index  => { method => 'GET',  suffix => '',     action => 'index'  },
            create => { method => 'POST', suffix => '',     action => 'create' },
            new    => { method => 'GET',  suffix => '/new', action => 'post'   },
        },
        member => {
            show    => { method => 'GET',    suffix => '',        action => 'show'    },
            update  => { method => 'PUT',    suffix => '',        action => 'update'  },
            destroy => { method => 'DELETE', suffix => '',        action => 'destroy' },
            edit    => { method => 'GET',    suffix => '/edit',   action => 'edit'    },
            delete  => { method => 'GET',    suffix => '/delete', action => 'delete'  },
        },
    };
    sub _resources_collection { $Resources->{collection} }
    sub _resources_member     { $Resources->{member}     }
}

sub _map_resources {
    my ($router, $args) = @_;

    for my $symbol (qw'collection member') {
        while (my ($key, $config) = each %{ $args->{$symbol} }) {
            $config = { method => $config } unless ref $config;

            my $action = exists $config->{action} ? $config->{action} : $key;
            my $suffix = exists $config->{suffix} ? $config->{suffix} : "/$action";
            my $prefix = $args->{"${symbol}_prefix"};

            my $path       = $prefix . $suffix;
            my $conditions = { method => $config->{method} };
            my $params     = { controller => $args->{controller}, action => $action };

            my $formatted_route = HTTP::Router::Route->new(
                path       => "${path}.{format}",
                conditions => $conditions,
                params     => $params,
            );
            $router->add_route($formatted_route);

            my $route = HTTP::Router::Route->new(
                path       => $path,
                conditions => $conditions,
                params     => $params,
            );
            $router->add_route($route);
        }
    }
}

sub _create_resources {
    my ($router, $name, $block, $args) = @_;

    my %only   = map { $_ => 1 } @{ $args->{only}   || [] };
    my %except = map { $_ => 1 } @{ $args->{except} || [] };

    for my $symbol (qw'collection member') {
        my $extra = delete $args->{$symbol}; # save extra maps

        no strict 'refs';
        my $default = exists $args->{singleton} ? &{"_resource_$symbol"}() : &{"_resources_$symbol"}();

        if (exists $args->{only}) {
            $args->{$symbol} = {
                map { $_ => $default->{$_} } grep { $only{$_} } keys %$default
            };
        }
        elsif (exists $args->{except}) {
            $args->{$symbol} = {
                map { $_ => $default->{$_} } grep { !$except{$_} } keys %$default
            };
        }
        else {
            $args->{$symbol} = $default;
        }

        $args->{$symbol} = { %{ $args->{$symbol} }, %$extra } if defined $extra;
    }

    my $decamelized = decamelize $name;
    my $singular    = to_S $decamelized;

    $args->{collection_prefix} = called_args(1)->[0]->path .
        (exists $args->{path_prefix} ? $args->{path_prefix} : "/$decamelized");
    $args->{member_prefix} = $args->{collection_prefix} .
        (exists $args->{singleton} ? '' : "/{${singular}_id}");

    $args->{controller} ||= $name;

    _map_resources($router, $args);

    if (defined $block) {
        my $route = HTTP::Router::Route->new(path => $args->{member_prefix});
        $block->($route);
    }
}

sub create_resource {
    my $router = shift;
    return sub {
        my $block = ref $_[-1] eq 'CODE' ? pop : undef;
        my $name  = shift;
        my $args  = shift || {};
        $args->{singleton} = 1;
        _create_resources $router, $name, $block, $args;
    };
}

sub create_resources {
    my $router = shift;
    return sub {
        my $block = ref $_[-1] eq 'CODE' ? pop : undef;
        my $name  = shift;
        my $args  = shift || {};
        _create_resources $router, $name, $block, $args;
    };
}

1;

=head1 NAME

HTTP::Router::Declare

=head1 SYNOPSIS

  use HTTP::Router::Declare;

  my $router = router {
      # path and params
      match '/' => to { controller => 'Root', action => 'index' };

      # path, conditions, and params
      match '/home', { method => 'GET' }
          => to { controller => 'Home', action => 'show' };
      match '/date/{year}', { year => qr/^\d{4}$/ }
          => to { controller => 'Date', action => 'by_year' };

      # path, params, and nesting
      match '/account' => to { controller => 'Account' } => then {
          match '/login'  => to { action => 'login' };
          match '/logout' => to { action => 'logout' };
      };

      # path nesting
      match '/account' => then {
          match '/signup' => to { controller => 'Users', action => 'register' };
          match '/logout' => to { controller => 'Account', action => 'logout' };
      };

      # conditions nesting
      match { method => 'GET' } => then {
          match '/search' => to { controller => 'Items', action => 'search' };
          match '/tags'   => to { controller => 'Tags', action => 'index' };
      };

      # params nesting
      with { controller => 'Account' } => then {
          match '/login'  => to { action => 'login' };
          match '/logout' => to { action => 'logout' };
          match '/signup' => to { action => 'signup' };
      };

      # match only
      match '/{controller}/{action}/{id}.{format}';
      match '/{controller}/{action}/{id}';
  };

=head1 METHODS

=head2 router $block

=head2 match $path?, $conditions?

=head2 to $params

=head2 with $params

=head2 then $block

=head2 resources $name

=head2 resource $name

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Router>, L<HTTP::Router::Route>

=cut
