#!/usr/bin/env perl 

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;

use List::Util qw( max );
use GD::Simple;
use Math::Window2Viewport;

GetOptions (
    'data=s'    => \my @data,
    'width=i'   => \my $width,
    'height=i'  => \my $height,
    help        => \my $help,
    man         => \my $man,
);
pod2usage( -verbose => 0 ) if $help;
pod2usage( -verbose => 2 ) if $man;

@data = split(/,/,join(',',@data));
@data = ( 4, 3, 10, 7, 2 ) unless @data;
$width  ||= 200;
$height ||= 150;

my $img = GD::Simple->new( $width, $height );
my $mapper = Math::Window2Viewport->new(
    Wb => 0, Wt => max( @data ), Wl => 0, Wr => scalar( @data ),
    Vb => $height, Vt => 0, Vl => 0, Vr => $width,
);

for (0 .. $#data) {
    $img->moveTo( $mapper->Dx($_ + .5), $mapper->Dy(1) );
    $img->lineTo( $mapper->Dx($_ + .5), $mapper->Dy($data[$_] - .5) );
    $img->moveTo( $mapper->Dx( $_ + .45 ), $mapper->Dy( 0 ) );
    $img->string( $data[$_] );
}

$img->moveTo( 10, 20 );
$img->fgcolor('blue');
$img->string( "bar chart" );
print $img->png;

__END__
=head1 NAME

graph.pl - 

=head1 SYNOPSIS

graph.pl [options]

 Options:
   --data           data to chart
   --height         height of PNG output
   --width          width of PNG output
   --help           list usage
   --man            print man page

=head1 OPTIONS

=over 8

=item B<--data>

The data to chart. Specify multiple args:

  --data=5 --data=10 --data=3

or use a comma delimited string:

  --data=21,45,30,67,10

=item B<--height>

The height (in pixels) of the PNG output.

=item B<--width>

The width (in pixels) of the PNG output.

=item B<--res>

The resolution of the waveform. Values between
0 and 1 work best.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will process data and produce a bar chart
in PNG format.

=cut
