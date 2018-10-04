package Data::ICal::DAVAdapter;
use strict;
use Data::ICal;
use Moo 2;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use Data::ICal;

our $VERSION = '0.02';

=head1 NAME

Data::ICal::DAVAdapter - adapt Data::ICal to the Net::DAVTalk API

=head1 SYNOPSIS

    my $calendar = Data::ICal::DAVAdapter->new(
        filename => $filename
    );

=head1 DESCRIPTION

This is not really intended for use beyond synchronizing Meetup and ICS files

=cut

has 'ics' => (
    is => 'ro',
);

around BUILDARGS => sub( $orig, $class, %options ) {
    if( my $filename = delete $options{ filename }) {
        my $ics = -e $filename
                  ? Data::ICal->new( filename => $filename, vcal10 => 0)->return_value
                  : Data::ICal->new( vcal10 => 0)->return_value
                  ;
        $options{ ics } = $ics
    };
    $class->$orig( %options )
};

sub NewEvent($self, $calendar, $data) {
    my $event = Data::ICal::Entry::Event->new();

    my %copy = %$data;
    $copy{ summary } = delete $copy{ title };
    $copy{ dtstart } = delete $copy{ start };

    if( exists $copy{ locations }) {
        my $addr = delete $copy{ locations };
        $addr = join "\n", grep { defined $_ }
                    $addr->{location}->{name},
                    #$addr->{location}->{address}->{value}
                    ;
        $copy{ location } = $addr;
    };
    ($copy{ url }) = map { "$_->{href}" } values %{ delete $copy{ links }};

    $event->add_properties( %copy );
    $self->ics->add_entry( $event );
}

sub SyncEvents( $self, $calendar, %options) {
    # We are always up to date and don't sync with our backing file
}

sub UpdateEvent( $self, $calendar, $data ) {
    @{ $self->ics->entries }
    = grep {
        $_->property('uid')->[0]->value() ne $data->{uid}
    } @{ $self->ics->entries };
    $self->NewEvent( $calendar, $data );
}

sub GetEvents( $self, $calendar, %options ) {
    [ map {

        my $ev = $_;
        my @prop = $ev->properties;
        my %res = %{ $ev->properties };
        for ( sort keys %res ) {
            $res{ $_ } = $res{ $_ }->[0]->value;
        };

        $res{ start } = delete $res{ dtstart };

        if( exists $res{ location }) {
            $res{ locations } = {
                location => {
                    name => $res{ location },
                    address => { name => "address", value => $res{ location }},
                },
            };
            delete $res{ location };
        };

        #use Data::Dumper;
        #warn Dumper \%res;
        \%res

    } @{ $self->ics->entries } ]
}

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Meetup-API>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2016-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
