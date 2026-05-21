#!/usr/bin/env perl -T

use strict;

use Time::HiRes 'sleep';
use POSIX qw(geteuid);
use Test::More;

# For debugging only
# use Data::Dumper;$Data::Dumper::Sortkeys=1; $Data::Dumper::Purity=1; $Data::Dumper::Deepcopy=1;

BEGIN {
    our $VERSION = '2.05';
    # Module is Linux-only; make this explicit in tests.
}

my $b  = "\e[34m";
my $bb = "\e[94m";
my $g  = "\e[32m";
my $gg = "\e[92m";
my $r  = "\e[31m";
my $rr = "\e[91m";
my $rs = "\e[0m";
my $c  = "\e[36m";
my $bk = "\e[40m";
my $y  = "\e[33m";

diag("\n\r$b$bk" . ' ' x 66 . $rs);
diag("\r$b$bk" . ' ' x 11 . q{   ,ad8888ba,  } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{  d8"'    `"8b } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ d8'           } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ 88            } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ 88      88888 } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{ Y8,        88 } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{  Y8a.    .a88 } . ' ' x 40 . $rs );
diag("\r$b$bk" . ' ' x 11 . q{   `"Y88888P"  } . ' ' x 40 . $rs );

sleep 0.3;

diag("\r$bk  \r\e[8A\e[26C$g$bk" , q{ 88888888888 } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88aaaaa     } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88"""""     } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );
diag("\r$bk  \r\e[26C$g$bk"      . q{ 88          } . $rs );

sleep 0.3;

diag("\r$bk  \r\e[8A\e[38C$r$bk" . q{ 88888888ba  } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      "8b } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      ,8P } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88aaaaaa8P' } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88""""""8b, } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      `8b } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88      a8P } . ' ' x 15 . $rs );
diag("\r$bk  \r\e[38C$r$bk"      . q{ 88888888P"  } . ' ' x 15 . $rs );
diag("\r$c$bk" . ' ' x 66 . $rs);

sleep .3;

diag("\r$c$bk" .             q{ 888888888888                         88                          } . $rs);
diag("\r$c$bk" .             q{      88                        ,d    ""                          } . $rs);
diag("\r$c$bk" .             q{      88                        88                                } . $rs);
diag("\r$c$bk" .             q{      88  ,adPPYba, ,adPPYba, MM88MMM 88 8b,dPPYba,   ,adPPYb,d8  } . $rs);
diag("\r$c$bk" .             q{      88 a8P_____88 I8[    ""   88    88 88P'   `"8a a8"    `Y88  } . $rs);
diag("\r$c$bk" .             q{      88 8PP"""""""  `"Y8ba,    88    88 88       88 8b       88  } . $rs);
diag("\r$c$bk" .             q{      88 "8b,   ,aa aa    ]8I   88,   88 88       88 "8a,   ,d88  } . $rs);
diag("\r$c$bk" .             q{      88  `"Ybbd8"' `"YbbdP"'   "Y888 88 88       88  `"YbbdP"Y8  } . $rs);
diag("\r$c$bk" .             q{                                                      aa,    ,88  } . $rs);
diag("\r$y$bk" . q{ Graphics::Framebuffer CPAN Module } . $c . q{                    "Y8bbdP"   } . $rs);
diag("\r$c$bk" . ' ' x 66 . $rs);
diag("\r ");

if( defined($ENV{'DISPLAY'}) ) {
	plan skip_all => "${y}Tests cannot run within X-Windows/Wayland$rs";
	exit(0);
} elsif ( $^O ne 'linux' ) {
	plan skip_all => "${r}Testable only on Linux$rs";
	exit(0);
} else {
	plan tests => 2;
	use_ok('Graphics::Framebuffer');
}

our $F = Graphics::Framebuffer->new('RESET' => 0, 'SPLASH' => 0);
isa_ok($F,'Graphics::Framebuffer');

$F->acceleration(0);
$F->splash(2);

$F->acceleration(1);
$F->splash(2);

exit(0);


__END__
