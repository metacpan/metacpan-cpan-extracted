package Google::RestApi::GmailApi1::Label;

our $VERSION = '2.2.2';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      gmail_api => HasApi,
      id        => Str, { optional => 1 },
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'labels' }
sub _parent_accessor { 'gmail_api' }

sub create {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      name                    => Str,
      label_list_visibility   => Str, { optional => 1 },
      message_list_visibility => Str, { optional => 1 },
      _extra_                 => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  my %content = (
    name => delete $p->{name},
  );
  $content{labelListVisibility} = delete $p->{label_list_visibility}
    if defined $p->{label_list_visibility};
  $content{messageListVisibility} = delete $p->{message_list_visibility}
    if defined $p->{message_list_visibility};

  DEBUG("Creating label '$content{name}'");
  my $result = $self->gmail_api()->api(
    uri     => 'labels',
    method  => 'post',
    content => \%content,
  );
  return ref($self)->new(gmail_api => $self->gmail_api(), id => $result->{id});
}

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      fields => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params;
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      name                    => Str, { optional => 1 },
      label_list_visibility   => Str, { optional => 1 },
      message_list_visibility => Str, { optional => 1 },
      _extra_                 => slurpy HashRef,
    ],
  );
  my $p = named_extra($check->(@_));

  $self->require_id('update');

  my %content;
  $content{name} = delete $p->{name} if defined $p->{name};
  $content{labelListVisibility} = delete $p->{label_list_visibility}
    if defined $p->{label_list_visibility};
  $content{messageListVisibility} = delete $p->{message_list_visibility}
    if defined $p->{message_list_visibility};

  DEBUG(sprintf("Updating label '%s'", $self->{id}));
  return $self->api(
    method  => 'patch',
    content => \%content,
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting label '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub label_id { shift->{id}; }
sub gmail_api { shift->{gmail_api}; }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1::Label - Label object for Gmail.

=head1 SYNOPSIS

 # List all labels
 my @labels = $gmail_api->labels();

 # Create a new label
 my $label = $gmail_api->label()->create(name => 'My Label');

 # Get label details
 my $details = $label->get();

 # Update label
 $label->update(name => 'New Name');

 # Delete label
 $label->delete();

=head1 DESCRIPTION

Represents a Gmail label. Supports creating, reading, updating, and deleting
labels.

=head1 METHODS

=head2 create(name => $name, ...)

Creates a new label. Required parameter: name.

Optional parameters: label_list_visibility, message_list_visibility.

=head2 get(fields => $fields)

Gets label details. Requires label ID.

=head2 update(name => $name, ...)

Updates label properties. Requires label ID.

=head2 delete()

Deletes the label. Requires label ID.

=head2 label_id()

Returns the label ID.

=head2 gmail_api()

Returns the parent GmailApi1 object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
