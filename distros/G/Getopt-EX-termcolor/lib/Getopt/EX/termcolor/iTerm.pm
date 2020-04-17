=head1 NAME

Getopt::EX::termcolor::iTerm

=head1 SYNOPSIS

command -Mtermcolor::iTerm

=head1 DESCRIPTION

This is a L<Getopt::EX::termcolor> module for iTerm.

=head1 SEE ALSO

L<Getopt::EX::termcolor>

=cut

package Getopt::EX::termcolor::iTerm;

use strict;
use warnings;
use Data::Dumper;

use Getopt::EX::termcolor qw(rgb_to_brightness);
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
