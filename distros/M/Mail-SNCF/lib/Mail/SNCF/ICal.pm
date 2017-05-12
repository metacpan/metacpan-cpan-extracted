package Mail::SNCF::ICal;

use warnings;
use strict;

use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

use base qw/Mail::SNCF/;

=head1 NAME

Mail::SNCF::Text - ICal output for SNCF

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This backend produces an output suitable for ICal based programs.

    use Mail::SNCF;

    my $foo = Mail::SNCF::Text->parse("Mail/sncf");
    my $s = $foo->as_string;
    $foo->print;

=head1 FUNCTIONS

=head2 as_string

=cut

sub as_string {
    my ($self) = @_;
    return $$self->as_string;
}

=head2 parse

Parses the mailbox and returns and Ical object.

=cut

sub parse {
    my ($class, $folder_path) = @_;

    my $ical = Data::ICal->new();
    my $self = \$ical;
    bless($self, $class);

    my $raw = Mail::SNCF->parse($folder_path);
    # I didn't manage to use SUPER here

    for my $trip (@{$raw}) {
        my @date = @{$trip->{date}};
        my @start = @{$trip->{start}};
        my @end = @{$trip->{end}};

        my $start = Date::ICal->new(year  => $date[2],
                                    month => $date[1],
                                    day   => $date[0],
                                    hour  => $start[0],
                                    min   => $start[1],
            );
        my $end = Date::ICal->new(year  => $date[2],
                                  month => $date[1],
                                  day   => $date[0],
                                  hour  => $end[0],
                                  min   => $end[1],
            );
        my $duration = $end - $start;

        my $event = Data::ICal::Entry::Event->new();
        $event->add_properties(summary     => $trip->{from} . " -> " . $trip->{to},
                               description => "",
                               dtstart     => $start->ical,
                               dtend       => $end->ical,
            );
        $$self->add_entry($event);
    }
    return $self;
}

=head1 AUTHOR

Olivier Schwander, C<< <iderrick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-sncf at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail::SNCF::Ical>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::SNCF::Ical

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-SNCF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-SNCF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-SNCF>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-SNCF>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier Schwander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Mail::SNCF::ICal
