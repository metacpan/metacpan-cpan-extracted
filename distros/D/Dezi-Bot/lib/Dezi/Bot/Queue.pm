package Dezi::Bot::Queue;
use strict;
use warnings;
use Carp;
use Module::Load;

our $VERSION = '0.003';

=head1 NAME

Dezi::Bot::Queue - web crawler queue

=head1 SYNOPSIS

 use Dezi::Bot::Queue;

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

The Dezi::Bot::Queue module adheres to the API of SWISH::Prog::Queue
while optimized for persistent storage.

=cut

=head1 METHODS

=head2 new( I<config> )

Returns a new Dezi::Bot::Queue object. I<config> should be a series
of key/value pairs (a hash). Supported I<config> params are:

=over

=item type

The backend storage type. Defaults to 'DBI' (see L<Dezi::Bot::Queue::DBI>).

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
to insert rows. Defaults to C<dezi_queue>.

=item quote

If B<type> is C<DBI> then the B<quote> value will be used
to quote column names on insert. Defaults to C<false>.

=item quote_char

If B<type> is C<DBI> then the B<quote_char> value will be used
when B<quote> is true. Defaults to backtick.

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
    $self->{type} ||= 'DBI';
    my $driver;
    if ( $self->{type} =~ m/^\+/ ) {
        $driver = $self->{type};
        $driver =~ s/^\+//;
    }
    else {
        $driver = 'Dezi::Bot::Queue::' . $self->{type};
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

=head2 name

Get/set the name of the queue.

=cut

sub name {
    my $self = shift;
    $self->{name} = $_[0] if defined $_[0];
    return $self->{name};
}

=head2 put( I<item> )

Add I<item> to the queue.

=cut

sub put {
    croak "$_[0] must implement put()";
}

=head2 get

Returns the next item.

=cut

sub get {
    croak "$_[0] must implement get()";
}

=head2 peek

Returns the next item value, but leaves it on the stack.

=cut

sub peek {
    croak "$_[0] must implement peek()";
}

=head2 size

Returns the number of items currently in the queue.

=cut

sub size {
    croak "$_[0] must implement size()";
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

