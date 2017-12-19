use strict;
use warnings;
use utf8;
use Test::More;

use Getopt::EX::Colormap qw(ansi_code);

is(ansi_code("R"), "\e[31m", "color name");
is(ansi_code("W/R"), "\e[37;41m", "background");
is(ansi_code("RDPIUFSVJ"), "\e[31;1;2;3;4;5;7;8;9m", "effect");

is(ansi_code("ABCDEF"), "\e[38;5;152m", "hex");
{
    local $Getopt::EX::Colormap::COLOR_RGB24 = 1;
    is(ansi_code("ABCDEF"), "\e[38;2;171;205;239m", "hex 24bit");
}

is(ansi_code("DK/544"), "\e[1;30;48;5;224m", "256 color");
is(ansi_code("L00/L23"), "\e[38;5;232;48;5;255m", "grey scale");
is(ansi_code("CCCCCC"), "\e[38;5;251m", "hex to grey scale map");
is(ansi_code("FFFFFF/000000"), "\e[38;5;231;48;5;16m", "hex, all 0/1");

is(ansi_code("DK/544E"), "\e[1;30;48;5;224m" . "\e[K", "E");
is(ansi_code("DK/544{EL}"), "\e[1;30;48;5;224m" . "\e[K", "{EL}");
is(ansi_code("DK/E544"), "\e[1;30m"."\e[K"."\e[48;5;224m" , "E");
is(ansi_code("DK/{EL}544"), "\e[1;30m"."\e[K"."\e[48;5;224m" , "{EL}");
is(ansi_code("{SGR}"), "\e[m", "{SGR}");
is(ansi_code("{SGR1;30;48;5;224}"), "\e[1;30;48;5;224m", "{SGR...}");
is(ansi_code("{SGR(1,30,48,5,224)}"), "\e[1;30;48;5;224m", "{SGR(...)}");

like(ansi_end("DK/544E"), qr/^\e\[?K/, "E before RESET");
like(ansi_end("DK/544{EL}"), qr/^\e\[?K/, "{EL} before RESET");

done_testing;

sub ansi_end {
    my $color = shift;
    my($s, $e) = Getopt::EX::Colormap::ansi_pair($color);
    $e;
}
