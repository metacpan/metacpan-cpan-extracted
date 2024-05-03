package Feed::Data::CNN;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Rope;
use Rope::Autoload;
use Feed::Data::CNN::TopStories;
use Feed::Data::CNN::AllPolitics;
use Feed::Data::CNN::Health;
use Feed::Data::CNN::Tech;
use Feed::Data::CNN::Showbiz;

for my $feed (qw/top_stories all_politics health tech showbiz/) {
        property $feed => (
                initable => 1,
                enumerable => 1,
                writeable => 0,
                configurable => 1,
                builder => sub {
                        _feed_info($_[0], $feed);
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
	$locale =~ s/_//g;
        return (
                sprintf("Feed::Data::CNN::%s", ucfirst($mod)),
                sprintf("http://rss.cnn.com/rss/cnn_%s.rss", $locale)
        );
};


1;

__END__

=head1 NAME

Feed::Data::CNN - The rest of the world will follow.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

	use Feed::Data::CNN;

	my $cnn = Feed::Data::CNN->new();

	for my $feed (qw/top_stories all_politics health tech showbiz/) {
		my $data = $cnn->$feed;
		$data->parse;
		$data->render;
	}

=head1 SUBROUTINES/METHODS

=head2 top_stories

=head2 all_politics

=head2 health

=head2 tech

=head2 showbiz

See L<Feed::Data> for more information.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-feed-data-cnn at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Feed-Data-CNN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Feed::Data::CNN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Feed-Data-CNN>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Feed-Data-CNN>

=item * Search CPAN

L<https://metacpan.org/release/Feed-Data-CNN>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Feed::Data::CNN
