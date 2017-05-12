package Dezi::Bot::Queue::DBI;
use strict;
use warnings;
use base 'Dezi::Bot::Queue';
use Carp;
use URI;
use Data::Dump qw( dump );
use DBIx::Connector;
use DBIx::InsertHash;
use Digest::MD5 qw( md5_hex );
use Time::HiRes;

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Queue::DBI - web crawler queue with DBI storage

=head1 SYNOPSIS

 use Dezi::Bot::Queue::DBI;

 my $queue = Dezi::Bot::Queue->new(
    type     => 'DBI',
    dsn      => "DBI:mysql:database=$database;host=$hostname;port=$port",
    username => 'myuser',
    password => 'mysecret',
 );
 my $uri = 'http://dezi.org/bot.html';
 $queue->put($uri);
 $queue->size();    # returns number of items in queue
 $queue->peek;      # returns $uri (next value for get())
 $queue->get;       # returns $uri and removes it from queue

=head1 DESCRIPTION

The Dezi::Bot::Queue::DBI class is a subclass of Dezi::Bot::Queue
that uses DBI for storage.

=cut

=head1 METHODS

=head2 init_store()

Sets up the internal database handle (accessible via conn() attribute).

=cut

sub init_store {
    my $self = shift;

    # name used in put/get
    $self->{name} ||= 'dezibot-' . $$;

    my $dsn = delete $self->{dsn} or croak "Queue dsn required";
    my $username = delete $self->{username}
        or croak "Queue username required";
    my $password = delete $self->{password}
        or croak "Queue password required";
    $self->{table_name} ||= 'dezi_queue';
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

=head2 put( I<item>, I<args> )

Add I<item> to the queue.

=cut

sub put {
    my $self = shift;
    my $item = shift;
    if ( !defined $item ) {
        croak "item required";
    }
    my %cols = @_;
    my $md5  = md5_hex("$item");
    my $row  = {
        lock_time  => 0,
        uri_md5    => $md5,
        uri        => $item,
        queue_time => Time::HiRes::time(),
        queue_name => $self->name,
        %cols,
    };
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            $self->{ih}->insert( $row, $self->{table_name}, $dbh );
        }
    );
}

=head2 get([ I<limit>, I<update_cols> ])

Returns the next item from the queue, marking it as unavailable.
Default is to return 1 item, but set I<limit> to return multiple.

I<update_cols> is an optional hashref of column/value pairs to update
when each item is locked.

=cut

sub get {
    my $self        = shift;
    my $limit       = shift || 1;
    my $update_cols = shift || {};
    my @items;
    my $t = $self->{table_name};
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            my $sth
                = $dbh->prepare(
                qq/select * from $t where queue_name=? and lock_time=0 order by priority DESC, queue_time ASC limit ?/
                );
            $sth->execute( $self->name, $limit );
            while ( my $row = $sth->fetchrow_hashref() ) {
                push @items, URI->new( $row->{uri} );

                # lock
                $row->{lock_time} = Time::HiRes::time();

                # mixin/override
                $row->{$_} = $update_cols->{$_} for keys %$update_cols;

                # update
                $self->{ih}->update( $row, [ $row->{id} ],
                    'id=?', $self->{table_name}, $dbh );
            }
        }
    );
    return ( $limit == 1 ) ? $items[0] : \@items;
}

=head2 remove( I<item> )

Remove I<item> from the queue completely.

=cut

sub remove {
    my $self = shift;
    my $item = shift;
    if ( !defined $item ) {
        croak "item required";
    }
    my $count = 0;
    my $md5   = md5_hex("$item");
    my $t     = $self->{table_name};
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            $count
                = $dbh->do( qq/delete from $t where uri_md5=?/, undef, $md5 );
        }
    );
    return $count;
}

=head2 clean

Remove all locked items from the queue.

=cut

sub clean {
    my $self  = shift;
    my $count = 0;
    my $t     = $self->{table_name};
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            $count = $dbh->do(qq/delete from $t where locked!=0/);
        }
    );
    return $count;
}

=head2 peek([ I<limit> ])

Returns the next item value, but leaves it on the stack as available.

=cut

sub peek {
    my $self = shift;
    my $limit = shift || 1;
    my @items;
    my $t = $self->{table_name};
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            my $sth
                = $dbh->prepare(
                qq/select * from $t where lock_time=0 order by priority DESC, queue_time ASC limit ?/
                );
            $sth->execute($limit);
            while ( my $row = $sth->fetchrow_hashref() ) {
                push @items, $row->{uri};
            }
        }
    );
    return ( $limit == 1 ) ? $items[0] : \@items;
}

=head2 size

Returns the number of items currently in the queue.

=cut

sub size {
    my $self = shift;
    my $size = 0;
    my $t    = $self->{table_name};
    $self->{conn}->run(
        sub {
            my $dbh = $_;              # just for clarity
            my $sth = $dbh->prepare(
                qq/select count(*) from $t where lock_time=0/);
            $sth->execute();
            $size = $sth->fetch->[0];
        }
    );
    return $size;
}

=head2 schema

Callable as a function or class method. Returns string suitable
for initializing a B<dezi_queue> SQL table.

Example:

 perl -e 'use Dezi::Bot::Queue::DBI; print Dezi::Bot::Queue::DBI::schema' |\
  sqlite3 dezi.index/bot.db

=cut

sub schema {
    return <<EOF
create table if not exists dezi_queue (
    id          integer primary key autoincrement,
    lock_time   float,
    queue_time  float,
    uri         text,
    uri_md5     char(32),
    priority    integer,
    queue_name  varchar(255),
    client_name varchar(255),
    constraint uri_md5_unique unique (uri_md5)
);
EOF
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-bot at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Bot>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Bot


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Bot>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Bot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Bot>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Bot/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



