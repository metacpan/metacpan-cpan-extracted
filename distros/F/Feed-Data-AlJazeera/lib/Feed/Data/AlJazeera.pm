package Feed::Data::AlJazeera;

use 5.006; use strict; use warnings; our $VERSION = '0.04';
use Rope; use Rope::Autoload;

use Feed::Data::AlJazeera::English;
use Feed::Data::AlJazeera::Arabic;
use Feed::Data::AlJazeera::Mubasher;
use Feed::Data::AlJazeera::Documentary;
use Feed::Data::AlJazeera::Balkans;

property urls => (
	initable => 1,
	enumerable => 0,
	writeable => 0,
	builder => sub {
		my %urls = (
			english => 'https://www.aljazeera.com/xml/rss/all.xml',
			arabic => 'https://www.aljazeera.net/aljazeerarss/a7c186be-1baa-4bd4-9d80-a84db769f779/73d0e1b4-532f-45ef-b135-bfdff8b8cab9',
			mubasher => 'https://www.aljazeeramubasher.net/rss.xml',
			documentary => 'https://doc.aljazeera.net/xml/rss/all.xml',
			balkans => 'https://balkans.aljazeera.net/rss.xml',
		);
		
		my $base = 'Feed::Data::AlJazeera::';
		for (keys %urls) {
			my $mod = $base . ucfirst($_);
			$_[0]->{properties}->{$_} = {
				index => $_[0]->{index}++,
				initable => 1,
				enumerable => 1,
				writeable => 0,
				configurable => 1,
				value => $mod->new(
					url => $urls{$_}
				)
			};
		}

		return \%urls
	}
);

1;

__END__

=head1 NAME

Feed::Data::AlJazeera - AlJazeera rss feeds

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

	use Feed::Data::AlJazeera;

	my $al_jazeera = Feed::Data::AlJazeera->new();

	for my $feed (qw/english arabic mubasher documentary balkans/) {
		my $data = $al_jazeera->$feed;
		$data->parse;
		$data->render;
	}

=head1 SUBROUTINES/METHODS

=head2 english

=head2 arabic

=head2 mubasher

=head2 documentary

=head2 balkans

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-feed-data-aljazeera at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-Data-AlJazeera>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::Data::AlJazeera

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-Data-AlJazeera>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Feed-Data-AlJazeera>

=item * Search CPAN

L<https://metacpan.org/release/Feed-Data-AlJazeera>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Feed::Data::AlJazeera
