#!/usr/bin/perl

# simple command-line utility for converting between spaces

use Graphics::ColorObject;

use Getopt::Long;

GetOptions (
			"from=s" => \$from,
			"to=s"   => \$to,
			"verbose"  => \$verbose
			);

$from_components = [ @ARGV ];

if (! $from || ! $to || scalar(@{$from_components}) != 3)
{
	print <<EOUSAGE;
Usage: 
  convert-color.pl  --to=HSV --from=RGB 0.0 0.5 0.5
EOUSAGE

exit;
}

if ($from eq 'RGB') { $color = Graphics::ColorObject->new_RGB( $from_components ); }
elsif ($from eq 'XYZ') { $color = Graphics::ColorObject->new_XYZ( $from_components ); }
elsif ($from eq 'xyY') { $color = Graphics::ColorObject->new_xyY( $from_components ); }
elsif ($from eq 'Lab') { $color = Graphics::ColorObject->new_Lab( $from_components ); }
elsif ($from eq 'LCHab') { $color = Graphics::ColorObject->new_LCHab( $from_components ); }
elsif ($from eq 'Luv') { $color = Graphics::ColorObject->new_Luv( $from_components ); }
elsif ($from eq 'LCHuv') { $color = Graphics::ColorObject->new_LCHuv( $from_components ); }
elsif ($from eq 'YCbCr') { $color = Graphics::ColorObject->new_YCbCr( $from_components ); }
elsif ($from eq 'YPbPr') { $color = Graphics::ColorObject->new_YPbPr( $from_components ); }
elsif ($from eq 'HSV') { $color = Graphics::ColorObject->new_HSV( $from_components ); }
elsif ($from eq 'HSL') { $color = Graphics::ColorObject->new_HSL( $from_components ); }
else { print STDERR "no such colorspace: $from\n"; exit; }

if ($to eq 'RGB') { $to_components = $color->as_RGB(); }
elsif ($to eq 'XYZ') { $to_components = $color->as_XYZ(); }
elsif ($to eq 'xyY') { $to_components = $color->as_xyY(); }
elsif ($to eq 'Lab') { $to_components = $color->as_Lab(); }
elsif ($to eq 'LCHab') { $to_components = $color->as_LCHab(); }
elsif ($to eq 'Luv') { $to_components = $color->as_Luv(); }
elsif ($to eq 'LCHuv') { $to_components = $color->as_LCHuv(); }
elsif ($to eq 'YCbCr') { $to_components = $color->as_YCbCr(); }
elsif ($to eq 'YPbPr') { $to_components = $color->as_YPbPr(); }
elsif ($to eq 'HSV') { $to_components = $color->as_HSV(); }
elsif ($to eq 'HSL') { $to_components = $color->as_HSL(); }
else { print STDERR "no such colorspace: $from\n"; exit; }

printf('%s [%6.3f %6.3f %6.3f] is the same as ', $from, @{$from_components});
printf('%s [%6.3f %6.3f %6.3f] '."\n", $to, @{$to_components});
