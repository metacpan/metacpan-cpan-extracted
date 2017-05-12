#!/usr/local/bin/perl
use strict;
use warnings;

use Pod::Usage;
use Getopt::Long;
use Imager;
use Image::ObjectDetect;

Getopt::Long::Configure('bundling');
GetOptions(
    'cascade=s' => \my $cascade,
    'output=s'  => \my $output,
    'input=s'   => \my $input,
    'version|v' => \my $version,
    'help|h'    => \my $help,
);
if ($version) {
    print "Image::ObjectDetect version $Image::ObjectDetect::VERSION\n";
    exit;
}
pod2usage(0) if $help or !$cascade or !$output or !$input;

my $detector = Image::ObjectDetect->new($cascade);
my @faces = $detector->detect($input);
my $image = Imager->new->read(file => $input);
for my $face (@faces) {
    $image->box(
        xmin   => $face->{x},
        ymin   => $face->{y},
        xmax   => $face->{x} + $face->{width},
        ymax   => $face->{y} + $face->{height},
        color  => 'red',
        filled => 0,
    );
}
$image->write(file => $output);

__END__

=head1 NAME

facedetect.pl - detects faces from picture.

=head1 SYNOPSIS

facedetect.pl [options]

 Options:
   -c -cascade        cascade file
   -o -output         output filename
   -i -input          input filename
   -v -version        print version
   -h -help           print this help

 See also:
   perldoc Image::ObjectDetect

=head1 DESCRIPTION

Detects faces from picture.

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

