package Email::Archive::Storage::MongoDB;
use Moo;
use Carp;
use Email::MIME;
use Email::Abstract;
use MongoDB;
use autodie;
with q/Email::Archive::Storage/;

has host => (
    is => 'rw',
    default => sub { 'localhost' },
);

has port => (
    is => 'rw',
    default => sub { 27017 },
);

has database => (
    is => 'rw',
);

has collection => (
    is => 'rw',
);

sub store {
  my ($self, $email) = @_;
  $email = Email::Abstract->new($email);
  $self->collection->insert({
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
  my $message = $self->collection->find_one($attribs);

  return Email::MIME->create(
    header => [
      From    => $message->{from_addr},
      To      => $message->{to_addr},
      Subject => $message->{subject},
    ],
    body => $message->{body},
  );
}

sub retrieve {
  my ($self, $message_id) = @_;
  $self->search({ message_id => $message_id });
}

sub storage_connect {
  my ($self, $mongo_con_info) = @_;
  if (defined $mongo_con_info){
    # should look like host:port:database
    my ($host, $port, $database, $collection) = split ':', $mongo_con_info;
    $self->host($host);
    $self->port($port);
    $self->database($database);
    $self->collection($collection);
  }

  my $conn = MongoDB::Connection->new(
    host => $self->host,
    port => $self->port,
  );

  my $datab = $self->database;
  my $collec = $self->collection;

  my $db = $conn->$datab;
  my $coll = $db->$collec;

  # replace name with actual collection object
  $self->collection($coll);

  return 1;
}

1;

__END__

=head1 NAME

Email::Archive::Storage::MongoDB - write emails to MongoDB

=head1 SYNOPSIS

Email::Archive::Storage::MongoDB is a storage engine for Email::Archive
to store emails in a MongoDB database.

Construction and connecting to the database is slightly different from the
default. The other methods should work like documented in Email::Archive.

    my $storage = Email::Archive::Storage::MongoDB->new(
        host       => $hostname,        # defaults to localhost
        port       => $port,            # defaults to 27017
        database   => $db_name,
        collection => $collection_name,
    );

    my $mongo_archive = Email::Archive->new(
        storage => $storage,
    );

Or
    my $mongo_archive = Email::Archive->new(
        storage => Email::Archive::Storage::MongoDB->new;
    );

The alternate construction needs a connection string passed to connect.

=head1 ATTRIBUTES

=head2 host

The database host to connect to. Default is localhost.

=head2 port

The port on the database host to connect to. Defaults to MongoDBs default
port 27017.

=head2 database

A valid MongoDB database name. If the database does not exist it will be
created.

=head2 collection

A MongoDB collection name. If the collection does not exist it will be
created automatically.

=head1 METHODS

=head2 connect

If the storage was constructed passing all the needed arguments just connect.

    $mongo_archive->connect;

Alternative connection needs to have a connection string of the format
host:port:database:collection and will override previously configured
values.

    $mongo_archive->connect("$host:$port:$dbname:$collname");

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
