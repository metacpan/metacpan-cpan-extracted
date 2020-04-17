=head1 NAME

Getopt::EX::termcolor::Apple_Terminal

=head1 SYNOPSIS

command -Mtermcolor::Apple_Terminal

=head1 DESCRIPTION

This is a L<Getopt::EX::termcolor> module for Apple_Terminal.

=head1 SEE ALSO

L<Getopt::EX::termcolor>

=cut

package Getopt::EX::termcolor::Apple_Terminal;

use strict;
use warnings;
use Data::Dumper;

use Getopt::EX::termcolor qw(rgb_to_brightness);

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
