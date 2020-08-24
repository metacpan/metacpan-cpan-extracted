package Mail::MtPolicyd::Connection::Sql;

use Moose;

extends 'Mail::MtPolicyd::Connection';

# ABSTRACT: Connection pool sql connection object
our $VERSION = '2.05'; # VERSION


use DBI;

has 'dsn' => ( is => 'ro', isa => 'Str', required => 1 );
has 'user' => ( is => 'ro', isa => 'Str', default => '' );
has 'password' => ( is => 'ro', isa => 'Str', default => '' );

has 'handle' => ( is => 'rw', isa => 'DBI::db', lazy => 1,
    default => sub {
      my $self = shift;
      return $self->_create_handle;
    },
    handles => [ 'disconnect' ],
);

sub _create_handle {
  my $self = shift;
  my $handle = DBI->connect(
    $self->dsn,
    $self->user,
    $self->password,
    {
      RaiseError => 1,
      PrintError => 0,
      AutoCommit => 1,
      mysql_auto_reconnect => 1,
    },
  );
  return $handle;
}

sub reconnect {
  my $self = shift;
  $self->handle( $self->_create_handle );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Connection::Sql - Connection pool sql connection object

=head1 VERSION

version 2.05

=head1 SYNOPSIS

  <Connection db>
    module = "Sql"
    # see perldoc DBI for syntax of dsn connection string
    dsn = "dbi:SQLite:dbname=/var/lib/mtpolicyd/mtpolicyd.sqlite"
    # user = "mtpolicyd"
    # user = "secret"
  </Connection>

=head1 PARAMETERS

=over

=item dsn (required)

A perl DBI connection string.

Examples:

  dbi:SQLite:dbname=/var/lib/mtpolicyd/mtpolicyd.sqlite
  dbi:SQLite::memory:
  DBI:mysql:database=test;host=localhost

see L<DBI>

=item user (default: '')

A username if required for connection.

=item password (default: '')

A password if required for user/connection.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
