=head1 NAME

Getopt::EX::autocolor::Apple_Terminal

=head1 SYNOPSIS

command -Mautocolor::Apple_Terminal

=head1 DESCRIPTION

This is a L<Getopt::EX::autocolor> module for Apple_Terminal.

=head1 SEE ALSO

L<Getopt::EX::autocolor>

=cut

package Getopt::EX::autocolor::Apple_Terminal;

use strict;
use warnings;
use Data::Dumper;

use Getopt::EX::autocolor qw(rgb_to_brightness);

sub rgb {
    my $app = "Terminal";
    my $do = "background color of first window";
    my $bg = qx{osascript -e \'tell application \"$app\" to $do\'};
    $bg =~ /(\d+)/g;
}

sub brightness {
    my(@rgb) = rgb;
    @rgb == 3 or return undef;
    if (grep { not /^\d+$/ } @rgb) {
	undef;
    } else {
	rgb_to_brightness @rgb;
    }
}

1;

__DATA__
