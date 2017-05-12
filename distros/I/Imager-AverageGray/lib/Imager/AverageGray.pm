package Imager::AverageGray;

use warnings;
use strict;
use Imager;

=head1 NAME

Imager::AverageGray - Finds the average gray for a Imager object or image.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Imager::AverageGray;

    my $ag = Imager::AverageGray->new();
    ...

=head1 METHODES

=head2 new

Initiates the object.

    my $ag=Imager::AverageGray->new;

=cut

sub new{

	my $self={error=>undef, errorString=>''};
	bless $self;

	return $self;
}

=head2 fromFile

This returns the average gray from a specified file.

    my $gray=$ag->fromFile('image.jpg');
    if($ag->{error}){
        print 'Error:'.$ag->{error}.': '.$ag->{errorString}."\n";
    }

=cut

sub fromFile{
	my $self=$_[0];
	my $file=$_[1];

	$self->errorblank;

	my $img = Imager->new();

	if (! -e $file) {
		warn('Imager-AverageGray fromFile:1: The file, "'.$file
			 .'", does not exist');
		$self->{error}=1;
		$self->{errorString}='The file, "'.$file.'", does not exist';
		return undef;
	}

	if (! -f $file) {
		warn('Imager-AverageGray fromFile:1: "'.$file.'", is not a file');
		$self->{error}=2;
		$self->{errorString}='"'.$file.'", is not a file';
		return undef;
	}

	if (!$img->read(file=>$file)){
		warn('Imager-AverageGray fromFile:3: Imager failed reading the file. error="'
			 .$img->errstr.'"');
		$self->{error}=3;
		$self->{errorString}='Imager failed reading the file. error="'.$img->errstr.'"';
		return undef;
	}

	my $ag=$self->fromObject($img);

	return $ag;
}

=head2 fromObject

This finds the average gray for a Imager object.

    my $gray=$ag->fromObject($img);
    if($ag->{error}){
        print 'Error:'.$ag->{error}.': '.$ag->{errorString}."\n";
    }

=cut

sub fromObject{
	my $self=$_[0];
	my $img=$_[1];

	$self->errorblank;

	#create a gray scale image;
	my $gimg=$img->convert(preset=>'grey');

	my $maxX=$gimg->getwidth;
	my $maxY=$gimg->getheight;

	$maxX--;
	$maxY--;

	my $x=0;
	my $y=0;

	my @values;

	while ($x <= $maxX) {
		while ($y <= $maxY) {
			my $color=$gimg->getpixel(x=>$x, y=>$y);

			my ($red, $green, $blue, $alpha) = $color->rgba();

			push(@values, $red);
			
			$y++;
		}

		$x++;
	}

	my $int=0;
	my $total=0;
	while (defined($values[$int])) {
		$total=$values[$int] + $total;

		$int++;
	}

	my $ag=$total/$int;

	return $ag;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

=head2 1

File does not exist.

=head2 2

The specified file is not a file.

=head2 3

Imager failed to read the file.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-image-averagegray at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Image-AverageGray>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Image::AverageGray


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Image-AverageGray>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Image-AverageGray>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Image-AverageGray>

=item * Search CPAN

L<http://search.cpan.org/dist/Image-AverageGray/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Image::AverageGray
