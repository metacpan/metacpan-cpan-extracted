use strict;
use warnings;
package Test::Metabase::Client;
use base 'Metabase::Client::Simple';

use Catalyst::Test 'Metabase::Web';

our $VERSION = '0.001';

sub new {
  my ($self, $arg) = @_;
  $self->SUPER::new({
    url => 'http://metabase.cpan.example/',
    %$arg,
  });
}

sub _http_request {
  my ($self, $req) = @_;
  request($req);
}

sub _abs_url { "/$_[1]"; }

sub retrieve_fact_raw {
  my ($self, $guid) = @_;

  # What do we want to do when you're asking for a fact /with your
  # credentials/?  Let's say, for now, that you never do this...
  # -- rjbs, 2009-03-30
  my $req_url = $self->_abs_url("guid/$guid");

  my $req = HTTP::Request::Common::GET(
    $req_url,
    'Accept' => 'application/json',
  );

  my $res = $self->_http_request($req);

  Carp::confess("fact retrieval failed: " . $res->message)
    unless $res->is_success;

  my $json = $res->content;

  JSON->new->decode($json);
}


1;
