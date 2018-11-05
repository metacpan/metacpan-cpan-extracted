package Docker::Registry::IO::Simple;
  use Moo;
  use Types::Standard qw/Bool/;
  with 'Docker::Registry::IO';

  use HTTP::Tiny;
  use Data::Dumper;

  has debug => (is => 'rw', isa => Bool, default => 0);

  has ua => (is => 'ro', default => sub {
    HTTP::Tiny->new(
      max_redirect => 0,
      agent => 'Docker::Registry Perl client' . $Docker::Registry::VERSION,
      timeout => 60,
    );
  }); 

  sub send_request {
    my ($self, $request) = @_;
    my $headers    = $request->header_hash;

    # HTTP::Tiny derives the Host header from the URL. It's an error to set it.
    delete $headers->{Host};

    print Dumper($request) if ($self->debug);

    my $response = $self->ua->request(
      $request->method,
      $request->url,
      {
        headers => $headers,
        (defined $request->content)?(content => $request->content):(),
      }
    );
    print Dumper($response) if ($self->debug);

    return Docker::Registry::Response->new(
      status => $response->{status},
      content => $response->{content},
      headers => $response->{headers}
    );
  }

1;
