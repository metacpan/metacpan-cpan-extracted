package NewDB;

use DB;

sub new {
    my $class = shift;

    my $self = { db => DB->new };

    bless $self, $class;

    return $self;
}

sub db { shift->{ db } }

sub dbname {
    my $self = shift;

    return $self->db->database;
}

sub init {
    my $self = shift;

    my $dbh = $self->db->retain_dbh;

    unless ( -f $self->dbname && @{ $self->db->list_tables } ) {
        warn "Creating new db...";

        $dbh->do( <<SQL );
CREATE TABLE `artist` (
  `id` INTEGER PRIMARY KEY NOT NULL,
  `name` CHARACTER VARYING(255) NOT NULL,
  UNIQUE (`name`)
);
SQL

        $dbh->do( <<SQL );
CREATE TABLE `album` (
  `id` INTEGER PRIMARY KEY NOT NULL,
  `artist_id` INTEGER,
  `title` CHARACTER VARYING(255) NOT NULL
);
SQL

        $dbh->do( <<SQL );
CREATE TABLE `genre` (
  `id` INTEGER PRIMARY KEY NOT NULL,
  `name` CHARACTER VARYING(255) NOT NULL,
  UNIQUE (`name`)
);
SQL

        $dbh->do( <<SQL );
CREATE TABLE `artist_genre_map` (
  `artist_id` INTEGER NOT NULL,
  `genre_id` INTEGER NOT NULL,
  PRIMARY KEY(`artist_id`, `genre_id`)
);
SQL

        $dbh->disconnect();
    }
}

sub cleanup {
    my $self = shift;

    unlink $self->dbname;
}

=head1 AUTHOR

vti

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
