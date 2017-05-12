package Mail::SNCF::Text;

use warnings;
use strict;

use base qw/Mail::SNCF/;

use DateTime;

=head1 NAME

Mail::SNCF::Text - Text output for SNCF

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This backend produces a pretty text output.

    use Mail::SNCF;

    my $foo = Mail::SNCF::Text->parse("Mail/sncf");
    my $s = $foo->as_string;
    $foo->print;

=head1 FUNCTIONS

=head2 print

=cut

sub print {
    my ($self) = @_;
    print $self->as_string;
}

=head2 as_string

=cut

sub as_string {
    my ($self) = @_;

    my $string = "";
    for my $trip (@{$self}) {
        my @date = @{$trip->{date}};
        my @start = @{$trip->{start}};
        my @end = @{$trip->{end}};
        
        my $start = DateTime->new(year   => $date[2],
                                  month  => $date[1],
                                  day    => $date[0],
                                  hour   => $start[0],
                                  minute => $start[1],
                                  locale => $ENV{LANG},
            );
        my $end = DateTime->new(year   => $date[2],
                                month  => $date[1],
                                day    => $date[0],
                                hour   => $end[0],
                                minute => $end[1],
                                locale => $ENV{LANG},
            );

        $string .= "* " . $start->strftime("%x") . " : " .
            $trip->{from} . " -> " . $trip->{to} . "\n";
        $string .= "  Départ : " . $start->strftime("%kh%M") . "\n";
        $string .= "  Arrivée : " . $end->strftime("%kh%M") . "\n";
        $string .= "\n";
    }

    return $string;
}

=head1 AUTHOR

Olivier Schwander, C<< <iderrick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-sncf at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-SNCF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::SNCF::Text

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

1; # End of Mail::SNCF::Text
