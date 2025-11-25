#!/usr/bin/env perl
#
# Encoding and Decoding of Base64
# Could use some more tests....
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body::Lines;

use Test::More;

use Time::HiRes 'time';
use Scalar::Util 'refaddr';

my $trace = 0;
my $large = $trace ? 100_000 : 1000;  # make larger for benchmarking

sub random_line($$$)
{	my ($avg_length, $number, $eol) = @_;
    my $line = substr "abcdefghijklmnopqrstuvwxyz0123456789!@#$%^*", 0, rand($avg_length *2);
	$line .= $eol->($line);
}

my @lines;
push @lines, random_line(20, $large, sub {(length $_[0]) % 2 ? "\012" : "\015\012"})
    while @lines < $large;
ok scalar @lines, 'created '.@lines.' lines';
my $i0 = grep ! m/\015\012$/, @lines;
cmp_ok $i0, '<', scalar @lines, "... $i0 do not end on CRLF";

my $body  = Mail::Message::Body::Lines->new
  ( mime_type => 'text/plain'
  , data      => \@lines
  );
is $body->mimeType, 'text/plain', '... text body';

my $s2   = time;
my $b2   = $body->eol("CRLF");
ok defined $b2, sprintf "Convert to CRLF in %.3fs", time - $s2;

ok refaddr $body != refaddr $b2, '... new body';
isa_ok $b2, 'Mail::Message::Body', '...';
isa_ok $b2, 'Mail::Message::Body::Lines', '...';
my $l2   = $b2->lines;
ok refaddr $l2 != refaddr \@lines, '... new set of lines';
cmp_ok scalar @$l2, '==', scalar @lines, '... same number of lines';
cmp_ok scalar(grep m!\015\012$!, @$l2), '==', scalar @$l2, '... all end with CRLF';

my $s3   = time;
my $b3   = $b2->eol("CRLF");
ok defined $b3, sprintf 'already perfect CRLF in %.3fs', time - $s3;
ok refaddr $b2 == refaddr $b3, '... same body';

done_testing;
