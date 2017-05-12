package Image::DominantColors;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Imager;
use Imager::Fill;
use Image::ColorCollection;
use POSIX;
 
our $VERSION = '0.02';


sub new {
	my ($class, $params) = @_;
	my $self = undef;
	if($params) {
		$self =  $params;
	} else {
	#carp die. We need a filename...
	}
	bless $self, $class;
	return $self;
}

sub getDominantColors {
	my $class = shift;
	my $img = Imager->new(file => $class->{file});
	my $clusters = 3;
	my $clus = $class->{clusters};
	if($clus)
	{
		$clusters = $clus;
	}
	my $h = $img->getheight() - 1;
	my $w = $img->getwidth() - 1;

	my @colors = ();
	for (my $j = 0; $j < $w; $j++) {
		for (my $k = 0; $k < $h; $k++) {
			my $oth = $img->getpixel(x => $j, y => $k);
			my ($red, $green, $blue, $alpha) = $oth->rgba();
			push (@colors, {
				r => $red,
				g => $green,
				b => $blue,
			});
		}		
	}

	my @centroids = ();
	for (my $i = 1; $i <= $clusters; $i++) {
		my $cc = Image::ColorCollection->new();
		push @centroids, $cc;
	}
	
	my $shft = 100;
	my $it = 0;#track iterations
#	print "TotalCentroid : ".scalar(@centroids);
	while($shft != 0)
	{
		foreach my $col (@colors) {
			my $min = LONG_MAX;
			my $cent = undef;
#				print "TotalCentroidAgainb : ".scalar(@centroids);
			foreach my $c (@centroids) {
				#print Dumper($c);
				my $d = int(euclideanDist($col, $c->getCentroid()));
				if($d < $min)
				{
					$min = $d;
					$cent = $c;					
				}
			}
			$cent->addColor($col);			
		}
		my $localShft = 0;
		foreach my $cnt (@centroids) {
			$localShft += $cnt->updateCentroid();
			$cnt->clear();
		}
		$shft = $localShft;
		$it++;				
#		print "Iteration : $it , shift : $shft\n";
	}
	my @ret = map { $_->getCentroid() } @centroids;
	return \@ret;
}
sub euclideanDist {
	my ($c1, $c2) = @_;
	return sqrt((($c1->{r}-$c2->{r})**2) + (($c1->{g}-$c2->{g})**2) + (($c1->{b}-$c2->{b})**2));
}

1; # End of Image::DominantColors
__END__


=head1 NAME

Image::DominantColors - Find dominant colors in an image with k-means clustering.

=head1 VERSION

Version 0.01

=cut




=head1 SYNOPSIS

This module does just one simple thing. It scans an image and clusters colors with the L<k-means clustering|http://en.wikipedia.org/wiki/K-means_clustering> 
algorithm to give you the most dominant colors in that image.

Here is a live demo : L<http://www.tryperl.com/dominantcolors/>

This is how it works, I would advise leaving the clusters to a default 3 which works best with images.:

    use Image::DominantColors;
    use Data::Dumper;
    
    
    my $dmt = Image::DominantColors->new({file => 'some_path/img.jpg', clusters => 4});
    #OR three clusters is default
    my $dmt = Image::DominantColors->new({file => 'some_path/img.jpg'});
    my $r = $dmt->getDominantColors();
    
    print Dumper($r);
	#This outputs the following:
    # [
    #           {
    #             'r' => 31,
    #             'b' => 23,
    #             'g' => 15
    #           },
    #           {
    #             'r' => 193,
    #             'b' => 41,
    #             'g' => 84
    #           },
    #           {
    #             'r' => 114,
    #             'b' => 136,
    #             'g' => 128
    #           },
    #           {
    #             'r' => 61,
    #             'b' => 82,
    #             'g' => 66
    #           }
    # ];
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 getDominantColors
    
    This is the only user function the module contains. it returns an array of hashes as in the synopsis.

=cut



=head1 AUTHOR

Gideon Israel Dsouza, C<< <gideon at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-dominantcolors at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-DominantColors>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::DominantColors


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-DominantColors>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-DominantColors>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-DominantColors>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-DominantColors/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gideon Israel Dsouza.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut
