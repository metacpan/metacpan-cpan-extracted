package Email::Archive;
use Moo;
use Email::Archive::Storage::DBI;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

has storage => (
  is    => 'rw',
  does  => 'Email::Archive::Storage',
  handles     => {
    store    => 'store',
    retrieve => 'retrieve',
    connect  => 'storage_connect',
  },
  lazy  => 1,
  default => sub { Email::Archive::Storage::DBI->new }
);

1;

__END__

=head1 NAME

Email::Archive - write emails to a database, fetch them

=head1 WARNING!

I only uploaded this to get it out there and kick myself into making it more
useful. As you can see it's not documented or tested yet. I put this together
mostly in one evening in a coffeeshop. It shows in some ways. caveat programmer.

=head1 SYNOPSIS

Email::Archive provides an interface to store emails.

The default storage is Email::Archive::Storage::DBI that uses DBI.
All dokumented examples assume you use this default. For information
on how to use different engines see those modules documentation.

    my $email_archive = Email::Archive->new;
    $email_archive->connect($dsn);
    $email_archive->store($msg);

    $email_archive->retrieve($msg_id);
    $email_archive->search({ from_addr => $from });

=head1 ATTRIBUTES

=head2 storage

Defaults to Email::Archive::Storage::DBI->new.

    my $e = Email::Archive->new;

is equvalent to

    my $storage = Email::Archive::Storage::DBI->new;
    my $e = Email::Archive->new(
        storage => $storage,
    );

This usage will be necessary if a storage different form 
Email::Archive::Storage::DBI is used.

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
