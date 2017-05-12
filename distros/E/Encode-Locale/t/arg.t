#!perl -w

use strict;
use warnings;
use Test::More;

use Encode::Locale qw($ENCODING_LOCALE decode_argv);
use Encode;
use utf8;

diag "ENCODING_LOCALE is $ENCODING_LOCALE\n";
my @chars = qw(funny chars š ™);
my @octets = map { Encode::encode(locale => $_) } @chars;
@ARGV = @octets;

plan tests => scalar(@ARGV);

decode_argv();

TODO: {
    local $TODO = "ARGV decoding";
    for (my $i = 0; $i < @ARGV; $i++) {
        is $chars[$i], $ARGV[$i],
            "chars(" . prettify($chars[$i]) .
            ") octets(" . prettify($octets[$i]) .
            ") argv(" . prettify($ARGV[$i]) . ")";
    }
}

sub prettify {
    my $text = shift;
    my @r;
    for (split(//, $text)) {
	if (ord() > 32 && ord() < 128) {
	    push @r, $_;
	}
	elsif (ord() < 256) {
	    push @r, sprintf "\\x%02X", ord();
	}
	else {
	    push @r, sprintf "\\x{%04X}", ord();
	}
    }
    join '', @r;
}
