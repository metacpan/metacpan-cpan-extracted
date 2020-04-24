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

use Getopt::EX::termcolor qw(rgb_to_luminance);

sub get_colors {
    map {
	my @rgb = get_color($_);
	@rgb ? undef : [ @rgb ];
    } @_;
}

sub get_color {
    my $cat = lc shift;
    if ($cat eq 'background') {
	return background_rgb();
    }
    ();
}

sub background_rgb {
    my $app = "Terminal";
    my $do = "background color of first window";
    my $bg = qx{osascript -e \'tell application \"$app\" to $do\'};
    my @rgb = $bg =~ /(\d+)/g;
    @rgb == 3 ? ( { max => 65535 }, @rgb) : ();
}

1;

__DATA__
