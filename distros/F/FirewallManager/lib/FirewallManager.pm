package FirewallManager;
use Mojo::Base 'Mojolicious';

use 5.012;
use Data::Dumper;
use Mojo::Headers;

# This method will run once at server start
sub startup {
  my $self = shift;

  my $db_params = {
    "dsn"      => "DBI:MariaDB:database=eladmin",
    "username" => "careline",
    "password" => "Cisc0123",
    #"options"  => { mysql_enable_utf8 => 1 }
  };

  my $headers = Mojo::Headers->new;
  $headers->access_control_allow_origin;
  # Load configuration from hash returned by config file
  my $config    = $self->plugin('Config');
  my $api_route = $self->plugin('Crud');
  $self->plugin( 'DBI', $db_params );
  $self->plugin( 'CORS' );

  #say Dumper keys %$self;
  say Dumper $self->dbi;

  # Configure the application
  $self->secrets( $config->{secrets} );

  # Router
  my $r = $self->routes;
  $r->api_routes( { name => "Device" } );
  $r->api_routes( { name => "Firewall" } );

  #say Dumper $self->ua;
  # Normal route to controller
  #$r->get('/')->to('example#welcome');
}

1;
