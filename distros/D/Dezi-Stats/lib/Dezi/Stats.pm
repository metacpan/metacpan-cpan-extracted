package Dezi::Stats;

use warnings;
use strict;
use Carp;
use Module::Load;

our $VERSION = '0.001006';

=head1 NAME

Dezi::Stats - log statistics for your Dezi server

=head1 SYNOPSIS

 # example Dezi server application
 use Dezi::Server;
 use Plack::Runner;
 use Dezi::Stats;
 
 my $app = Dezi::Server->app({
    engine_config   => { 
        type    => 'Lucy',
        index   => ['path/to/your/index'],
    },
    stats_logger => Dezi::Stats->new(
        type        => 'DBI',
        dsn         => "DBI:mysql:database=$database;host=$hostname;port=$port",
        username    => 'myuser',
        password    => 'mysecret',
    ),
 });
 
 my $runner = Plack::Runner->new();
 $runner->run($app);

=head1 DESCRIPTION

Dezi::Stats logs statistics about requests to a Dezi server.
There are multiple backend storage options, including DBI-based
storage (MySQL, Postgresql, SQLite, etc), file-based, etc.

=head1 METHODS

=head2 new( I<config> )

Returns a new Dezi::Stats object. I<config> should be a series
of key/value pairs (a hash). Supported I<config> params are:

=over

=item type

The backend storage type. Defaults to 'File' (see L<Dezi::Stats::File>).

=item dsn

If B<type> is C<DBI> then the B<dsn> value will be passed directly
to the DBI->connect() method.

=item username

If B<type> is C<DBI> then the B<username> value will be passed directly
to the DBI->connect() method.

=item password

If B<type> is C<DBI> then the B<password> value will be passed directly
to the DBI->connect() method.

=item table_name

If B<type> is C<DBI> then the B<table_name> value will be used
to insert rows. Defaults to C<dezi_stats>.

=item quote

If B<type> is C<DBI> then the B<quote> value will be used
to quote column names on insert. Defaults to C<false>.

=item quote_char

If B<type> is C<DBI> then the B<quote_char> value will be used
when B<quote> is true. Defaults to backtick.

=item path

If B<type> is C<File> then the B<path> value is the filesystem path
to the log file. See L<Dezi::Stats::File>.

=back

=cut

sub new {
    my $class = shift;
    my $self;
    if ( @_ == 1 ) {
        $self = shift;
    }
    else {
        $self = {@_};
    }
    $self->{type} ||= 'File';
    my $driver;
    if ( $self->{type} =~ m/^\+/ ) {
        $driver = $self->{type};
        $driver =~ s/^\+//;
    }
    else {
        $driver = 'Dezi::Stats::' . $self->{type};
    }
    load $driver;
    bless $self, $driver;
    $self->init_store();
    return $self;
}

=head2 init_store

All subclasses must implement this abstract method.
Called internally in new().

=cut

sub init_store {
    my $self = shift;
    croak "$self must implement init_store()";
}

=head2 log( I<plack_request>, I<sos_response> )

Required method for Search::OpenSearch::Server stats_logger()
API.

Expects 2 objects: the current Plack::Request and the resulting
Search::OpenSearch::Response.

Calls insert() after pulling data from the request
and the response.

=cut

sub log {
    my $self     = shift;
    my $request  = shift or croak "Plack::Request object required";
    my $response = shift or croak "Response object required";
    my %stats    = (
        remote_user => (
              $request->can('remote_user')
            ? $request->remote_user
            : $request->user
        ),
        tstamp      => time(),
        build_time  => $response->build_time,
        search_time => $response->search_time,
        path        => $request->uri->path,
        total       => $response->total,
    );
    my $params = $request->parameters;
    if ( $response->isa('Search::OpenSearch::Result') ) {

        # a REST request on a specific doc

    }
    else {

        # a SOS::Response
        # TODO document and/or whitelist these
        for my $p (qw( q s o p h c L f r t b )) {
            $stats{$p} = $params->{$p};
        }
    }
    $self->insert( \%stats );
}

=head2 insert( I<hash_ref> )

Called by log. All subclasses must implement this abstract method.

=cut

sub insert {
    my $self = shift;
    croak "$self must implement insert()";
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

