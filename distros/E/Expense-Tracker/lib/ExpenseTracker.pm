package ExpenseTracker;
{
  $ExpenseTracker::VERSION = '0.008';
}
{
  $ExpenseTracker::VERSION = '0.008';
}
use Mojo::Base 'Mojolicious';
use ExpenseTracker::Models;
use ExpenseTracker::Routes;
use Mojolicious::Plugin::Authentication;
use Digest::MD5 qw(md5 md5_hex);

# ABSTRACT: Demo app for showing the synergy between perl and javascript

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->secret("Very well hidden secret");

  # Everything can be customized with options
  my $config = $self->plugin( yaml_config => {
        file      => 'conf/config.yaml',
        stash_key => 'conf',
        class     => 'YAML::XS'
  });

  $self->{config} = $config;  
  #db connect  
  my $mode = lc( $ENV{MOJO_MODE} || 'development' );
  
  if ( !$self->can('model') ) {
    ref($self)->attr(
      'model' => sub {
        return ExpenseTracker::Models->connect(
          $config->{database}->{ $mode }->{dsn},
          $config->{database}->{ $mode }->{user},
          $config->{database}->{ $mode }->{password},
        );
      }
    );
  }

  $self->plugin(
    'authentication' => {
      'session_key' => 'wickedapp',
      'load_user'   => sub {
        my ( $app, $uid ) = @_;
        my $schema = $self->app->model;                
        return $schema->resultset('ExpenseTracker::Models::Result::User')->find($uid);          
      },
      'validate_user' => sub {
        my ( $app, $username, $pass, $extra ) = @_;

        my $schema = $self->app->model;
        my $user =
          $schema->resultset('ExpenseTracker::Models::Result::User')
          ->search_rs( { username => $username, password => md5_hex($pass) } )
          ->next();          
        
        $self->{uid} = $user->id() if defined($user);
        return $self->{uid};
      },
    }
  );

  $self->hook(after_static_dispatch => sub {
    my $c = shift;

    $self->{uid} = $c->session->{wickedapp};
    $c->session->{_menu} = defined($c->app->user)
                ? $c->app->{config}->{app_menu}->{regular}
                : $c->app->{config}->{app_menu}->{anonymous} ;
  });  
   
  # Routes
  my $r = $self->routes;
  
  #set location for controllers
  $r->namespace('ExpenseTracker::Controllers');
  
  $r->route('/')->to("site#welcome")->name('home');

  #routes to user controller
  $r->route('/login')->to('login#login')->name('login');
  $r->route('/logout')->to('login#logout')->name('logout');
  $r->route('/authenticate')->to('login#auth')->name('authenticate_html');

  my $api_routes = $r->route('/api')->over( authenticated => 1 );

  my $routes_params = {
    app_routes            => $r,
    api_base_url          => $self->{config}->{api}->{base_url},
    controllers_namespace => 'ExpenseTracker::Controllers',
    resource_names        => [ split ' ', $self->{config}->{expose_resources} ],
    app                   => $self,
  };
  
  ExpenseTracker::Routes->create_routes( $routes_params );
  
}

sub user{
  my $self = shift;
  
  return unless $self->{uid};

  return $self->{user} if (defined($self->{user}) and $self->{user}->id() == $self->{uid} );
  $self->{user} = $self->model->resultset('User')->find( $self->{uid} );
  return $self->{user};
  
}

1;

__END__
=pod
 
=head1 NAME
ExpenseTracker - main app file


=head1 VERSION

version 0.008

=cut
