package Froody::Renderer::json;
use strict;
use warnings;

use JSON::Syck;

use Froody::Response;
use Froody::Response::Terse;
use Encode;

# If we don't know how to do it ourselves, convert to
# a terse and try again
*Froody::Response::render_json = sub {
  my $self = shift;
  return $self->as_terse->render_json;
};

# Terse format just gets the main data structure out
# and renders it with JSON
*Froody::Response::Terse::render_json = sub {
  my $self = shift;
  local $JSON::Syck::ImplicitUnicode = 1; # bah.
  return Encode::encode_utf8( # BAH
    JSON::Syck::Dump({ stat => $self->status, data => $self->content })
  );
};

1;