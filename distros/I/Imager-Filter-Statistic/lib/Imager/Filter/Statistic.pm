use strict;
use warnings;
package Imager::Filter::Statistic;
# ABSTRACT: Provide statistica-based pixel filters.


use List::Util qw<min max>;
use List::UtilsBy qw<max_by>;

use Imager;
use Imager::Color;

sub summerize {
    my ($ctx, $pixels) = @_;
    my $method = lc $ctx->{param}{method};
    my @c = map { [$_->rgba] } @$pixels;

    my @sum = (0,0,0);

    if ($method eq 'mean') {
        my @sum;
        for my $c (@c) {
            $sum[0] += $c->[0];
            $sum[1] += $c->[1];
            $sum[2] += $c->[2];
        }
        return [
            int($sum[0]/@c),
            int($sum[1]/@c),
            int($sum[2]/@c),
        ]
    } elsif ($method eq 'variance') {
        my @sum;
        for my $c (@c) {
            $sum[0] += $c->[0];
            $sum[1] += $c->[1];
            $sum[2] += $c->[2];
        }
        my @mean = (int($sum[0]/@c), int($sum[1]/@c), int($sum[2]/@c));
        my @variance = (0,0,0);
        for my $c (@c) {
            $variance[0] += ($c->[0] - $mean[0])**2 / $#c;
            $variance[1] += ($c->[1] - $mean[1])**2 / $#c;
            $variance[2] += ($c->[2] - $mean[2])**2 / $#c;
        }
        return \@variance;
    } elsif ($method eq 'min') {
        my @min = (255,255,255);
        for my $c (@c) {
            $min[0] = $c->[0] if $c->[0] < $min[0];
            $min[1] = $c->[1] if $c->[1] < $min[1];
            $min[2] = $c->[2] if $c->[2] < $min[2];
        }
        return \@min;
    } elsif ($method eq 'max') {
        my @max = (0,0,0);
        for my $c (@c) {
            $max[0] = $c->[0] if $c->[0] > $max[0];
            $max[1] = $c->[1] if $c->[1] > $max[1];
            $max[2] = $c->[2] if $c->[2] > $max[2];
        }
        return \@max;
    } elsif ($method eq 'gradient') {
        my @max = (0,0,0);
        my @min = (255,255,255);
        for my $c (@c) {
            $min[0] = $c->[0] if $c->[0] < $min[0];
            $min[1] = $c->[1] if $c->[1] < $min[1];
            $min[2] = $c->[2] if $c->[2] < $min[2];
            $max[0] = $c->[0] if $c->[0] > $max[0];
            $max[1] = $c->[1] if $c->[1] > $max[1];
            $max[2] = $c->[2] if $c->[2] > $max[2];
        }
        return [
            $max[0] - $min[0],
            $max[1] - $min[1],
            $max[2] - $min[2],
        ]
    } elsif ($method eq 'mode') {
        my @freq;
        for my $c (@c) {
            $freq[0]{$c->[0]} += 1;
            $freq[1]{$c->[1]} += 1;
            $freq[2]{$c->[2]} += 1;
        }

        return [
            scalar(max_by { $freq[0]{$_} } (keys %{$freq[0]})),
            scalar(max_by { $freq[1]{$_} } (keys %{$freq[1]})),
            scalar(max_by { $freq[2]{$_} } (keys %{$freq[2]})),
        ]
    } elsif ($method eq 'median') {
        my @pixels;
        for my $c (@c) {
            push @{$pixels[0]}, $c->[0];
            push @{$pixels[1]}, $c->[1];
            push @{$pixels[2]}, $c->[2];
        }
        @{$pixels[0]} = sort {$a<=>$b} @{$pixels[0]};
        @{$pixels[1]} = sort {$a<=>$b} @{$pixels[1]};
        @{$pixels[2]} = sort {$a<=>$b} @{$pixels[2]};
        my $middle = int( (@c-1)/2 );
        return [
            $pixels[0][$middle],
            $pixels[1][$middle],
            $pixels[2][$middle],
        ]
    }
    die "unknown statistic method = $method";
}

sub statistic_filter {
    my %param = @_;
    my $ctx = { param => \%param };

    my $img = $param{imager};
    my $img_copy = $img->copy();

    my ($w,$h) = split("x", $param{geometry});
    $w ||= $h;
    my $w_half_1 = int(($w-1)/2);
    my $w_half_2 = int($w/2);
    my $h_half_1 = int(($h-1)/2);
    my $h_half_2 = int($h/2);
    my $img_bound_x = $img->getwidth - 1;
    my $img_bound_y = $img->getheight - 1;

    for my $y (0 .. $img_bound_y) {
        for my $x (0..$img_bound_x) {
            my $y_0 = max(0, $y - $h_half_1);
            my $y_1 = min($y + $h_half_2, $img_bound_y);
            my $x_0 = max(0, $x - $w_half_1);
            my $x_1 = min($x + $w_half_2, $img_bound_x);
            my $w_ = $x_1 - $x_0 + 1;
            my @px = map { $img_copy->getscanline(y => $_, x => $x_0, width => $w_) } ($y_0 .. $y_1);
            my $new_px = summerize($ctx, \@px);
            $img->setpixel( y => $y, x => $x, color => $new_px);
        }
    }
}

Imager->register_filter(
    type     => 'statistic',
    callsub  => \&statistic_filter,
    callseq  => ['image', 'method', 'geometry'],
    defaults => {},
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Imager::Filter::Statistic - Provide statistica-based pixel filters.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Imager;
    use Imager::Filter::Statistic;

    my $img = Imager->new(file => $file) or die Imager->errstr;
    $img->filter(
        type => "statistic",
        method => "gradient",
        geometry => "3x3"
    );
    $img->write(file => "filtered-by-gradient.png");

=head1 DESCRIPTION

This module provide a "statistic" type of image filter to work with L<Imager>. The filter does a sliding window scan.
For each pixel in the image, the pixel value is replaced by the summerizing its surroundings with a statistic
method. The parameter "geometry" means the size of sliding window, with format C<${width}x${height}>. The parameter
"method" means the summerizing method. Here's the full list of them:

=over 4

=item gradient (max - min)

=item variance

=item mean

=item min

=item max

=item mode

=back

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE


Kang-min Liu has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
