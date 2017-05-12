use 5.010;
use warnings;
use Test::More 'no_plan';

use IO::Prompter;

# -yesno

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
y
y
n
a
yes
y
END_INPUT

ok  prompt("Enter line 1", -yesno) => "-yesno 1";
ok  prompt("Enter line 1", -yn)    => "-yn    2";
ok !prompt("Enter line 1", -yesno) => "-yesno 3";
ok  prompt("Enter line 1", -yesno) => "-yesno 4";
ok  prompt("Enter line 1", -yesno) => "-yesno 4";
ok eof(*ARGV)                      => "-yesno complete";


# -YesNo

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Y
y
Y
n
N
a
Yes
Y
END_INPUT

ok  prompt("Enter line 1", -YesNo) => "-YesNo 1";
ok  prompt("Enter line 1", -YN)    => "-YN    2";
ok !prompt("Enter line 1", -YesNo) => "-YesNo 3";
ok  prompt("Enter line 1", -YesNo) => "-YesNo 4";
ok  prompt("Enter line 1", -YesNo) => "-YesNo 4";
ok eof(*ARGV)                      => "-YesNo complete";


# -yes

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
y
y
n
a
yes
y
END_INPUT

ok  prompt("Enter line 1", -yes) => "-yes 1";
ok  prompt("Enter line 1", -y_)  => "-y   2";
ok !prompt("Enter line 1", -yes) => "-yes 3";
ok !prompt("Enter line 1", -yes) => "-yes 4";
ok  prompt("Enter line 1", -yes) => "-yes 5";
ok  prompt("Enter line 1", -yes) => "-yes 6";
ok eof(*ARGV)                    => "-yes complete";


# -Yes

local *ARGV;
open *ARGV, '<', \<<END_INPUT or die $!;
Y
y
Y
n
N
a
Yes
Y
Y
END_INPUT

ok  prompt("Enter line 1", -Yes) => "-Yes 1";
ok  prompt("Enter line 1", -Y)   => "-Y   2";
ok !prompt("Enter line 1", -Yes) => "-Yes 3";
ok !prompt("Enter line 1", -Yes) => "-Yes 4";
ok !prompt("Enter line 1", -Yes) => "-Yes 5";
ok  prompt("Enter line 1", -Yes) => "-Yes 6";
ok  prompt("Enter line 1", -Yes) => "-Yes 6";
ok  prompt("Enter line 1", -Yes) => "-Yes 7";
ok eof(*ARGV)                    => "-Yes complete";

