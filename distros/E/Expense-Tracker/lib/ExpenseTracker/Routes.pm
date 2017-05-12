package ExpenseTracker::Routes;
{
  $ExpenseTracker::Routes::VERSION = '0.008';
}
{
  $ExpenseTracker::Routes::VERSION = '0.008';
}

use Mojo::Util qw/camelize/;

use Lingua::EN::Inflect qw/PL/;

sub create_routes{
  my ( $self, $params ) = @_;

  $params->{app_routes}->add_shortcut(resource => sub {
    my ($r, $name ) = @_;
    
    my $plural = PL($name, 10);
    
    $params->{app}->log->debug("Creating routes for $name ( $plural ) ");
    # Generate "/$name" route
    my $resource = $r->route( ( $params->{api_base_url} || '' )."/$plural" )->to("$name#");

    # Handle POST requests - creates a new resource
    $resource->post->to('#create')->name("create_$name");
    
    $params->{app}->log->info("Created route create_$name ");

    # Handle GET requests - lists the collection of this resource
    $resource->get->to('#list')->name("list_$plural");
    $params->{app}->log->info("Created route list_$plural ");
    
    $resource = $r->route( ( $params->{api_base_url} || '' )."/$plural/:id" )->to("$name#");
    
    $resource->get->to('#show')->name("show_$name");
    $params->{app}->log->info("Created route show_$name ");
    
    $resource->delete->to('#remove')->name("delete_$name");
    $params->{app}->log->info("Created route delete_$name ");
    
    $resource->put->to('#update')->name("update_$name");
    $params->{app}->log->info("Created route update_$name ");   
    
    return $resource;
  });
  
  foreach my $resource ( @{ $params->{resource_names} } ){    
    $params->{app_routes}->resource( $resource );
  }
}

sub _add_routes_authorization {
  my $self = shift;
  
  $self->routes->add_condition(
    authenticated => sub {
      my ( $r, $c, $captures, $authenticated ) = @_;
      
      # It's ok, we know him
      return 1 if (
            (  $authenticated and  defined( $self->user ) )
         or ( !$authenticated and !defined( $self->user ) )
      );
      
      return;
    }
  );

  return;
}

1;

__END__
=pod
 
=head1 NAME
ExpenseTracker::Routes - separate the routes adding from the main app module

=head1 VERSION

version 0.008

=cut
