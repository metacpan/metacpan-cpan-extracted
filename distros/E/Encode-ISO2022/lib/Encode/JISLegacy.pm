#-*- perl -*-
#-*- coding: us-ascii -*-

package Encode::JISLegacy;

use strict;
use warnings;

use base qw(Encode::Encoding);
our $VERSION = '0.02';

use Encode::JP;
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my $HTMLCREF = Encode::HTMLCREF();
my $PERLQQ   = Encode::PERLQQ();
my $XMLCREF  = Encode::XMLCREF();

# JIS C 6226-1978, 1st revision of JIS X 0208.
$Encode::Encoding{'jis-x-0208-1978'} = bless {
    Name => 'jis-x-0208-1978',
    alt => '1978',
    encoding => $Encode::Encoding{'jis0208-raw'},
} => __PACKAGE__;

# 26 row-cell pairs swapped between JIS C 6226-1978 and JIS X 0208-1983.
# cf. JIS X 0208:1997 Annex 2 Table 1.
my @swap1978 = (
    "\x30\x33" => "\x72\x4D", "\x32\x29" => "\x72\x74",
    "\x33\x42" => "\x69\x5a", "\x33\x49" => "\x59\x78",
    "\x33\x76" => "\x63\x5e", "\x34\x43" => "\x5e\x75",
    "\x34\x52" => "\x6b\x5d", "\x37\x5b" => "\x70\x74",
    "\x39\x5c" => "\x62\x68", "\x3c\x49" => "\x69\x22",
    "\x3F\x59" => "\x70\x57", "\x41\x28" => "\x6c\x4d",
    "\x44\x5B" => "\x54\x64", "\x45\x57" => "\x62\x6a",
    "\x45\x6e" => "\x5b\x6d", "\x45\x73" => "\x5e\x39",
    "\x46\x76" => "\x6d\x6e", "\x47\x68" => "\x6a\x24",
    "\x49\x30" => "\x5B\x58", "\x4b\x79" => "\x50\x56",
    "\x4c\x79" => "\x69\x2e", "\x4F\x36" => "\x64\x46",
    "\x36\x46" => "\x74\x21", "\x4B\x6A" => "\x74\x22",
    "\x4D\x5A" => "\x74\x23", "\x60\x76" => "\x74\x24",
);
my %swap1978 = (@swap1978, reverse @swap1978);

sub encode {
    my ($self, $utf8, $chk) = @_;

    if (not ref $chk) {
	$chk &= ~($PERLQQ | $HTMLCREF | $XMLCREF);
    }
    my $str;
    if ($self->{alt} eq '1978') {
	$str = $self->{encoding}->encode($utf8, $chk);
	$str =~ s{([\x21-\x7E]{2})}{$swap1978{$1} || $1}eg;
    } else {
	$str = $self->{encoding}->encode($utf8, $chk);
    }

    $_[1] = $utf8;
    return $str;
}

sub decode {
    my ($self, $str, $chk) = @_;

    my $utf8;
    if ($self->{alt} eq '1978') {
	$str =~ s{([\x21-\x7E]{2})}{$swap1978{$1} || $1}eg;
	$utf8 = $self->{encoding}->decode($str, $chk);
	$str =~ s{([\x21-\x7E]{2})}{$swap1978{$1} || $1}eg;
    } else {
	$utf8 = $self->{encoding}->decode($str, $chk);
    }

    $_[1] = $str;
    return $utf8;
}

sub perlio_ok { 0 }

1;
__END__

=head1 NAME

Encode::JISLegacy - Coded character sets for legacy JIS

=head1 DESCRIPTION

See L<Encode::ISO2022::CCS>.

=cut
