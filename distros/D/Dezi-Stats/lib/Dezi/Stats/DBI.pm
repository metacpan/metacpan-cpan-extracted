package Dezi::Stats::DBI;

use warnings;
use strict;
use base 'Dezi::Stats';
use Carp;
use DBIx::Connector;
use DBIx::InsertHash;

our $VERSION = '0.001006';

=head1 NAME

Dezi::Stats::DBI - store Dezi statistics in a database

=head1 SYNOPSIS

 # see Dezi::Stats

=head1 DESCRIPTION

Dezi::Stats::DBI logs statistics to any backend supported by DBI.
This class uses DBIx::Connector to manage a persistent DBI connection.

=head1 METHODS

=head2 init_store()

Sets up the internal database handle (accessible via conn() attribute).

=cut

sub init_store {
    my $self     = shift;
    my $dsn      = delete $self->{dsn} or croak "dsn required";
    my $username = delete $self->{username} or croak "username required";
    my $password = delete $self->{password} or croak "password required";
    $self->{table_name} ||= 'dezi_stats';
    $self->{conn} = DBIx::Connector->new(
        $dsn,
        $username,
        $password,
        {   RaiseError => 1,
            AutoCommit => 1,
        }
    );
    $self->{conn}->mode('fixup');    # ping only on failure
    $self->{ih} = DBIx::InsertHash->new(
        table      => $self->{table_name},
        quote      => $self->{quote},
        quote_char => $self->{quote_char},
    );
    return $self;
}

=head2 conn

Returns the internal DBIx::Connector object.

=cut

sub conn {
    return shift->{conn};
}

=head2 table_name

Returns the table_name. Default is C<dezi_stats>.

=cut

sub table_name {
    return shift->{table_name};
}

=head2 insert( I<hashref> )

Writes I<hashref> to the database.

=cut

sub insert {
    my $self = shift;
    my $row = shift or croak "hashref required";
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            $self->{ih}->insert( $row, $self->{table_name}, $dbh );
        }
    );
}

=head2 schema

Callable as a function or class method. Returns string suitable
for initializing a B<dezi_stats> SQL table.

Example:

 perl -e 'use Dezi::Stats::DBI; print Dezi::Stats::DBI::schema' | sqlite3 dezi.index/stats.db

You can use SQL::Translator to initialize a non-SQLite database:

 my $dbh        = DBI->connect($dsn, $user, $pass);
 my $sql        = Dezi::Stats::DBI::schema();
 my $translator = SQL::Translator->new(
    show_warnings     => 1,
    validate          => 1,
    quote_identifiers => 1,
    no_comments       => 1,
 );
 my $mysql = $translator->translate(
    from       => 'SQLite',
    to         => 'MySQL',
    datasource => \$sql
 ) or die $translator->error;

 # Translator adds extra statements that do() can't handle.
 $mysql =~ s/^.*(CREATE TABLE .+?\));.*$/$1/s;

 $dbh->do($mysql);

=cut

sub schema {
    return <<EOF
create table if not exists dezi_stats (
    id          integer primary key autoincrement,
    tstamp      integer,
    q           text,
    build_time  float,
    search_time float,
    remote_user text,
    path        varchar(255),
    total       integer,
    s text,
    o integer,
    p integer,
    h integer,
    c integer,
    L text,
    f integer,
    r integer,
    t varchar(128),
    b varchar(32)
);
EOF
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-stats at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Stats>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Stats


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Stats>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Stats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Stats>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Stats/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

