package Docker::Registry::Call::Repositories;
  use Moo;
  use Types::Standard qw/Int/;
  has n => (is => 'ro', isa => Int);
  has limit => (is => 'ro', isa => Int);

package Docker::Registry::Result::Repositories;
  use Moo;
  use Types::Standard qw/ArrayRef Str/;
  has repositories => (is => 'ro', isa => ArrayRef[Str]);

package Docker::Registry::Call::RepositoryTags;
  use Moo;
  use Types::Standard qw/Int Str/;
  has repository => (is => 'ro', isa => Str, required => 1);
  has n => (is => 'ro', isa => Int);
  has limit => (is => 'ro', isa => Int);

package Docker::Registry::Result::RepositoryTags;
  use Moo;
  use Types::Standard qw/ArrayRef Str/;
  has name => (is => 'ro', isa => Str, required => 1);
  has tags => (is => 'ro', isa => ArrayRef[Str], required => 1);

package Docker::Registry::V2;
  use Moo;
  use Docker::Registry::Types qw(DockerRegistryURI);
  use Types::Standard qw/Str ConsumerOf/;

  has url => (is => 'ro', coerce => 1, isa => DockerRegistryURI, required => 1);
  has api_base => (is => 'ro', default => 'v2');

  has caller => (is => 'ro', isa => ConsumerOf['Docker::Registry::IO'], default => sub {
    require Docker::Registry::IO::Simple;
    Docker::Registry::IO::Simple->new;  
  });
  has auth => (is => 'ro', isa => ConsumerOf['Docker::Registry::Auth'], lazy => 1, builder => 'build_auth' );

  sub build_auth {
    require Docker::Registry::Auth::None;
    Docker::Registry::Auth::None->new; 
  };

  use JSON::MaybeXS qw//;
  has _json => (is => 'ro', default => sub {
    JSON::MaybeXS->new;
  });
  sub process_json_response {
    my ($self, $response) = @_;
    if ($response->status == 200) {
      my $struct = eval {
        $self->_json->decode($response->content);
      };
      if ($@) {
        Docker::Registry::Exception->throw({ message => $@ });
      }
      return $struct;
    } elsif ($response->status == 401) {
      Docker::Registry::Exception::Unauthorized->throw({
        message => $response->content,
        status  => $response->status,
      });
    } else {
      Docker::Registry::Exception::HTTP->throw({
        message => $response->content,
        status  => $response->status
      });
    }
  }

  sub repositories {
    my $self = shift;
    # Inputs n, last
    #
    # GET /v2/_catalog
    #
    # Header next
    # {
    #   "repositories": [
    #     <name>,
    #     ...
    #   ]
    # }
    my $call_class = 'Docker::Registry::Call::Repositories';
    my $call = $call_class->new({ @_ });
    my $params = { };
    $params->{ n } = $call->n if (defined $call->n);
    $params->{ limit } = $call->limit if (defined $call->limit);

    my $request = Docker::Registry::Request->new(
      parameters => $params,
      method => 'GET',
      url => (join '/', $self->url, $self->api_base, '_catalog')
    );
    my $scope = 'registry:catalog:*';
    $request = $self->auth->authorize($request, $scope);
    my $response = $self->caller->send_request($request);
    my $result_class = 'Docker::Registry::Result::Repositories';
    my $result = $result_class->new($self->process_json_response($response));
    return $result;
  }

  sub repository_tags {
    my $self = shift;

    # n, last
    #GET /v2/$repository/tags/list
    #
    #{"name":"$repository","tags":["2017.09","latest"]}
    my $call_class = 'Docker::Registry::Call::RepositoryTags';
    my $call = $call_class->new({ @_ });
    my $params = { };

    $params->{ n } = $call->n if (defined $call->n);
    $params->{ limit } = $call->limit if (defined $call->limit);

    my $request = Docker::Registry::Request->new(
      parameters => $params,
      method => 'GET',
      url => (join '/', $self->url, $self->api_base, $call->repository, 'tags/list')
    );
    my $scope = sprintf 'repository:%s:%s', $call->repository, 'pull';
    $request = $self->auth->authorize($request, $scope);
    my $response = $self->caller->send_request($request);
    my $result_class = 'Docker::Registry::Result::RepositoryTags';
    my $result = $result_class->new($self->process_json_response($response));
    return $result;
  }

  sub is_registry {
    my $self = shift;
    # GET /v2
    # if (200 or 401) and (header.Docker-Distribution-API-Version eq 'registry/2.0')
  }

  # Actionable failure conditions, covered in detail in their relevant sections,
  # are reported as part of 4xx responses, in a json response body. One or more 
  # errors will be returned in the following format:
  # {
  #  "errors:" [{
  #          "code": <error identifier>,
  #          "message": <message describing condition>,
  #          "detail": <unstructured>
  #      },
  #      ...
  #  ]
  # }

  # ECR: returns 401 error body as "Not Authorized"
  sub process_error {
    
  }

  sub request {
    
  }
1;
