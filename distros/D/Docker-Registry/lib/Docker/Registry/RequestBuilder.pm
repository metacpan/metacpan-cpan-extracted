package Docker::Registry::RequestBuilder;
  use Moo;

  use Docker::Registry::Request;
  use Docker::Registry::Types qw(DockerRegistryURI);

  has url => (is => 'ro', coerce => 1, isa => DockerRegistryURI, required => 1);
  has api_base => (is => 'ro', default => 'v2');

  sub build_request {
    my ($self, $call) = @_;
    my $request;

    my $url_params = $self->_build_url_params($call);

    if (ref($call) eq 'Docker::Registry::Call::Repositories') {
      $request = Docker::Registry::Request->new(
        method => 'GET',
        url => (join '/', $self->url, $self->api_base, "_catalog$url_params"),
      );

    } elsif (ref($call) eq 'Docker::Registry::Call::RepositoryTags') {
      $request = Docker::Registry::Request->new(
        method => 'GET',
        url => (join '/', $self->url, $self->api_base, $call->repository, "tags/list$url_params"),
      );
    } else {
      Docker::Exception->throw(
        message => sprintf("Unknown call class: %s", ref($call)),
      );
    }

    return $request;
  }

  sub _build_url_params {
    my ($self, $call) = @_;
    my $url_params = URI->new();

    if ($call->n or $call->last) {
      if ($call->n and !$call->last) {
        $url_params->query_form(n => $call->n);
      } elsif (!$call->n and $call->last) {
        $url_params->query_form(last => $call->last);
      } else {
        $url_params->query_form(last => $call->last, n => $call->n);
      }
    }

    return $url_params->as_string;
  }


1;
