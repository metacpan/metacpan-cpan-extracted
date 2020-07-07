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

use v5.14;
use warnings;
use Data::Dumper;

{
    no warnings 'once';
    use Getopt::EX::Colormap;
    $Getopt::EX::Colormap::RGB24 = 1;
}

our $debug = 0;

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

my %script = (

'background' => <<END,
tell application "iTerm"
	tell current session of current window
		background color
	end tell
end tell
END

    );

use Capture::Tiny ':all';

sub background_rgb {
    my $script = $script{background};
    my($stdout, $stderr, $exit) = capture {
	system 'osascript', '-e', $script;
    };
    $exit == 0 or return;
    my @rgb = $stdout =~ /(\d+)/g;
    @rgb == 3 ? ( { max => 65535 }, @rgb) : ();
}

1;

__DATA__
