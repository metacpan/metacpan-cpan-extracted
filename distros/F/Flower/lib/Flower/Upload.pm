package Flower::Upload;



use strict;
use warnings;
use Data::Printer;
use Mojo::Base 'Mojolicious::Controller';
use JSON::XS;
use Number::Format qw/format_bytes/;
my $json    = JSON::XS->new->allow_nonref;


# Multipart upload handler
sub store {
  my $self = shift;

  # Check file size
  return $self->render(text => 'File is too big.', status => 200)
    if $self->req->is_limit_exceeded;

  # Process uploaded file
  return $self->redirect_to('form') unless my $example = $self->param('example');
  my $size = $example->size;
  my $name = $example->filename;
  my $foo = $self->req->upload('example');

  $foo->move_to('/tmp/'.$name);

  $self->render(text => "Thanks for uploading $size byte file $name.");
};



1;

__DATA__
