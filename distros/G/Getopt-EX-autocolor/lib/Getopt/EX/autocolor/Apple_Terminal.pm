=head1 NAME

Getopt::EX::autocolor::Apple_Terminal

=head1 SYNOPSIS

command -Mautocolor::Apple_Terminal

=head1 DESCRIPTION

This is a L<Getopt::EX::autocolor> module for Apple_Terminal.
Terminal brightness is caliculated from terminal background RGB values
by next equation.

    Y = 0.30 * R + 0.59 * G + 0.11 * B

When the result is greater than 0.5, set B<--light> option, otherwise
B<--dark>.  You can override default setting in your F<~/.sdifrc>.

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

sub initialize {
    my $rc = shift;
    if (defined (my $brightness = brightness)) {
	$rc->setopt(
	    default =>
	    $brightness > 50 ? '--light-terminal' : '--dark-terminal');
    }
}

1;

__DATA__
