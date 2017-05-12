#!perl -T

# ABSTRACT: UTF-8 Byte Sequences - RFC3629 - test suite

# VERSION

# AUTHORITY

use strict;
use warnings FATAL => 'all';
use Encode qw/encode encode_utf8/;
use Test::More tests => 6;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

BEGIN {
    use_ok( 'MarpaX::RFC::RFC3629' ) || print "Bail out!\n";
}

foreach ("\x{0041}\x{2262}\x{0391}\x{002E}",
         "\x{0041}\x{2262}\x{0391}\x{002E}",
         "\x{D55C}\x{AD6D}\x{C5B4}",
         "\x{65E5}\x{672C}\x{8A9E}",
         "\x{233B4}") {

  my $octets = encode_utf8($_);
  my $got = MarpaX::RFC::RFC3629->new($octets)->output;
  ok($got eq $_, 'MarpaX::RFC::RFC3987->new->("' . _safePrint($octets) . '")->output returned ' . _safePrint($got) . '" eq "' . _safePrint($_) . '" ?');
}

sub _safePrint {
  my ($string) = @_;
  $string =~ s/([^\x20-\x7E])/sprintf("\\x{%X}", ord($1))/ge;
  $string;
}
