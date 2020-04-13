=head1 NAME

Getopt::EX::autocolor::iTerm

=head1 SYNOPSIS

command -Mautocolor::iTerm

=head1 DESCRIPTION

This is a L<Getopt::EX::autocolor> module for iTerm.  Terminal
brightness is caliculated from terminal background RGB values by next
equation.

    Y = 0.30 * R + 0.59 * G + 0.11 * B

When the result is greater than 0.5, set B<--light> option, otherwise
B<--dark>.  You can override default setting in your F<~/.sdifrc>.

=head1 SEE ALSO

L<Getopt::EX::autocolor>

=cut

package Getopt::EX::autocolor::iTerm;

use strict;
use warnings;
use Data::Dumper;

use Getopt::EX::Colormap;
use Getopt::EX::autocolor qw(rgb_to_brightness);
use App::cdif::Command::OSAscript;

our $debug;

my $script_iTerm = <<END;
tell application "iTerm"
	tell current session of current window
		background color
	end tell
end tell
END

sub rgb {
    my $result =
	App::cdif::Command::OSAscript->new->exec($script_iTerm);
    my @rgb = $result =~ /(\d+)/g;
    warn Dumper $result, \@rgb if $debug;
    @rgb;
}

sub brightness {
    my(@rgb) = rgb;
    return undef unless @rgb == 3;
    return undef     if grep { not /^\d+$/ } @rgb;
    rgb_to_brightness @rgb;
}

sub initialize {
    my $rc = shift;
    if (defined (my $brightness = brightness)) {
	$rc->setopt(
	    default =>
	    $brightness > 50 ? '--light' : '--dark');
    }
    no warnings 'once';
    $Getopt::EX::Colormap::RGB24 = 1;
}

1;

__DATA__
