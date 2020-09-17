package LinkEmbedder::Link::Dropbox;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Dropbox';
has provider_url  => sub { Mojo::URL->new('https://dropbox.com') };

1;
