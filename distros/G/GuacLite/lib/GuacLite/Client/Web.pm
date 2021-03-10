package GuacLite::Client::Web;

use Mojo::Base 'Mojolicious';

use Mojo::File;
use Mojo::JSON;
use Mojo::URL;

use GuacLite::Client::Guacd;

use File::ShareDir;

has dist_dir => sub {
  my $cpanfile = Mojo::File::curfile->dirname->dirname->dirname->sibling('cpanfile');
  return $cpanfile->sibling('share') if -e $cpanfile;
  return Mojo::File->new(File::ShareDir::dist_dir('GuacLite'));
};

sub startup {
  my $app = shift;

  $app->commands->namespaces([
    'Mojolicious::Command',
    'GuacLite::Client::Web::Command',
  ]);

  $app->renderer->paths([
    $app->dist_dir->child('templates'),
  ]);
  $app->static->paths([
    $app->dist_dir->child('public'),
  ]);

  $app->plugin('GuacLite::Plugin::Guacd');

  my $r = $app->routes;
  $r->get('/')->to(template => 'index');
  $r->websocket('/tunnel')->to(cb => \&_tunnel)->name('tunnel');
}

sub _tunnel {
  my $c = shift;

  my $json = $c->req->params->pairs->[0];
  my $params = Mojo::JSON::from_json($json);
  my $target = Mojo::URL->new($params->{target});

  my $connection = $target->query->to_hash;
  $connection->{hostname} ||= $target->host if $target->host;
  $connection->{port}     ||= $target->port if $target->port;

  my $client = GuacLite::Client::Guacd->new(
    $params->{client}{audio}    ? (audio_mimetypes => $params->{client}{audio}   ) : (),
    $params->{client}{video}    ? (video_mimetypes => $params->{client}{video}   ) : (),
    $params->{client}{image}    ? (image_mimetypes => $params->{client}{image}   ) : (),
    $params->{client}{timezone} ? (timezone        => $params->{client}{timezone}) : (),
    $params->{client}{width}    ? (width           => $params->{client}{width}   ) : (),
    $params->{client}{height}   ? (height          => $params->{client}{height}  ) : (),
    $params->{client}{dpi}      ? (dpi             => $params->{client}{dpi}     ) : (),
    $target->protocol           ? (protocol        => $target->protocol          ) : (),
    connection_args => $connection,
  );

  return $c->guacd->tunnel($client);
}

{
  package GuacLite::Client::Web::Command::pack;

  use Mojo::Base 'Mojolicious::Command';

  has description => 'Bundle guacamole-common-js assets';
  has usage => <<"END";
  Usage: $0 pack path/to/guacamole-client/guacamole-common-js/src/main/webapp/modules/

  Bundle the assets in a given directory and write it to STDOUT.
  The resulting javascript file exposes a Guacamole global with an "initialize" method used to load the rest of the library.
  This "initialize" allows deferring loading the audio system until after a user action which is required by modern browsers.
END

  sub run {
    my ($command, $path) = @_;
    warn $path;

    die "a path is required" unless $path;
    die "$path does not exist or is not a directory" unless -d $path;

    require GuacLite::Util;
    print GuacLite::Util::pack_js($path);
  }
}

1;

