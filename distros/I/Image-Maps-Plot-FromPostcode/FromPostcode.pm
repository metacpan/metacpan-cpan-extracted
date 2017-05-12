package Image::Maps::Plot::FromPostcode; # where in the world are London.pm members?

our $VERSION = 2;
our $DATE = "Tue 12 Feb  2003 15:33 CET";#"Mon 28 May 09:59 2002 CET"; #"Fri 06 July 19:18 2001 BST";
use 5.006;
use strict;
use warnings;

use base "Image::Maps::Plot::FromLatLong";

our %locations;
our $ADDENTRY;	# Should be object field

=head1 NAME

Image::Maps::Plot::FromPostcode - from postcodes plot world/regional maps in JPEG/HTML

=head1 DESCRIPTION

This module is a sub-class of C<Image::Maps::Plot::FromLatLong>,
that uses the C<WWW::MapBlast> module to convert postcodes to
latitude and longitude.

=head1 OVER-RIDDEN METHODS

=head2 METHOD add_entry

A method that accepts: $name, $country, $postcode

Looks up on MapBlast.com the supplied details, and adds them to the db.

If an entry already exists for $name, will return C<undef> unless
the global scalar C<$ADDENTRY> is set to it's default value of C<MULTIPLE>,
in which case $name will be appended with $country and $postcode.

Does not save them to file - you must do that manually (L<"METHOD save_db">), but
note that you may wish to load the db before adding to it and saving.

Incidentaly returns a reference to the new key.

See also L<ADDING MAPS>.

=cut

sub add_entry { my ($self, $name,$country,$postcode) = (@_);
	eval('use WWW::MapBlast 0.02;');
	die "Can't add_entry without \$name, \$country, \$postcode "
		unless (defined $name and defined $country and defined $postcode);

	my ($lat,$lon,$address) = WWW::MapBlast::latlon($country,$postcode);
	$lat = 11111111 if not defined $lat or $lat eq '';
	$lon = 11111111 if not defined $lon or $lon eq '';
	if (not defined $address or $address eq ''){
		$address = "$postcode $country - MapBlast.com didn't know"
	}

	if (exists $locations{$name} ){
		if ($ADDENTRY ne 'MULTIPLE'){
			warn "Not adding duplicate entry for $name at $postcode, $country.\n" if $self->{chat};
			return undef;
		}
		$name .= " ($postcode $country)";
	}

	$locations{$name} = {
			PLACE=>$address,
			LAT=>$lat,
			LON=>$lon,
	};

	return \$locations{$name};
}



=head2 &remove_entry

A subroutine, not a method, that accepts the name field of the entry in the db, and returns
C<1> on success, C<undef> if no such entry exists.

=cut

sub remove_entry { my ($name) = (shift);
	return undef if not exists $locations{$name};
	delete $locations{$name};
	return 1;
}



1;
__END__



=head1 BACKGROUND

I was bored and got this message on a list:

	From: london.pm-admin@london.pm.org
	[mailto:london.pm-admin@london.pm.org]On Behalf Of Philip Newton
	Sent: 21 June 2001 11:44
	To: 'london.pm@london.pm.org'
	Subject: Re: headers

	Simon Wistow wrote:
	> It's more a collection of people who have the common connection
	> that they live and london and like perl.
	> In fact neither of those actually have to be true since I personally
	> know two people on the list who don't program Perl and one of whom
	> doesn't even live in London.

	How many off-London people have we got? (Well, also excluding people who
	live near London.)

	From outside the UK, there's Damian, dha, Paul M, I; Lucy and lathos
	probably also qualify as far as I can tell. Marcel used to work in London
	(don't know whether he still does). Anyone else?

	Cheers,
	Philip
	--
	Philip Newton <Philip.Newton@datenrevision.de>
	All opinions are my own, not my employer's.
	If you're not part of the solution, you're part of the precipitate.

In the twenty-second weekly summary of the London Perl Mongers
mailing list, for the week starting 2001-06-18:

	In other news: ... a london.pm world map ...

Hence the module. At that time there were no maps to
plot from postcodes.

=head1 REVSIONS

=over 4

=item 2

Made this a sub-class of the new C<*::FromLatLong> to
remove what has, for me personally, become redundent functionality.
Interface remains unchanged, I<I think>.

=item 1.2

Corrected a slight mis-positioning of points.

Replaced GD with Image::Magick as I was seeing terrible JPEG output
with GD.

Replaced support for non-maintained C<Image::GD::Thumbnail> with
C<Image::Thumbnail>.

Added methods to create just images and to return references to image blobs.

=item 1.0

Don't remember.

=item 0.25

Clean IMG path and double-header bugs

=item 0.23

Added more documentation; escaping of href text

=item 0.22

Added thumbnail images to index page

=back

=head1 SEE ALSO

perl(1);
L<Image::Maps::Plot::FromLatLong>;
L<Image::Magick|http://www.ImageMagick.org> (C<http://www.ImageMagick.org>); L<File::Basename>; L<Acme::Pony>; L<Data::Dumper>; L<WWW::MapBlast>; L<Image::Thumbnail>

=head1 THANKS

Thanks to the London.pm group for their test data and insipration, to Leon for his patience with all that mess on the list, to Philip Newton for his frankly amazing knowledge of international postcodes.

Thanks also to the CIA, L<About.com|http://wwww.about.com>, L<The University of Texas|http://www.lib.utexas.edu/maps>,
and L<The Ordnance Survey|http://www.ordsvy.gov.uk/freegb/index.htm#maps>
for their public-domain maps.

=head1 AUTHOR

Lee Goddard <lgoddard@cpan.org>

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 2001.  All Rights Reserved.

This module is supplied and may be used under the same terms as Perl itself.

The public domain maps provided with this distribution are the property of their respective copyright holders.

=cut

