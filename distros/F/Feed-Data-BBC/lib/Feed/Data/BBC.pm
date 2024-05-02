package Feed::Data::BBC;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.01';

use Rope;
use Rope::Autoload;
use Feed::Data::BBC::England;
use Feed::Data::BBC::Africa;
use Feed::Data::BBC::Asia;
use Feed::Data::BBC::Europe;
use Feed::Data::BBC::LatinAmerica;
use Feed::Data::BBC::MiddleEast;
use Feed::Data::BBC::UsAndCanada;
use Feed::Data::BBC::NorthernIreland;
use Feed::Data::BBC::Scotland;
use Feed::Data::BBC::Wales;

for my $country (qw/england africa asia europe latin_america middle_east us_and_canada northern_ireland scotland wales/) {
	property $country => (
		initable => 1,
		enumerable => 1,
		writeable => 0,
		configurable => 1,
		builder => sub {
			_feed_info($_[0], $country);
		}
	);
}

sub _feed_info {
	my @info = $_[0]->{properties}->{feed_info}->{value}(undef, $_[1]);
	$info[0]->new(
		url => $info[1] 
	);
}

function feed_info => sub {
	my ($self, $locale) = @_;
	(my $mod = $locale) =~ s/_([^_]+)/ucfirst($1)/eg;
	return (
		sprintf("Feed::Data::BBC::%s", ucfirst($mod)),
		sprintf("https://feeds.bbci.co.uk/news%s/%s/rss.xml", ($locale =~ m/^(england|northern_ireland|scotland|wales)$/ ? '' : '/world'), $locale)
	);
};

1;

__END__

=head1 NAME

Feed::Data::BBC - Waiting for comedians to present the news

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Feed::Data::BBC;

	my $bbc = Feed::Data::BBC->new();

	for my $feed (qw/england africa asia europe latin_america middle_east us_and_canada/) {
		my $data = $bbc->$feed;
		$data->parse;
		$data->render;
	}

=head1 SUBROUTINES/METHODS

=head2 england

=head2 africa

=head2 asia

=head2 europe

=head2 latin_america

=head2 middle_east

=head2 us_and_canada

=head2 northern_ireland

=head2 scotland

=head2 wales

See L<Feed::Data> for more information.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-feed-data-bbc at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-Data-BBC>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::Data::BBC

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-Data-BBC>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Feed-Data-BBC>

=item * Search CPAN

L<https://metacpan.org/release/Feed-Data-BBC>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Feed::Data::BBC
