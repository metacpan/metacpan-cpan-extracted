#!/usr/bin/env plackup
use strict;
use warnings;
use Plack::Builder;

use lib "lib";
use HTML::FromANSI::Tiny;
my $w = HTML::FromANSI::Tiny->new(auto_reverse => 1, background => 'white', foreground => 'black');
my $b = HTML::FromANSI::Tiny->new(auto_reverse => 1, background => 'black', foreground => 'white');

my $ansi = do { local $/; <DATA> };

my $alternate = eval q{
  use HTML::FromANSI;
  HTML::FromANSI::ansi2html( $ansi );
};

my $html =
  sprintf '<html><head><style>%s</style></head><body><pre>%s</pre><pre style="background: black; color: white;">%s</pre><hr/><div>%s</div></body></html>',
    scalar $w->css,
    scalar $w->html( $ansi ),
    scalar $b->html( $ansi ),
    $alternate;

builder { 
  sub { [ 200, [ "Content-type" => "text/html" ], [ $html ] ]; }
};

__DATA__
 0	[00m  0 [01;00m  0 [0m		 1	[01m  1 [01;01m  1 [0m
 2	[02m  2 [01;02m  2 [0m		 3	[03m  3 [01;03m  3 [0m
 4	[04m  4 [01;04m  4 [0m		 5	[05m  5 [01;05m  5 [0m
 6	[06m  6 [01;06m  6 [0m		 7	[07m  7 [01;07m  7 [0m
30	[30m 30 [01;30m 30 [0m		31	[31m 31 [01;31m 31 [0m
30	[30m 30 [07;30m 30 [0m		31	[31m 31 [07;31m 31 [0m
32	[32m 32 [01;32m 32 [0m		33	[33m 33 [01;33m 33 [0m
34	[34m 34 [01;34m 34 [0m		35	[35m 35 [01;35m 35 [0m
36	[36m 36 [01;36m 36 [0m		37	[37m 37 [01;37m 37 [0m
40	[40m 40 [01;40m 40 [0m		41	[41m 41 [01;41m 41 [0m
42	[42m 42 [01;42m 42 [0m		43	[43m 43 [01;43m 43 [0m
44	[44m 44 [01;44m 44 [0m		45	[45m 45 [01;45m 45 [0m
46	[46m 46 [01;46m 46 [0m		47	[47m 47 [01;47m 47 [0m
90	[90m 90 [01;90m 90 [0m		91	[91m 91 [01;91m 91 [0m
92	[92m 92 [01;92m 92 [0m		93	[93m 93 [01;93m 93 [0m
94	[94m 94 [01;94m 94 [0m		95	[95m 95 [01;95m 95 [0m
96	[96m 96 [01;96m 96 [0m		97	[97m 97 [01;97m 97 [0m
100	[100m 100 [01;100m 100 [0m		101	[101m 101 [01;101m 101 [0m
102	[102m 102 [01;102m 102 [0m		103	[103m 103 [01;103m 103 [0m
104	[104m 104 [01;104m 104 [0m		105	[105m 105 [01;105m 105 [0m
106	[106m 106 [01;106m 106 [0m		107	[107m 107 [01;107m 107 [0m
