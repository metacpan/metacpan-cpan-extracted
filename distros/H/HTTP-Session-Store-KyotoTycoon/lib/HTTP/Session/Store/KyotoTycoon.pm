package HTTP::Session::Store::KyotoTycoon;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.02';
use Cache::KyotoTycoon;
use Storable ();

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    my $kt = Cache::KyotoTycoon->new(
        host => $args{host} || '127.0.0.1',
        port => $args{port} || 1978,
        db   => $args{db}   || 0,
    );
    bless {kt => $kt, expires => $args{expires}}, $class;
}

sub select {
    my ( $self, $session_id ) = @_;
    my $data = $self->{kt}->get($session_id);
    if (defined $data) {
        return Storable::thaw($data);
    } else {
        return undef;
    }
}

sub insert {
    my ($self, $session_id, $data) = @_;
    $self->{kt}->set( $session_id, Storable::nfreeze($data), $self->{expires} );
}

sub update {
    my ($self, $session_id, $data) = @_;
    $self->{kt}->replace( $session_id, Storable::nfreeze($data), $self->{expires} );
}

sub delete {
    my ($self, $session_id) = @_;
    $self->{kt}->remove( $session_id );
}

sub cleanup { Carp::croak "This storage doesn't support cleanup" }


1;
__END__

=encoding utf8

=head1 NAME

HTTP::Session::Store::KyotoTycoon - HTTP::Session with Cache::KyotoTycoon

=head1 SYNOPSIS

    use HTTP::Session::Store::KyotoTycoon;

    HTTP::Session->new(
        store => HTTP::Session::Store::KyotoTycoon->new(
            host => 'localhost',
            port => 1978,
            db   => 0,
        ),
        state => ...,
        request => ...,
    );

=head1 DESCRIPTION

HTTP::Session::Store::KyotoTycoon is L<Cache::KyotoTycoon> bindings for L<Cache::KyotoTycoon>.

B<THIS MODULE IS IN ITS BETA QUALITY. THE API MAY CHANGE IN THE FUTURE>.

=head1 CONFIGURATION

=over 4

=item host

host name of the server(Default: '127.0.0.1')

=item port

Port number of the server(Default: 1978)

=item db

The name of database or the number of database(Default: 0)

=item expires

session expire time(in seconds)

=back

=head1 METHODS

=over 4

=item select

=item update

=item delete

=item insert

for internal use only

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

L<Cache::KyotoTycoon>, L<HTTP::Session>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
