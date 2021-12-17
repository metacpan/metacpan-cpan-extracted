package ELab::Client;
# ABSTRACT: Access the eLabFTW API with Perl
$ELab::Client::VERSION = '0.011';
use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::Params::Validate;
use JSON;
use HTTP::Request::Common qw '';

extends 'REST::Client';

has host => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has token => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has endpoint => (
  is => 'ro',
  isa => 'Str',
  default => 'api/v1/'
);


sub BUILD {
  my $self = shift;
  my $args = shift;

  $self->addHeader('Authorization', $self->token());
}

sub elab_get {
  my $self = shift;
  my $url = shift;
  my $result = $self->GET($self->endpoint().$url);
  return undef unless $result->responseCode() eq '200';
  return $result->responseContent();
}

sub elab_delete {
  my $self = shift;
  my $url = shift;
  my $result = $self->DELETE($self->endpoint().$url);
  return undef unless $result->responseCode() eq '200';
  return $result->responseContent();
}

sub elab_post {
  my $self = shift;
  my $url = shift;
  my $data = shift;
  $data =~ s/^\?//;  # buildQuery starts with "?" (makes no sense here)
  my $headers = { 'Content-Type' => 'application/x-www-form-urlencoded' };
  my $result = $self->POST($self->endpoint().$url, $data, $headers);
  return undef unless $result->responseCode() eq '200';
  return $result->responseContent();
}


# from here on we try to follow elabapy in terms of function names


sub create_experiment {
  my $self = shift;
  return decode_json $self->elab_post("experiments");
}



sub create_item {
  my $self = shift;
  my $type = shift;
  return decode_json $self->elab_post("items/$type");
}



sub create_template {
  my $self = shift;
  return decode_json $self->elab_post("templates");
}



sub get_all_experiments {
  my $self = shift;
  my (%args) = validated_hash(
    \@_,
    limit  => { isa => 'Int', default => 25 },
    offset => { isa => 'Int', default => 0 },
  );
  return decode_json $self->elab_get("experiments/?".$self->buildQuery(%args));
}



sub get_experiment {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_get("experiments/$id");
}



sub get_all_items {
  my $self = shift;
  my (%args) = validated_hash(
    \@_,
    limit  => { isa => 'Int', default => 25 },
    offset => { isa => 'Int', default => 0 },
  );
  return decode_json $self->elab_get("items/".$self->buildQuery(%args));
}




sub get_item {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_get("items/$id");
}



sub get_items_types {
  my $self = shift;
  return decode_json $self->elab_get("items_types/");
}



sub get_tags {
  my $self = shift;
  return decode_json $self->elab_get("tags/");
}



sub get_upload {
  my $self = shift;
  my $id = shift;
  return $self->elab_get("uploads/$id");
}



sub get_status {
  my $self = shift;
  return decode_json $self->elab_get("status/");
}



sub get_all_templates {
  my $self = shift;
  return decode_json $self->elab_get("templates/");
}



sub get_template {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_get("templates/$id");
}



sub post_experiment {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    title  => { isa => 'Str', optional => 1 },
    date => { isa => 'Str', optional => 1 },
    body => { isa => 'Str', optional => 1 },
    bodyappend => { isa => 'Str', optional => 1 },
  );
  return decode_json $self->elab_post("experiments/$id", $self->buildQuery(%args));
}



sub post_item {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    title  => { isa => 'Str', optional => 1 },
    date => { isa => 'Str', optional => 1 },
    body => { isa => 'Str', optional => 1 },
    bodyappend => { isa => 'Str', optional => 1 },
  );
  return decode_json $self->elab_post("items/$id", $self->buildQuery(%args));
}



sub post_template {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    title  => { isa => 'Str', optional => 1 },
    date => { isa => 'Str', optional => 1 },
    body => { isa => 'Str', optional => 1 },
  );
  return decode_json $self->elab_post("templates/$id", $self->buildQuery(%args));
}



sub add_link_to_experiment {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    link  => { isa => 'Str' },
  );
  return decode_json $self->elab_post("experiments/$id", $self->buildQuery(%args));
}



sub add_link_to_item {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    link  => { isa => 'Str' },
  );
  return decode_json $self->elab_post("items/$id", $self->buildQuery(%args));
}



sub upload_to_experiment {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    file  => { isa => 'Str' },
  );
  my $request = HTTP::Request::Common::POST(
        $self->host().$self->endpoint()."experiments/$id", 
        {
          file => [ $args{file} ]
        },
        Content_Type => 'form-data', 
        Authorization => $self->token(),
      );
  return decode_json $self->getUseragent()->request($request)->decoded_content(); 
}



sub upload_to_item {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    file  => { isa => 'Str' },
  );
  my $request = HTTP::Request::Common::POST(
        $self->host().$self->endpoint()."items/$id", 
        {
          file => [ $args{file} ]
        },
        Content_Type => 'form-data', 
        Authorization => $self->token(),
      );
  return decode_json $self->getUseragent()->request($request)->decoded_content(); 
}



sub add_tag_to_experiment {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    tag  => { isa => 'Str' },
  );
  return decode_json $self->elab_post("experiments/$id", $self->buildQuery(%args));
}



sub add_tag_to_item {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    tag  => { isa => 'Str' },
  );
  return decode_json $self->elab_post("items/$id", $self->buildQuery(%args));
}



sub get_backup_zip {
  my $self = shift;
  my $datespan = shift;
  return $self->elab_get("backupzip/$datespan");
}



sub get_bookable {
  my $self = shift;
  return decode_json $self->elab_get("bookable/");
}



sub create_event {
  my $self = shift;
  my $id = shift;
  my (%args) = validated_hash(
    \@_,
    start  => { isa => 'Str' },
    end  => { isa => 'Str' },
    title  => { isa => 'Str' },
  );
  return decode_json $self->elab_post("events/$id", $self->buildQuery(%args));
}



sub get_event {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_get("events/$id");
}



sub get_all_events {
  my $self = shift;
  return decode_json $self->elab_get("events/");
}



sub destroy_event {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_delete("events/$id");
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELab::Client - Access the eLabFTW API with Perl

=head1 VERSION

version 0.011

=head1 SYNOPSYS

  use ELab::Client;

  my $elab = ELab::Client->new(
        host => 'https://elab.somewhere.de/',
        token => 'ae...d4',
  );

  my $e = $elab->post_experiment(4,
                    title => "New experiment title",
                    body => "The new body text"
        );

This module is work in progress, and coverage of the API is by far not complete yet.

=head1 METHODS

=head2 create_experiment

Creates a new experiment:

  my $e = $elab->create_experiment();

The return value is a hash reference with fields

  result      string       'success' or error message
  id          string       id of the new experiment

=head2 create_item

Creates a new database item of type $type: 

  my $e = $elab->create_item($type);

The return value is a hash reference with fields

  result      string       'success' or error message
  id          string       id of the new item

=head2 create_template

Creates a new template:

  my $t = $elab->create_template();

The return value is a hash reference with fields

  result      string       'success' or error message
  id          string       id of the new template

=head2 get_all_experiments

Lists experiments, with maximum number limit and starting at offset.

  my $a = $elab->get_all_experiments(limit => 15, offset => 0);

The return value is an array reference, where each element is a hash reference
describing an experiment (not fully, but abbreviated).

=head2 get_experiment

Returns an experiment.

  my $e = $elab->get_experiment($id);

The return value is a hash reference with the full experiment information.

=head2 get_all_items

Lists database items, with maximum number limit and starting at offset.

  my $a = $elab->get_all_items(limit => 25, offset => 0);

The return value is an array reference, where each element is a hash reference
corresponding to a database item.

=head2 get_item

Returns a database item.

  my $i = $elab->get_item($id);

=head2 get_items_types

Returns a list of database item types.

  my $t = $elab->get_items_types();

The return value is an array reference ...

=head2 get_tags

Returns the tags of the team.

  my $t = $elab->get_tags();

=head2 get_upload

Get an uploaded file from its id

  my $data = $elab->get_upload($id);

The result is the raw binary data of the uploaded file.

=head2 get_status

Get a list of possible experiment states (statuses?)...

  my $s = $elab->get_status();

=head2 get_all_templates

  my $t = $elab->get_all_templates();

=head2 get_template

  my $t = $elab->get_template($id);

=head2 post_experiment

  my $e = $elab->post_experiment(13,
                    title => "Updated experiment title",
                    body => "Updated experiment body text"
        );

=head2 post_item

  my $i = $elab->post_item(4,
                    title => "Database item",
                    body => "here are the bodies"
        );

=head2 post_template

=head2 add_link_to_experiment

=head2 add_link_to_item

=head2 upload_to_experiment

  my $e = $elab->upload_to_experiment(13, file => "mauterndorf.jpg");

=head2 upload_to_item

  my $e = $elab->upload_to_item(13, file => "mauterndorf.jpg");

=head2 add_tag_to_experiment

=head2 add_tag_to_item

=head2 get_backup_zip

=head2 get_bookable

=head2 create_event

=head2 get_event

=head2 get_all_events

=head2 destroy_event

=head1 AUTHOR

Andreas K. Huettel <dilfridge@gentoo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Andreas K. Huettel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
