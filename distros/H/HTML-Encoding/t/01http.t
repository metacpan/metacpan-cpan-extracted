use Test::More tests => 43;
use IO::File;
use File::Spec qw();
use HTTP::Response;

BEGIN {
  use_ok('HTML::Encoding');
};

while (<DATA>) {
  my ($name, $expect) = split ' ', $_, 2;
  $expect =~ s/[\r\n]+$//g;
  my $path = File::Spec->catfile('tinput', 'http', $name);
  my $data = do { local $/; IO::File->new('<' . $path)->getline };
  my $message = HTTP::Response->parse($data);
  my $charset = HTML::Encoding::encoding_from_http_message($message);
  $charset = '' unless defined $charset;
  is($charset, $expect);
}

__DATA__
01 utf-8
02 utf-8
03 utf-8
04 utf-8
05 utf-8
06 utf-8
07 utf-8
08 utf-8
09 utf-8
10 utf-8
11 utf-8
12 utf-8
13 iso-8859-1
14 iso-8859-1
15 iso-8859-1
16 ISO-8859-1
17 iso-8859-1
18 utf-8
19 utf-8
20 utf-8
21 utf-8
22 iso-8859-1
23 iso-8859-1
24 utf-8
25 utf-8
26 utf-8
27 utf-8
28 utf-8
29 utf-8
30 utf-8
31 utf-8
32 utf-8
33 CESU-8
34 CESU-8
35 {CE}SU-8
36 xCESU-8
37 PC-Multilingual-850+euro
38 ISO_8859-16:2001
39 utf-8
40 ISO-8859-1
41 
42 utf-8
