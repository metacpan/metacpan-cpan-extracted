package Dezi::Bot::Handler::FileCacher;
use strict;
use warnings;
use base 'Dezi::Bot::Handler';
use Carp;
use Digest::MD5 qw( md5_hex );
use DBIx::Connector;
use DBIx::InsertHash;
use Time::HiRes;
use Dezi::Bot::Utils;
use File::Slurp;
use Encode;
use Search::Tools::UTF8;

__PACKAGE__->mk_accessors(
    qw(
        root_dir
        dsn
        username
        password
        table_name
        queue_name
        quote
        quote_char
        )
);

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Handler::FileCacher - web crawler handler that caches files

=head1 SYNOPSIS

 use Dezi::Bot::Handler::FileCacher;
 my $handler = Dezi::Bot::Handler::FileCacher->new(
    dsn      => "DBI:mysql:database=$database;host=$hostname;port=$port",
    username => 'myuser',
    password => 'mysecret',
    root_dir => '/path/to/site/mirror',
 );
 $handler->handle( $swish_prog_doc );

=head1 DESCRIPTION

The Dezi::Bot::Handler::FileCacher writes
each doc to the filesystem, managing
its progress and status via DBI.

=head1 METHODS

=head2 new( I<config> )

Returns a new Dezi::Bot::Handler::FileCacher object.
I<config> must have:

=over

=item dsn

Passed to DBI->connect.

=item username

Passed to DBI->connect.

=item password

Passed to DBI->connect.

=item table_name

The B<table_name> value will be used
to insert rows. Defaults to C<dezi_file_cache>.

=item queue_name

The B<queue_name> value will be inserted
for each row in the database.

=item quote

The B<quote> value will be used
to quote column names on insert. Defaults to C<false>.

=item quote_char

The B<quote_char> value will be used
when B<quote> is true. Defaults to backtick.

=item root_dir

Base path for writing cached files.

=back

=cut

=head2 init

Internal method to initialize object.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{root_dir} ||= '/tmp/dezi-file-cache';

    my $dsn = delete $self->{dsn} or croak "FileCacher dsn required";
    my $username = delete $self->{username}
        or croak "FileCacher username required";
    my $password = delete $self->{password}
        or croak "FileCacher password required";
    $self->{table_name} ||= 'dezi_file_cache';
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

=head2 handle( I<doc> )

Metadata from I<doc> is stored via DBI
and I<doc> is written to disk.

=cut

sub handle {
    my $self        = shift;
    my $bot         = shift or croak "Bot required";
    my $doc         = shift or croak "Doc required";
    my $buf_ref     = \$doc->content;
    my $uri_md5     = md5_hex( $doc->url . "" );
    my $content_md5 = md5_hex( encode_utf8( to_utf8($$buf_ref) ) );
    my $file_path
        = Dezi::Bot::Utils::file_cache_path( $self->{root_dir}, $uri_md5 );

    $file_path->dir->mkpath( $self->verbose );

    write_file( "$file_path", { binmode => ':utf8' }, $buf_ref );

    return $self->write_record(
        uri_md5     => $uri_md5,
        content_md5 => $content_md5,
        uri         => $doc->url,
        queue_name  => ( $self->queue_name || $bot->spider->agent ),
        client_name => $bot->spider->agent,
        upd_time    => $doc->modtime,
    );
}

=head2 write_record( I<record> )

Write the key/value pairs of I<record> to the database
represented by B<dsn>. I<record> is metadata about the
cached file. Timestamps are automatically added to I<record>
by write_record().

Returns the id (primary key) of the new record.

=cut

sub write_record {
    my $self = shift;
    my %rec  = @_;
    $rec{crawl_time} = time();

    my $ret;
    $self->{conn}->run(
        sub {
            my $dbh = $_;    # just for clarity
            $ret
                = Dezi::Bot::Utils::update_or_insert( $self->{ih}, \%rec,
                [ $rec{uri_md5} ],
                'uri_md5=?', $self->{table_name}, $dbh, );

        }
    );
    return $ret;
}

=head2 schema

Callable as a function or class method. Returns string suitable
for initializing a B<dezi_filecache> SQL table.

Example:

 perl -e 'use Dezi::Bot::Handler::FileCacher; print Dezi::Bot::Handler::FileCacher::schema' |\
  sqlite3 dezi.index/bot.db

=cut

sub schema {
    return <<EOF
create table if not exists dezi_file_cache (
    id          integer primary key autoincrement,
    upd_time    integer,
    crawl_time  integer,
    uri         text,
    uri_md5     char(32),
    content_md5 char(32),
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
