package Google::RestApi::GmailApi1::Message;

our $VERSION = '2.2.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

use aliased 'Google::RestApi::GmailApi1::Attachment';

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

sub _uri_base { 'messages' }
sub _parent_accessor { 'gmail_api' }

sub get {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      format => Str, { optional => 1 },
      fields => Str, { optional => 1 },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('get');

  my %params;
  $params{format} = $p->{format} if defined $p->{format};
  $params{fields} = $p->{fields} if defined $p->{fields};

  return $self->api(params => \%params);
}

sub modify {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      add_label_ids    => ArrayRef[Str], { default => [] },
      remove_label_ids => ArrayRef[Str], { default => [] },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('modify');

  my %content;
  $content{addLabelIds} = $p->{add_label_ids} if $p->{add_label_ids}->@*;
  $content{removeLabelIds} = $p->{remove_label_ids} if $p->{remove_label_ids}->@*;

  DEBUG(sprintf("Modifying message '%s'", $self->{id}));
  return $self->api(
    uri     => 'modify',
    method  => 'post',
    content => \%content,
  );
}

sub trash {
  my $self = shift;

  $self->require_id('trash');

  DEBUG(sprintf("Trashing message '%s'", $self->{id}));
  return $self->api(uri => 'trash', method => 'post');
}

sub untrash {
  my $self = shift;

  $self->require_id('untrash');

  DEBUG(sprintf("Untrashing message '%s'", $self->{id}));
  return $self->api(uri => 'untrash', method => 'post');
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting message '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub attachment {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      id => Str,
    ],
  );
  my $p = $check->(@_);

  $self->require_id('attachment');

  return Attachment->new(message => $self, %$p);
}

sub message_id { shift->{id}; }
sub gmail_api { shift->{gmail_api}; }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1::Message - Message object for Gmail.

=head1 SYNOPSIS

 # Get a message
 my $message = $gmail_api->message(id => 'msg_id');
 my $details = $message->get();
 my $metadata = $message->get(format => 'metadata');

 # Modify message labels
 $message->modify(
   add_label_ids    => ['STARRED'],
   remove_label_ids => ['UNREAD'],
 );

 # Trash/untrash
 $message->trash();
 $message->untrash();

 # Permanently delete
 $message->delete();

 # Get an attachment
 my $att = $message->attachment(id => 'att_id');
 my $data = $att->get();

=head1 DESCRIPTION

Represents a Gmail message. Supports reading, modifying labels, trashing,
and deleting messages, as well as accessing attachments.

=head1 METHODS

=head2 get(format => $format, fields => $fields)

Gets message details. Requires message ID.

Format can be 'full', 'metadata', 'minimal', or 'raw'.

=head2 modify(add_label_ids => \@ids, remove_label_ids => \@ids)

Modifies the labels on a message. Requires message ID.

=head2 trash()

Moves the message to trash. Requires message ID.

=head2 untrash()

Removes the message from trash. Requires message ID.

=head2 delete()

Permanently deletes the message. Requires message ID.

=head2 attachment(id => $id)

Returns an Attachment object for the given attachment ID.

=head2 message_id()

Returns the message ID.

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
