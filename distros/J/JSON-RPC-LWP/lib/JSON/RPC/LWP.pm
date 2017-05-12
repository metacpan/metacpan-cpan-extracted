package JSON::RPC::LWP;
BEGIN{
  our $AUTHORITY = 'cpan:BGILLS'; # AUTHORITY
  our $VERSION = '0.007'; # VERSION
}
use 5.008;
use URI 1.58;
use LWP::UserAgent;
use JSON::RPC::Common;
use JSON::RPC::Common::Marshal::HTTP; # uses Moose

use Moose::Util::TypeConstraints;

# might as well use it, it gets loaded anyway
use JSON::RPC::Common::TypeConstraints qw(JSONValue);

subtype 'JSON.RPC.Version'
  => as 'Str'
  => where {
    $_ eq '1.0' ||
    $_ eq '1.1' ||
    $_ eq '2.0'
};

coerce 'JSON.RPC.Version'
  => from 'Int',
  => via {
    $_.'.0'
  }
;

use namespace::clean 0.20;
use Moose;

has agent => (
  is => 'rw',
  isa => 'Str',
  lazy => 1,
  clearer => 'clear_agent',
  default => sub{
    my($self) = @_;
    $self->_agent;
  },
);
around 'agent', sub{
    my($orig,$self,$agent) = @_;
    $agent = $self->$orig() unless @_ > 2;

    unless( defined $agent ){
      $agent = $self->_agent;
    }
    if( length $agent ){
      if( substr($agent,-1) eq ' ' ){
        $agent .= $self->_agent;
      }
    }
    $self->ua->agent($agent) if $self->has_ua;
    $self->marshal->user_agent($agent) if $self->has_marshal;
    $self->$orig($agent);
};

has _agent => (
  is => 'ro',
  isa => 'Str',
  builder => '_build_agent',
  init_arg => undef,
);
sub _build_agent{
  my($self) = @_;
  my $class = blessed($self) || $self;

  no strict qw'vars refs';
  if( $class eq __PACKAGE__ ){
    return "JSON-RPC-LWP/$VERSION"
  }else{
    my $version = ${$class.'::VERSION'};
    if( $version ){
      return "$class/$version";
    }else{
      return $class;
    }
  }
}

my @ua_handles = qw{
  timeout
  proxy
  no_proxy
  env_proxy
  from
  credentials
};

has ua => (
  is => 'rw',
  isa => 'LWP::UserAgent',
  lazy => 1,
  predicate => 'has_ua',
  default => sub{
    my($self) = @_;
    my $lwp = LWP::UserAgent->new(
      env_proxy => 1,
      keep_alive => 1,
      parse_head => 0,
      agent => $self->agent,
    );
  },
  handles => \@ua_handles,
);

my @marshal_handles = qw{
  prefer_get
  rest_style_methods
  prefer_encoded_get
};

has marshal => (
  is => 'rw',
  isa => 'JSON::RPC::Common::Marshal::HTTP',
  lazy => 1,
  predicate => 'has_marshal',
  default => sub{
    my($self) = @_;
    JSON::RPC::Common::Marshal::HTTP->new(
      user_agent => $self->agent,
    );
  },
  handles => \@marshal_handles,
);

my %from = (
  map( { $_, 'ua' } @ua_handles ),
  map( { $_, 'marshal' } @marshal_handles ),
);

sub BUILD{
  my($self,$args) = @_;

  while( my($key,$value) = each %$args ){
    if( exists $from{$key} ){
      my $attr = $from{$key};
      $self->$attr->$key($value);
    }
  }
}

has version => (
  is => 'rw',
  isa => 'JSON.RPC.Version',
  default => '2.0',
  coerce => 1,
);

has previous_id => (
  is => 'ro',
  isa => JSONValue,
  init_arg => undef,
  writer => '_previous_id',
  predicate => 'has_previous_id',
  clearer => 'clear_previous_id',
);

has id_generator => (
  is => 'rw',
  isa => 'Maybe[CodeRef]',
  default => undef,
);

with "MooseX::Deprecated" => {
  attributes => [ qw" id_generator previous_id " ],
};

sub call{
  my($self,$uri,$method,@rest) = @_;

  $uri = URI->new($uri) unless blessed $uri;

  my $params;
  if( @rest == 1 and ref $rest[0] ){
    ($params) = @rest;
  }else{
    $params = \@rest;
  }
  $self->{count}++;

  my $next_id = 1;
  eval {
    $self->{previous_id} = $next_id;
    # $self->_previous_id($next_id);
  };

  my $request = $self->marshal->call_to_request(
    JSON::RPC::Common::Procedure::Call->inflate(
      jsonrpc => $self->version,
      id      => $next_id,
      method  => $method,
      params  => $params,
    ),
    uri => $uri,
  );
  my $response = $self->ua->request($request);
  my $result = $self->marshal->response_to_result($response);

  return $result;
}

sub notify{
  my($self,$uri,$method,@rest) = @_;

  $uri = URI->new($uri) unless blessed $uri;

  my $params;
  if( @rest == 1 and ref $rest[0] ){
    $params = $rest[0];
  }else{
    $params = \@rest;
  }
  $self->{count}++;

  my $request = $self->marshal->call_to_request(
    JSON::RPC::Common::Procedure::Call->inflate(
      jsonrpc => $self->version,
      method  => $method,
      params  => $params,
    ),
    uri => $uri,
  );
  my $response = $self->ua->request($request);

  return $response;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
#ABSTRACT: Use any version of JSON RPC over any libwww supported transport protocols.

__END__

=pod

=encoding UTF-8

=head1 NAME

JSON::RPC::LWP - Use any version of JSON RPC over any libwww supported transport protocols.

=head1 VERSION

version 0.007

=head1 SYNOPSIS

    use JSON::RPC::LWP;

    my $rpc = JSON::RPC::LWP->new(
      from  => 'name@address.com',
      agent => 'Example ',
    );

    my $login = $rpc->call(
      'https://us1.lacunaexpanse.com/empire', # uri
      'login', # service
      [$empire,$password,$api_key] # JSON container
    );

=head1 METHODS

=over 4

=item C<< call( $uri, $method ) >>

=item C<< call( $uri, $method, {...} ) >>

=item C<< call( $uri, $method, [...] ) >>

=item C<< call( $uri, $method, param1, param2, ... ) >>

Initiate a L<JSON::RPC::Common::Procedure::Call>

Uses L<LWP::UserAgent> for transport.

Then returns a L<JSON::RPC::Common::Procedure::Return>

To check for an error use the C<has_error> method of the returned object.

=item C<< notify( $uri, $method ) >>

=item C<< notify( $uri, $method, {...} ) >>

=item C<< notify( $uri, $method, [...] ) >>

=item C<< notify( $uri, $method, param1, param2, ... ) >>

Initiate a L<JSON::RPC::Common::Procedure::Call>

Uses L<LWP::UserAgent> for transport.

Basically this is the same as a call, except without the C<id> key,
and doesn't expect a JSON RPC result.

Returns the L<HTTP::Response> from L<C<ua>|LWP::UserAgent>.

To check for an error use the C<is_error> method of the returned
response object.

=back

=head1 ATTRIBUTES

=over 4

=item C<previous_id>

This attribute is deprecated, and will always return C<1> immediately
after a call.

=item C<has_previous_id>

Returns true if the C<previous_id> has any value associated with it.

This method is deprecated.

=item C<clear_previous_id>

This method is deprecated.

Clears the previous id, useful for generators that do something different
the first time they are used.

=item C<id_generator>

This attribute is deprecated, and is no longer used.

If you modified it in a subclass:

    has '+id_generator' => (
      default => sub{sub{1}},
    );

You should change it to only be modified on older versions of this
module.

    unless( eval{ JSON::RPC::LWP->VERSION(0.007); 1 } ){
      # was always called with ( id => "1" )
      has '+id_generator' => (
        default => sub{sub{1}},
      );
    }

If anyone was actually relying on this feature it might get added back in.

=item C<version>

The JSON RPC version to use. one of 1.0 1.1 or 2.0

=item C<agent>

Get/set the product token that is used to identify the user agent on the network.
The agent value is sent as the "User-Agent" header in the requests.
The default is the string returned by the C<_agent> attribute (see below).

If the agent ends with space then the C<_agent> string is appended to it.

The user agent string should be one or more simple product identifiers
with an optional version number separated by the "/" character.

Setting this will also set C<< ua->agent >> and C<< marshal->user_agent >>.

=item C<_agent>

Returns the default agent identifier.
This is a string of the form "JSON-RPC-LWP/#.###", where "#.###" is
substituted with the version number of this library.

=item C<marshal>

An instance of L<JSON::RPC::Common::Marshal::HTTP>.
This is used to convert from a L<JSON::RPC::Common::Procedure::Call>
to a L<HTTP::Request>,
and from an L<HTTP::Response> to a L<JSON::RPC::Common::Procedure::Return>.

B<Attributes delegated to C<marshal>>

=over 4

=item C<prefer_get>

=item C<rest_style_methods>

=item C<prefer_encoded_get>

=back

=item C<ua>

An instance of L<LWP::UserAgent>.
This is used for the transport layer.

B<Attributes delegated to C<ua>>

=over 4

=item C<timeout>

=item C<proxy>

=item C<no_proxy>

=item C<env_proxy>

=item C<from>

=item C<credentials>

=back

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Brad Gilbert <b2gills@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Brad Gilbert.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
