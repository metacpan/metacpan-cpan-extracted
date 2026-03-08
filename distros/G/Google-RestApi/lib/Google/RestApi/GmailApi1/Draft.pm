package Google::RestApi::GmailApi1::Draft;

our $VERSION = '2.1.1';

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

sub _uri_base { 'drafts' }
sub _parent_accessor { 'gmail_api' }

sub create {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      to           => Str,
      subject      => Str,
      body         => Str,
      from         => Str, { optional => 1 },
      cc           => Str, { optional => 1 },
      bcc          => Str, { optional => 1 },
      content_type => Str, { default => 'text/plain' },
    ],
  );
  my $p = $check->(@_);

  my $raw = $self->gmail_api()->_build_mime(%$p);

  DEBUG("Creating draft");
  my $result = $self->gmail_api()->api(
    uri     => 'drafts',
    method  => 'post',
    content => { message => { raw => $raw } },
  );
  return ref($self)->new(gmail_api => $self->gmail_api(), id => $result->{id});
}

sub create_raw {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      raw => Str,
    ],
  );
  my $p = $check->(@_);

  DEBUG("Creating draft from raw message");
  my $result = $self->gmail_api()->api(
    uri     => 'drafts',
    method  => 'post',
    content => { message => { raw => $p->{raw} } },
  );
  return ref($self)->new(gmail_api => $self->gmail_api(), id => $result->{id});
}

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

sub update {
  my $self = shift;
  state $check = signature(
    bless => !!0,
    named => [
      to           => Str,
      subject      => Str,
      body         => Str,
      from         => Str, { optional => 1 },
      cc           => Str, { optional => 1 },
      bcc          => Str, { optional => 1 },
      content_type => Str, { default => 'text/plain' },
    ],
  );
  my $p = $check->(@_);

  $self->require_id('update');

  my $raw = $self->gmail_api()->_build_mime(%$p);

  DEBUG(sprintf("Updating draft '%s'", $self->{id}));
  return $self->api(
    method  => 'put',
    content => { message => { raw => $raw } },
  );
}

sub send {
  my $self = shift;

  $self->require_id('send');

  DEBUG(sprintf("Sending draft '%s'", $self->{id}));
  return $self->gmail_api()->api(
    uri     => 'drafts/send',
    method  => 'post',
    content => { id => $self->{id} },
  );
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting draft '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub draft_id { shift->{id}; }
sub gmail_api { shift->{gmail_api}; }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1::Draft - Draft object for Gmail.

=head1 SYNOPSIS

 # Create a draft
 my $draft = $gmail_api->draft()->create(
   to      => 'recipient@example.com',
   subject => 'Draft subject',
   body    => 'Draft body',
 );

 # Get draft details
 my $details = $draft->get();

 # Update draft
 $draft->update(
   to      => 'recipient@example.com',
   subject => 'Updated subject',
   body    => 'Updated body',
 );

 # Send draft
 $draft->send();

 # Delete draft
 $draft->delete();

=head1 DESCRIPTION

Represents a Gmail draft. Supports creating, reading, updating, sending,
and deleting drafts.

=head1 METHODS

=head2 create(to => $to, subject => $subject, body => $body, ...)

Creates a new draft. Required parameters: to, subject, body.

Optional parameters: from, cc, bcc, content_type.

=head2 create_raw(raw => $base64url)

Creates a draft from a pre-encoded raw MIME message.

=head2 get(format => $format, fields => $fields)

Gets draft details. Requires draft ID.

=head2 update(to => $to, subject => $subject, body => $body, ...)

Updates the draft content. Requires draft ID.

=head2 send()

Sends the draft. Requires draft ID.

=head2 delete()

Deletes the draft. Requires draft ID.

=head2 draft_id()

Returns the draft ID.

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
