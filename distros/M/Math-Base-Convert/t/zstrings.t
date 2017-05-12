
BEGIN { $| = 1; print "1..4357\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;


sub ok {
  print "ok $test\n";
  ++$test;
}

sub test { $test++ };

#use diagnostics;
use Math::Base::Convert qw( cnv cnvpre cnvabs );

my $usr = ['Z',1];	# user defined base

my @bases = (qw( bin dna DNA oct hex HEX dec b62 m64 b64 ), $usr);

sub getref {
  return $_[0] if ref $_[0];
  my $sub = 'Math::Base::Convert::'. $_[0];
  no strict;
  &{$sub};
}

sub getlen {
  my $ref = ref($_[0]) ? $_[0] : getref($_[0]);
  scalar @{$ref};
}

use strict;
  
sub getzero {
  my $base = shift;
  return ('', $base->[0]) if ref $base;
  return ('0b', 0)	if $base eq 'bin';	# unique
  return ('0x', 0)	if $base =~ /hex/i;	# unique
  return ('0', 0)	if $base =~ /oct/i;	# unique
  my $ref = getref($base);
  return ('', $ref->[0]);			# return zero digit
}

my $signedBase = $Math::Base::Convert::signedBase;
my $useprefix;
my $tcnv;

sub testit {
  my $sign  = shift;
  foreach my $from (@bases) {

    my $flab = ref($from) ? 'usr' : $from;
    my $flen = getlen($from);
    my($prefix, $in) = getzero($from);

    $sign = '' if $flen <= $Math::Base::Convert::signedBase;

    my $isign = $sign =~ /([+-])/ ? $1 : '';

    $in = $isign . $prefix. $in;

    foreach my $to (@bases) {

      my $tlab = ref($to) ? 'usr' : $to;
      my $tlen = getlen($to);
      my $osign = ($sign =~ /(\-)/ && $tlen <= $Math::Base::Convert::signedBase) ? $1 : '';

      my $out;
      ($prefix, $out) = getzero($to);

      my $ayprfx = $prefix;				# array output prefix

      $prefix = '' unless $useprefix;

      $out = $osign . $prefix . $out;

      my ($gsign,$ofix,$data) = $tcnv->($in,$from,$to);
      my $got = $tcnv->($in,$from,$to);

      print "$flab -> $tlab value got: $got, exp: $out\nnot "
	unless $got eq $out;
      &ok;

      print "$flab -> $tlab sign  got: |$gsign|, exp: |$isign|\nnot "
	unless $gsign eq $isign;
      &ok;

      print "$flab -> $tlab prefx got: |$ofix|, exp: |$ayprfx|\nnot "
	unless $ofix eq $ayprfx;
      &ok;

      my $ref = getref($to);
      print "$flab -> $tlab data  got: |$data|, exp: |$ref->[0]|\nnot "
	unless $data eq $ref->[0];
      &ok;
    }
  }
}

$useprefix = 1;
$tcnv   = \&cnvpre;

foreach ('','-','+') {
  testit($_);
}

$useprefix = 0;
$tcnv = \&cnv;

foreach ('','-','+') {
  testit($_);
}

$useprefix = 0;
$tcnv = \&cnvabs;

foreach ('','-','+') {
  testit($_);
}
