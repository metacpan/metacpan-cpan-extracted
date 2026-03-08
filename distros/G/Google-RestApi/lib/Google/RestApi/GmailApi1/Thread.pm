package Google::RestApi::GmailApi1::Thread;

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

sub _uri_base { 'threads' }
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

  DEBUG(sprintf("Modifying thread '%s'", $self->{id}));
  return $self->api(
    uri     => 'modify',
    method  => 'post',
    content => \%content,
  );
}

sub trash {
  my $self = shift;

  $self->require_id('trash');

  DEBUG(sprintf("Trashing thread '%s'", $self->{id}));
  return $self->api(uri => 'trash', method => 'post');
}

sub untrash {
  my $self = shift;

  $self->require_id('untrash');

  DEBUG(sprintf("Untrashing thread '%s'", $self->{id}));
  return $self->api(uri => 'untrash', method => 'post');
}

sub delete {
  my $self = shift;

  $self->require_id('delete');

  DEBUG(sprintf("Deleting thread '%s'", $self->{id}));
  return $self->api(method => 'delete');
}

sub thread_id { shift->{id}; }
sub gmail_api { shift->{gmail_api}; }

1;

__END__

=head1 NAME

Google::RestApi::GmailApi1::Thread - Thread object for Gmail.

=head1 SYNOPSIS

 # Get a thread
 my $thread = $gmail_api->thread(id => 'thread_id');
 my $details = $thread->get();

 # Modify thread labels
 $thread->modify(
   add_label_ids    => ['STARRED'],
   remove_label_ids => ['UNREAD'],
 );

 # Trash/untrash
 $thread->trash();
 $thread->untrash();

 # Permanently delete
 $thread->delete();

=head1 DESCRIPTION

Represents a Gmail thread. Supports reading, modifying labels, trashing,
and deleting threads.

=head1 METHODS

=head2 get(format => $format, fields => $fields)

Gets thread details including all messages. Requires thread ID.

Format can be 'full', 'metadata', or 'minimal'.

=head2 modify(add_label_ids => \@ids, remove_label_ids => \@ids)

Modifies the labels on all messages in the thread. Requires thread ID.

=head2 trash()

Moves the thread to trash. Requires thread ID.

=head2 untrash()

Removes the thread from trash. Requires thread ID.

=head2 delete()

Permanently deletes the thread. Requires thread ID.

=head2 thread_id()

Returns the thread ID.

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
