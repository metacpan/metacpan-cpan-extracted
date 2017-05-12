use 5.008001;
use strict;
use warnings;
package Metabase::Backend::MongoDB;
our $VERSION = '1.000'; # VERSION

use MongoDB;
use Moose::Role;
use namespace::autoclean;

requires '_build_collection_name', '_ensure_index' ;


# XXX eventually, do some validation on this -- dagolden, 2011-06-30
has 'host' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'mongodb://localhost:27017',
  required  => 1,
);


# XXX eventually, do some validation on this -- dagolden, 2011-06-30
has 'db_name' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'metabase',
  required  => 1,
);


# XXX eventually, do some validation on this -- dagolden, 2011-07-07
has 'collection_name' => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_collection_name',
);

# XXX eventually, do some validation on this -- dagolden, 2011-06-30
# e.g. if password,then also need non-empty username
has ['username', 'password'] => (
  is      => 'ro',
  isa     => 'Str',
  default => '',
);


has 'connection' => (
    is      => 'ro',
    isa     => 'MongoDB::Connection',
    lazy    => 1,
    builder => '_build_connection',
);

sub _build_connection {
  my $self = shift;
  return MongoDB::Connection->new(
    host => $self->host,
    $self->password ? (
      db_name   => $self->db_name,
      username  => $self->username,
      password  => $self->password,
    ) : (),
  );
}


has 'coll' => (
    is      => 'ro',
    isa     => 'MongoDB::Collection',
    lazy    => 1,
    builder => '_build_coll',
);

sub _build_coll {
  my $self = shift;
  my $coll = $self->connection
    ->get_database( $self->db_name )
    ->get_collection( $self->collection_name );
  $self->_ensure_index($coll);
  return $coll;
}

#--------------------------------------------------------------------------#

sub _munge_keys {
  my ($self, $data, $from, $to) = @_;
  $from ||= '.';
  $to ||= '|';

  if ( ref $data eq 'HASH' ) {
    for my $key (keys %$data) {
      (my $new_key = $key) =~ s/\Q$from\E/$to/;
      $data->{$new_key} = delete $data->{$key};
    }
  }
  else {
    $data =~ s/\Q$from\E/$to/;
  }

  return $data;
}

1;

# ABSTRACT: Metabase backend implemented using MongoDB
#
# This file is part of Metabase-Backend-MongoDB
#
# This software is Copyright (c) 2011 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#



__END__
=pod

=head1 NAME

Metabase::Backend::MongoDB - Metabase backend implemented using MongoDB

=head1 VERSION

version 1.000

=head1 SYNOPSIS

  use Metabase::Index::MongoDB;

  Metabase::Index::MongoDB->new(
    host    => 'mongodb://localhost:27017',
    db_name => 'my_metabase',
  );

  use Metabase::Archive::MongoDB;

  Metabase::Archive::MongoDB->new(
    host    => 'mongodb://localhost:27017',
    db_name => 'my_metabase',
  );

=head1 DESCRIPTION

This distribution provides a backend for L<Metabase> using MongoDB.  There are
two modules included, L<Metabase::Index::MongoDB> and
L<Metabase::Archive::MongoDB>.  They can be used separately or together (see
L<Metabase::Librarian> for details).

The L<Metabase::Backend::MongoDB> module is a L<Moose::Role> that provides
common attributes and private helpers and is not intended to be used directly.

Common attributes are described further below.

=head1 ATTRIBUTES

=head2 host

A MongoDB connection string.  Defaults to 'mongodb://localhost:27017'.

=head2 db_name

A database name.  Defaults to 'metabase'.  To avoid collision with other
Metabase data on the same MongoDB server, users should always explicitly set
this to a unique name for a given Metabase installation.

=head2 collection_name

A collection name for the archive or table. Defaults to 'metabase_index' or
'metabase_archive'.  As long as the C<db_name> is unique, these defaults should
be safe to use for most purposes.

=head2 username

A username for MongoDB authentication.  By default, no username is used.

=head2 password

A password for MongoDB authentication.  By default, no password is used.

=head1 METHODS

=head2 connection

This returns the L<MongoDB::Connection> object that is created
when the object is instantiated.

=head2 coll

This returns the L<MongoDB::Collection> object containing
the index or archive data.

=for Pod::Coverage method_names_here

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Metabase-Backend-MongoDB>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/metabase-backend-mongodb>

  git clone https://github.com/dagolden/metabase-backend-mongodb.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

