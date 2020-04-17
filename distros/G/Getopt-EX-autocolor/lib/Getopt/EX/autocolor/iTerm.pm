=head1 NAME

Getopt::EX::autocolor::iTerm

=head1 SYNOPSIS

command -Mautocolor::iTerm

=head1 DESCRIPTION

This is a L<Getopt::EX::autocolor> module for iTerm.

=head1 SEE ALSO

L<Getopt::EX::autocolor>

=cut

package Getopt::EX::autocolor::iTerm;

use strict;
use warnings;
use Data::Dumper;

use Getopt::EX::autocolor qw(rgb_to_brightness);
use App::cdif::Command::OSAscript;

{
    no warnings 'once';
    use Getopt::EX::Colormap;
    $Getopt::EX::Colormap::RGB24 = 1;
}

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
    return undef if grep { not /^\d+$/ } @rgb;
    rgb_to_brightness @rgb;
}

1;

__DATA__
