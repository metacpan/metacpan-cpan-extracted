package Email::Sender::Transport::SQLite 1.501;
# ABSTRACT: deliver mail to an sqlite db for testing

use Moo;
with 'Email::Sender::Transport';

#pod =head1 DESCRIPTION
#pod
#pod This transport makes deliveries to an SQLite database, creating it if needed.
#pod The SQLite transport is intended for testing programs that fork or that
#pod otherwise can't use the Test transport.  It is not meant for robust, long-term
#pod storage of mail.
#pod
#pod The database will be created in the file named by the C<db_file> attribute,
#pod which defaults to F<email.db>.
#pod
#pod The database will have two tables:
#pod
#pod   CREATE TABLE emails (
#pod     id INTEGER PRIMARY KEY,
#pod     body     varchar NOT NULL,
#pod     env_from varchar NOT NULL
#pod   );
#pod
#pod   CREATE TABLE recipients (
#pod     id INTEGER PRIMARY KEY,
#pod     email_id integer NOT NULL,
#pod     env_to   varchar NOT NULL
#pod   );
#pod
#pod Each delivery will insert one row to the F<emails> table and one row per
#pod recipient to the F<recipients> table.
#pod
#pod Delivery to this transport should never fail.
#pod
#pod =cut

use DBI;

has _dbh => (
  is       => 'rw',
  init_arg => undef,
);

has _dbh_pid => (
  is       => 'rw',
  init_arg => undef,
  default  => sub { $$ },
);

sub dbh {
  my ($self) = @_;

  ## no critic Punctuation
  my $existing_dbh = $self->_dbh;

  return $existing_dbh if $existing_dbh and $self->_dbh_pid == $$;

  my $must_setup = ! -e $self->db_file;
  my $dbh        = DBI->connect("dbi:SQLite:dbname=" . $self->db_file);

  $self->_dbh($dbh);
  $self->_dbh_pid($$);
  $self->_setup_dbh if $must_setup;

  return $dbh;
}

has db_file => (
  is      => 'ro',
  default => sub { 'email.db' },
);

sub _setup_dbh {
  my ($self) = @_;
  my $dbh = $self->_dbh;

  $dbh->do('
    CREATE TABLE emails (
      id INTEGER PRIMARY KEY,
      body varchar NOT NULL,
      env_from varchar NOT NULL
    );
  ');

  $dbh->do('
    CREATE TABLE recipients (
      id INTEGER PRIMARY KEY,
      email_id integer NOT NULL,
      env_to varchar NOT NULL
    );
  ');
}

sub send_email {
  my ($self, $email, $env) = @_;

  my $message = $email->as_string;
  my $to      = $env->{to};
  my $from    = $env->{from};

  my $dbh = $self->dbh;

  $dbh->do(
    "INSERT INTO emails (body, env_from) VALUES (?, ?)",
    undef,
    $message,
    $from,
  );

  my $id = $dbh->last_insert_id((undef) x 4);

  for my $addr (@$to) {
    $dbh->do(
      "INSERT INTO recipients (email_id, env_to) VALUES (?, ?)",
      undef,
      $id,
      $addr,
    );
  }

  return $self->success;
}

#pod =method retrieve_deliveries
#pod
#pod   my @deliveries = $transport->retrieve_deliveries;
#pod
#pod This method returns a list of deliveries made so far to this transport's
#pod database.  They're returned in order of insertion, and each delivery is a hash
#pod reference like this:
#pod
#pod   id       => $db_primary_key,
#pod   env_from => $envelope_sender,
#pod   env_to   => \@all_env_recipients,
#pod   message  => $text_of_email_sent
#pod
#pod More fields may be added in the future.
#pod
#pod =cut

sub retrieve_deliveries {
  my ($self) = @_;

  my $rows = $self->dbh->selectall_arrayref(
    "SELECT e.id, env_from, env_to, body
    FROM emails e
    JOIN recipients r ON r.email_id = e.id
    ORDER BY e.id"
  );

  my %delivery;

  for my $d (@$rows) {
    $delivery{$d->[0]} ||= {
      id       => $d->[0],
      env_from => $d->[1],
      env_to   => [ ],
      message  => $d->[3],
    };

    push @{ $delivery{$d->[0]}{env_to} }, $d->[2];
  }

  return @delivery{ sort { $a <=> $b } keys %delivery };
}

__PACKAGE__->meta->make_immutable;
no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::Sender::Transport::SQLite - deliver mail to an sqlite db for testing

=head1 VERSION

version 1.501

=head1 DESCRIPTION

This transport makes deliveries to an SQLite database, creating it if needed.
The SQLite transport is intended for testing programs that fork or that
otherwise can't use the Test transport.  It is not meant for robust, long-term
storage of mail.

The database will be created in the file named by the C<db_file> attribute,
which defaults to F<email.db>.

The database will have two tables:

  CREATE TABLE emails (
    id INTEGER PRIMARY KEY,
    body     varchar NOT NULL,
    env_from varchar NOT NULL
  );

  CREATE TABLE recipients (
    id INTEGER PRIMARY KEY,
    email_id integer NOT NULL,
    env_to   varchar NOT NULL
  );

Each delivery will insert one row to the F<emails> table and one row per
recipient to the F<recipients> table.

Delivery to this transport should never fail.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 retrieve_deliveries

  my @deliveries = $transport->retrieve_deliveries;

This method returns a list of deliveries made so far to this transport's
database.  They're returned in order of insertion, and each delivery is a hash
reference like this:

  id       => $db_primary_key,
  env_from => $envelope_sender,
  env_to   => \@all_env_recipients,
  message  => $text_of_email_sent

More fields may be added in the future.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
