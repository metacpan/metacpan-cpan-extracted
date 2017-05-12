package Hash::Storage;

our $VERSION = '0.03';

use v5.10;
use strict;
use warnings;
use Carp qw/croak/;
use Class::Load qw/load_class/;

sub new {
    my $class  = shift;
    my %args   = @_;
    my $driver = $args{driver};
    croak "Wrong driver" unless ref $driver;

    my $self = bless {}, $class;

    if ( ref $driver eq 'ARRAY' ) {
        my $driver_class = 'Hash::Storage::Driver::' . $driver->[0];

        load_class($driver_class);

        $self->{driver} = $driver_class->new( %{ $driver->[1] || {} } );
    } elsif ( $driver->isa('Hash::Storage::Driver::Base') ) {
        $self->{driver} = $driver;
    } else {
        croak "Wrong driver [$driver]";
    }

    $self->init();

    return $self;
}

sub init {
    my $self = shift;
    $self->{driver}->init(@_);
}

sub get {
    my ( $self, $id ) = @_;
    croak "id is required" unless $id;
    croak "id must contain only letters and digits" unless $self->_is_good_id($id);

    $self->{driver}->get(lc($id));
}

sub set {
    my ( $self, $id, $fields ) = @_;
    croak 'id is required' unless $id;
    croak 'id must contain only letters and digits' unless $self->_is_good_id($id);
    croak 'fields are required' unless ref $fields eq 'HASH';

    $fields->{_id} = lc($id);
    $self->{driver}->set( lc($id), $fields );
}

sub del {
    my ( $self, $id ) = @_;
    croak "id is required" unless $id;
    croak "id must contain only letters and digits" unless $self->_is_good_id($id);

    $self->{driver}->del(lc($id));
}

sub list {
    my ( $self, @query ) = @_;
    $self->{driver}->list( @query );
}

sub count {
    my ( $self, $filter ) = @_;
    $self->{driver}->count($filter);
}

sub _is_good_id {
	my ($self, $id) = @_;
	return 1;
	#return $id =~ m/^[a-zA-Z0-9][a-zA-Z0-9_\@\-.]*[a-zA-Z0-9]$/ ? 1 : 0 ;
}

=head1 NAME

Hash::Storage - Persistent Hash Storage Framework

=cut

=head1 SYNOPSIS

    my $st = Hash::Storage->new(
        driver => [ OneFile => { serializer => 'JSON', file => '/tmp/t.json' } ]
    );

    # Store hash by id
    $st->set( 'user1' => { name => 'Viktor', gender => 'M', age => '28' } );

    # Get hash by id
    my $user_data = $st->get('user1');

    # Delete hash by id
    $st->del('user1');


=head1 DESCRIPTION

Hash::Storage is a multipurpose storage for hash. You can consider Hash::Storage object as a collection of hashes.
You can use it for storing users, sessions and a lot more data.

Hash::Storage has pluggable architecture, therefore you can use different drivers or write you own.

=head1 METHODS

=head2 Hash::Storage->new(driver => $DRIVER)

$DRIVER is an arrayref with two values:
the first is a driver name, the second is a hashref with options for driver.

    my $st = Hash::Storage->new(
        driver => [ OneFile => { serializer => 'JSON', file => '/tmp/t.json' } ]
    );

$DRIVER - also can be a Hash::Storage driver object

    my $drv = Hash::Storage::Driver::OneFile->new({ serializer => 'JSON', file => '/tmp/t.json' });
    my $st = Hash::Storage->new( driver => $drv );


=head2 $SELF->set($ID, \%HASH);

Saves hash

=head2 $SELF->get($ID);

Retrieves hash

=head2 $SELF->del($ID);

Deletes hash

=head2 $SELF->list();

returns array with hashrefs

=head2 $SELF->count();

returns number of hashes in a collection

=head1 AUTHOR

"koorchik", C<< <"koorchik at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-storage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Storage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Storage


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Storage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Storage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Storage>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Storage/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 "koorchik".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Hash::Storage
