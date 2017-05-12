package Email::Archive::Storage::DBIC;
use Moo;
use Carp;
use Email::MIME;
use Email::Abstract;
use Email::Archive::Storage::DBIC::Schema;
use autodie;
use Try::Tiny;
with q/Email::Archive::Storage/;

has schema => (
  is => 'rw',
  isa => sub {
    ref $_[0] eq 'Email::Archive::Storage::DBIC::Schema' or die "schema must be a Email::Archive::Storage::DBIC schema",
  },
);

sub store {
  my ($self, $email) = @_;
  $email = Email::Abstract->new($email);
  $self->schema->resultset('Messages')->update_or_create({
    message_id => $email->get_header('Message-ID'),
    from_addr  => $email->get_header('From'),
    to_addr    => $email->get_header('To'),
    date       => $email->get_header('Date'),
    subject    => $email->get_header('Subject'),
    body       => $email->get_body,
  });
}

sub search {
  my ($self, $attribs) = @_;
  my $message = $self->schema
                  ->resultset('Messages')
                  ->find($attribs);
  return Email::MIME->create(
    header => [
      From    => $message->from_addr,
      To      => $message->to_addr,
      Subject => $message->subject,
    ],
    body => $message->body,
  );
}

sub retrieve {
  my ($self, $message_id) = @_;
  $self->search({ message_id => $message_id });
}

sub _deploy {
  my ($self) = @_;
  $self->schema->deploy;
}

sub _deployed {
  my ($self) = @_;
  my $deployed = 1;
  try {
      # naive check if table metadata exists
      $self->schema->resultset('Metadata')->all;
  }
  catch {
      $deployed = 0;
  };

  return $deployed;
}

sub storage_connect {
  my ($self, $dsn) = @_;
  $self->schema(Email::Archive::Storage::DBIC::Schema->connect($dsn));
  my $deployed = $self->_deployed;
  $self->_deploy unless $deployed;
}

1;

__END__

=head1 NAME

Email::Archive::Storage::DBIC - write emails to relational databases

=head1 SYNOPSIS

Email::Archive::Storage::DBIC is a storage engine for Email::Archive
to store emails in databases utilizing DBIx::Class.

All methods should work like documented in Email::Archive. Construction
is slightly different as you have to tell Email::Archive to use the storage.

    my $dbic_archive = Email::Archive->new(
        storage => Email::Archive::Storage::DBIC->new,
    );

=head1 METHODS

=head2 connect

Takes a DBI connection string as parameter.

    $email_archive->connect('dbi:SQLite:dbname=emails');

For more information see DBI documentation.

If the database schema does not exist it will be deployed automatically by
the connect method.

=head2 store

    $email_archive->store($msg);

Where $msg could be anything feedable to Email::Abstract. That is a raw
email, an Email::MIME object or even an Email::Abstract object.

The message will be stored in the messages table of the connected database.

=head2 search

    $email_archive->search($attributes);

Search the database for emails where $attributes is a hashref containing
the fields to search and the values filter.

    $attributes = { from_addr => $addr };

Will return the first found result as Email::MIME object.

    $email_archive->search({ message_id => $some_id });

Is exactly the same as retrieval by Message-ID.

=head2 retrieve

    $email_archive->retrieve($msg_id);

Retrieve emails by Message-ID. Is a shortcut for

    $email_archive->search({ message_id => $some_id });

=head1 LICENSE

This library may be used under the same terms as Perl itself.

=head1 AUTHOR AND COPYRIGHT

Copyright (c) 2010, 2011 Chris Nehren C<apeiron@cpan.org>.
