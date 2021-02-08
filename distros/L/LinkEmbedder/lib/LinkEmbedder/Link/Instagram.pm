package LinkEmbedder::Link::Instagram;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Instagram';
has provider_url  => sub { Mojo::URL->new('https://instagram.com') };

1;
