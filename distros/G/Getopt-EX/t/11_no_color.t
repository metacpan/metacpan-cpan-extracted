use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    for (grep /^GETOPTEX|^COLORTERM$/, keys %ENV) {
	delete $ENV{$_};
    }
    $ENV{NO_COLOR} = "1";
}

use Getopt::EX::Colormap qw(colorize colorize24 ansi_code);

use constant {
    RESET => "",
};

sub rgb24(&) {
    my $sub = shift;
    local $Getopt::EX::Colormap::RGB24 = 1;
    $sub->();
}

is(colorize("N", "text"), "text", "N - NOP");
is(colorize(";", "text"), "text", "; - NOP");

is(colorize("R", "text"), ""."text".RESET, "colorize");

is(colorize("ABCDEF", "text"), ""."text".RESET, "colorize24");

is(colorize24("ABCDEF", "text"), ""."text".RESET, "colorize24");

{
    my $text = colorize("R", "AB") . "CD" . colorize("R", "EF");
    my $rslt = colorize("R", "AB") . colorize("B", "CD") . colorize("R", "EF");
    is(colorize("B", $text), $rslt, "nested");
}

{
    my $text = "AB" . colorize("B", "CD") . "EF";
    my $rslt = colorize("R", "AB") . colorize("B", "CD") . colorize("R", "EF");
    is(colorize("R", $text), $rslt, "nested 2");
}

{
    my $text = colorize("R", "ABCDEF");
    is(colorize("B", $text), $text, "nested/unchange");
}

is(ansi_code("EE334E"), "\e[38;5;197m", "hex24 (DeePink2)");
is(ansi_code("ABCDEF"), "\e[38;5;153m", "hex24");
is(ansi_code("#AABBCC"), "\e[38;5;146m", "hex24 with #");
is(ansi_code("#ABC"),    "\e[38;5;146m", "hex12");
is(ansi_code("(171,205,239)"), "\e[38;5;153m", "rgb");

is(ansi_code("#AAABBBCCC"), "\e[38;5;146m", "hex36 with #");
is(ansi_code("#AAAABBBBCCCC"), "\e[38;5;146m", "hex48 with #");

done_testing;
