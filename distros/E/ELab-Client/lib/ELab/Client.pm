package ELab::Client;
# ABSTRACT: Access the eLabFTW API with Perl
$ELab::Client::VERSION = '0.020';
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


sub get_backup_zip {
  my $self = shift;
  my $datespan = shift;
  return $self->elab_get("backupzip/$datespan");
}



sub get_items_types {
  my $self = shift;
  return decode_json $self->elab_get("items_types/");
}


sub get_item_types {
  return get_items_types(@_);
}



sub get_status {
  my $self = shift;
  return decode_json $self->elab_get("status/");
}


sub get_experiment_states {
  return get_status(@_);
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



sub create_item {
  my $self = shift;
  my $type = shift;
  return decode_json $self->elab_post("items/$type");
}



sub create_experiment {
  my $self = shift;
  return decode_json $self->elab_post("experiments");
}



sub create_template {
  my $self = shift;
  return decode_json $self->elab_post("templates");
}



sub get_upload {
  my $self = shift;
  my $id = shift;
  return $self->elab_get("uploads/$id");
}



sub get_bookable {
  my $self = shift;
  return decode_json $self->elab_get("bookable/");
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



sub get_tags {
  my $self = shift;
  return decode_json $self->elab_get("tags/");
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
    category => { isa => 'Str', optional => 1 },
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
    category => { isa => 'Str', optional => 1 },
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



sub destroy_event {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_delete("events/$id");
}



sub get_all_events {
  my $self = shift;
  return decode_json $self->elab_get("events/");
}



sub get_event {
  my $self = shift;
  my $id = shift;
  return decode_json $self->elab_get("events/$id");
}




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


no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ELab::Client - Access the eLabFTW API with Perl

=head1 VERSION

version 0.020

=head1 SYNOPSYS

  use ELab::Client;

  my $elab = ELab::Client->new(
                    host => 'https://elab.somewhere.de/',
                    token => 'ae...d4',
              );

  my $e = $elab->post_experiment(4,
                    title => "Replacement experiment title",
                    body => "Replacement body text"
              );

=head1 METHODS

=head2 API interface

This interface is intended to be compatible to the elabapy Python client.

=head3 get_backup_zip($datespan)

  use File::Slurp;
  write_file('backup.zip', get_backup_zip('20200101-20210101'));

Generates a zip file with all experiments changed in a given time period.
The period is specified as FROM-TO in the format YYYYMMDD-YYYYMMDD.

Requires sysadmin permissions.

=head3 get_items_types()

  my $t = $elab->get_items_types();

Returns a list of database item types with their type id's.
The return value is an array reference, with the array items being hash
references for each item type.

=head3 get_item_types()

Alias for get_items_types()

=head3 get_status()

  my $s = $elab->get_status();

Returns a list of possible experiment states.
The return value is an array reference, with the array items being hash
references for each status type.

=head3 get_experiment_states()

Alias for get_status()

=head3 add_link_to_experiment($id, ...)

  my $result = add_link_to_experiment(2, link => 5)

Adds to an experiment a link to a database item with given id.
Returns a hash reference with status information.

=head3 add_link_to_item($id, ...)

  my $result = add_link_to_item(2, link => 5);

Adds to a database item a link to another database item with given id.
Returns a hash reference with status information.

=head3 add_tag_to_experiment($id, ...)

  my $result = add_tag_to_experiment(2, tag => "awesome");

Adds to an experiment the given tag (a string).
Returns a hash reference with status information.

=head3 add_tag_to_item($id, ...)

  my $result = add_tag_to_item(42, tag => "broken");

Adds to a database item the given tag (a string).
Returns a hash reference with status information.

=head3 create_item($type)

  my $e = $elab->create_item($type);

Creates a new database item of type $type. The return value is a hash 
reference with status information and the id of the new item.

=head3 create_experiment()

  my $e = $elab->create_experiment();

Creates a new experiment. The return value is a hash reference with status 
information and the id of the new experiment.

=head3 create_template()

  my $t = $elab->create_template();

Creates a new template. The return value is a hash reference with status 
information and the id of the new template.

=head3 get_upload($id)

  my $data = $elab->get_upload($id);

Get an uploaded file from its id.
The result is the raw binary data of the uploaded file.

=head3 get_bookable()

  my $b = $elab->get_bookable();

Returns a list of bookable items (i.e., equipment etc). The result is an
array reference.

=head3 get_all_experiments(...)

  my $a = $elab->get_all_experiments(limit => 15, offset => 0);

Lists the stored experiments, at most limit and starting at offset.
The return value is an array reference, where each element is a hash reference
describing an experiment (not fully, but abbreviated).

=head3 get_experiment($id)

  my $e = $elab->get_experiment($id);

Returns an experiment. The return value is a hash reference with the full 
experiment information.

=head3 get_all_items(...)

  my $a = $elab->get_all_items(limit => 25, offset => 0);

Lists database items, with maximum number limit and starting at offset.
The return value is an array reference, where each element is a hash reference
corresponding to a database item.

=head3 get_item($id)

  my $i = $elab->get_item($id);

Returns a database item. The return value is a hash reference with the full
item information.

=head3 get_tags()

  my $t = $elab->get_tags();

Returns the tags that are in use.

=head3 get_all_templates()

  my $t = $elab->get_all_templates();

Lists the available templates.
The return value is an array reference, where each element is a hash reference
describing a template.

=head3 get_template

  my $t = $elab->get_template($id);

Returns a template. The return value is a hash reference with the template
information.

=head3 post_experiment($id, ...)

  my $e = $elab->post_experiment(13,
                    title => "Updated experiment title",
                    body => "Updated experiment body text"
        );

Updates an experiment, overwriting previous values or (in the case of
'bodyappend') appending to the existing text. The following parameters can
be given:

  category    The (id of the) experiment status
  title       The experiment title
  date        The date
  body        The experiment body text
  bodyappend  Text that is appended to the experiment body text

=head3 post_item

  my $i = $elab->post_item(4,
                    title => "Database item",
                    body => "This is a piece of expensive equipment."
        );

Updates a database item, overwriting previous values or (in the case of
'bodyappend') appending to the existing text. The following parameters can
be given:

  category    The (id of the) database item type
  title       The item title
  date        The date
  body        The item body text
  bodyappend  Text that is appended to the item body text

=head3 post_template($id, ...)

  my $t = $elab->post_template(4,
                    title => "New template title",
                    body => "Lots of text"
        );

Updates a template, overwriting previous values. The following parameters can
be given:

  title       The item title
  date        The date
  body        The item body text

=head3 upload_to_experiment($id, ...)

  my $e = $elab->upload_to_experiment(13, file => "mauterndorf.jpg");

Uploads a file given by its name and appends it to the specified experiment.
The return value is a hash reference with status information.

=head3 upload_to_item

  my $e = $elab->upload_to_item(13, file => "mauterndorf.jpg");

Uploads a file given by its name and appends it to the specified database item.
The return value is a hash reference with status information.

=head3 create_event(...)

  my $e = $elab->create_event(
    start => "2019-11-30T12:00:00",
    end   => "2019-11-30T14:00:00",
    title => "Booked from API",
  );

Creates an event in the scheduler for a bookable item. The return value is
a hash reference with status information and the id of the generated event.

=head3 destroy_event($id)

  my $e = $elab->destroy_event(1);

Deletes the event with the given id.

=head3 get_all_events()

  my $e = $elab->get_all_events();

Returns a list reference with information on all events.

=head3 get_event($id)

  my $e = $elab->get_event(1);

Returns a hash reference with information on the event specified by id.

=head2 Low-level methods

=head3 elab_get($url)

  my $hashref = decode_json $self->elab_get("events/$id");

Sends a GET requrest to the server, and returns the response as JSON.

=head3 elab_delete($url)

  my $hashref = decode_json $self->elab_delete("events/$id");

Sends a DELETE requrest to the server, and returns the response as JSON.

=head3 elab_post($url, $data)

  my $hashref = decode_json $self->elab_post("events/$id", $self->buildQuery(%args));

Sends a POST requrest to the server, with the posted data supplied as an
urlencoded string (starting with '?' for convenient use of buildQuery).
Returns the obtained data as JSON.

=head1 AUTHOR

Andreas K. Huettel <dilfridge@gentoo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Andreas K. Huettel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
