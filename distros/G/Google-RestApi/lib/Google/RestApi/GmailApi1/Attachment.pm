package Google::RestApi::GmailApi1::Attachment;

our $VERSION = '2.1.1';

use Google::RestApi::Setup;

use parent 'Google::RestApi::SubResource';

sub new {
  my $class = shift;
  state $check = signature(
    bless => !!0,
    named => [
      message => HasApi,
      id      => Str,
    ],
  );
  return bless $check->(@_), $class;
}

sub _uri_base { 'attachments' }
sub _parent_accessor { 'message' }

sub get {
  my $self = shift;

  $self->require_id('get');

  return $self->api();
}

sub attachment_id { shift->{id}; }
sub message { shift->{message}; }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1::Attachment - Attachment object for Gmail messages.

=head1 SYNOPSIS

 # Get an attachment from a message
 my $att = $message->attachment(id => 'att_id');
 my $data = $att->get();
 # $data->{data} contains base64url-encoded attachment body

=head1 DESCRIPTION

Represents an attachment on a Gmail message. Supports retrieving attachment
data.

=head1 METHODS

=head2 get()

Gets attachment data. Returns a hashref with 'data' (base64url-encoded body)
and 'size' fields.

=head2 attachment_id()

Returns the attachment ID.

=head2 message()

Returns the parent Message object.

=head1 AUTHORS

=over

=item

Robin Murray mvsjes@cpan.org

=back

=head1 COPYRIGHT

Copyright (c) 2019-2026 Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
