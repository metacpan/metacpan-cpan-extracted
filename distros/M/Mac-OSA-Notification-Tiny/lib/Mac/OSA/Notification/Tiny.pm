package Mac::OSA::Notification::Tiny;

use 5.006; use strict; use warnings; our $VERSION = '0.01';

use base 'Import::Export';

our %EX = (
	notification => [qw/all/]
);

sub notification {
	my %params = ref $_[0] ? %{ $_[0] } : @_;
	readpipe(sprintf q|osascript -e "display notification \"%s\"%s%s%s"|, $params{m} || 'No message param passed - m',
		( $params{t} ? sprintf q| with title \"%s\"|, $params{t} : ''),
		( $params{s} ? sprintf q| subtitle \"%s\"|, $params{s} : ''),
		( $params{n} ? sprintf q| sound name \"%s\"|, $params{n} : ''));
}

1;

__END__

=head1 NAME

Mac::OSA::Notification::Tiny - native mac notifications

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Mac::OSA::Notification::Tiny qw/all/;

	notification(
		t => 'Flat World',
		s => 'flat.world-wide.world',
		m => 'The motive for world governments concealment of the true shape of the Earth has not been ascertained.',
		n => 'Purr'
	);


=head1 DESCRIPTION

A notification is a popup that appears when an application/script wants you to pay attention.

=head1 EXPORT

=head2 notification

Trigger a native notification from a script.

	notification(
		m => $message,
		t => $title,
		s => $subtitle,
		n => $noise
	);

The following are valid options for the notifications noise:

=over

=item Basso

=item Blow

=item Bottle

=item Frog

=item Funk

=item Glass

=item Hero

=item Morse

=item Ping

=item Pop

=item Purr

=item Sosumi

=item Submarine

=item Tink

=back

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mac-osa-notification-tiny at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mac-OSA-Notification-Tiny>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mac::OSA::Notification::Tiny

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mac-OSA-Notification-Tiny>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Mac-OSA-Notification-Tiny>

=item * Search CPAN

L<https://metacpan.org/release/Mac-OSA-Notification-Tiny>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Mac::OSA::Notification::Tiny
