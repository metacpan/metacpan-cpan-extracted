# SOAP::Lite style Hoobot::Page

package Hoobot::Page;

use strict;
use warnings;
use Hoobot;
use URI;
use HTTP::Request::Common;
use XML::LibXML;

our @ISA = qw/Hoobot/;
my $parser;

# accessor
sub page {
  my $self = shift;
  $self = $self->new unless ref $self;
  return $self->{uri}{page} unless @_;

  $self->{uri}{page} = shift;

  return $self;
}

# accessor
sub skin {
  my $self = shift;
  $self = $self->new unless ref $self;
  return $self->{uri}{skin} unless @_;

  $self->{uri}{skin} = shift;

  return $self;
}

# accessor
sub site {
  my $self = shift;
  $self = $self->new unless ref $self;
  unless (@_) {
    return $self->{uri}{site} if defined $self->{uri}{site};
    return $self->{uri}{site} = 'h2g2';
  }

  $self->{uri}{site} = shift;

  return $self;
}

# accessor
sub method {
  my $self = shift;
  $self = $self->new unless ref $self;
  unless (@_) {
    return $self->{method} if defined $self->{method};
    return $self->{method} = 'GET';
  }

  $self->{method} = shift;

  return $self;
}

# method
sub clear_params {
  my $self = shift;
  $self = $self->new unless ref $self;

  $self->{params} = undef;

  return $self;
}

# accessor: add deletion etc
sub param {
  my $self = shift;
  $self = $self->new unless ref $self;

  $self->{params} ||= [];
  push @{$self->{params}}, shift, shift; # hehe, fix this code!
  
  return $self;
}

# accessor
sub response {
  my $self = shift;
  $self = $self->new unless ref $self;
  return $self->{response} unless @_;

  $self->{response} = shift;

  return $self;
}

# accessor
sub document {
  my $self = shift;
  $self = $self->new unless ref $self;
  unless (@_) {
    return $self->{document} if defined $self->{document};
    return $self->xml_parse->{document};
  }

  $self->{document} = shift;

  return $self;
}

sub prepare_update {
  my $self = shift;
  $self = $self->new unless ref $self;

  return $self;
}

# method (do the actual downloading thing)
sub update {
  my $self = shift;
  $self = $self->new unless ref $self; # does this make sense?!

  $self->prepare_update; # setup anything necessary before updating

  my $url = URI->new($self->host);
  $url->scheme or $url->scheme('http');
  $url->path_segments(
    $url->path_segments,
    'dna',
    $self->site ? $self->site : (),
    $self->skin ? $self->skin : (),
    $self->page || '',
  );

  $url->query_form(@{$self->{params}})
    if lc $self->method eq 'get' and ref $self->{params} eq 'ARRAY';

  print STDERR "Update requested: (details follow)\n";
  print STDERR "  host: ", $self->host || '', "\n";
  print STDERR "  site: ", $self->site || '', "\n";
  print STDERR "  skin: ", $self->skin || '', "\n";
  print STDERR "  page: ", $self->page || '', "\n";
  print STDERR "  url:  ", $url, "\n";
  print STDERR "  method: ", $self->method || '', "\n";

  my $request;
  if (lc($self->method) eq 'post') {
    $request = POST $url, $self->{params};
  } else {
    $request = GET $url;
  }

  my $response = $self->ua->request($request);

  $self->response($response);

  $self->post_update(); # setup anything necessary after updating

  return $self;
}

# method
sub post_update {
  my $self = shift;
  $self = $self->new unless ref $self;

  return $self;
}
#
# method: currently extracts the XML, change to callback?
sub xml_parse {
  my $self = shift;
  $self = $self->new unless ref $self;
  
  if (lc($self->response->content_type) eq 'text/html') {
    $parser ||= XML::LibXML->new;
    $self->document(
      $parser->parse_html_string(
	$self->response->content,
      ),
    );
  } elsif (lc($self->response->content_type) eq 'text/xml') {
    $parser ||= XML::LibXML->new;
    $self->document(
      $parser->parse_string(
	$self->response->content,
      ),
    );
  } else {
    warn "Couldn't parse document\n";
    print STDERR $self->response->as_string, "\n";
  }

  return $self;
}

1;
