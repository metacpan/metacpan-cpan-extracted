BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

use strict;
#use diagnostics;
use Math::Base::Convert;

require './recurse2txt';

#=pod

my $reg = [
	0xfffffffe,
	0xffffffff,
	0xfffffffc,
	0xffffffff,
	0xfffffff8,
	0xffffffff,
	0xfffffff0,
	0xffffffff,
	0xffffffe0,
	0xffffffff,
	0xffffffc0,
	0xffffffff,
	0xffffff80,
	0xffffffff,
	0xffffff00,
	0xffffffff,
	0xffffffff
];

my @exp = (0,	# unused position
# shift 1
  q|0x11	= [0xffffffff,0x7fffffff,0xfffffffe,0x7fffffff,0xfffffffc,0x7fffffff,0xfffffff8,0x7fffffff,0xfffffff0,0x7fffffff,0xffffffe0,0x7fffffff,0xffffffc0,0x7fffffff,0xffffff80,0xffffffff,0x7fffffff,];
|,
# shift 2
  q|0x11	= [0xffffffff,0x3fffffff,0xffffffff,0x3fffffff,0xfffffffe,0x3fffffff,0xfffffffc,0x3fffffff,0xfffffff8,0x3fffffff,0xfffffff0,0x3fffffff,0xffffffe0,0x3fffffff,0xffffffc0,0xffffffff,0x3fffffff,];
|,
# shift 3
  q|0x11	= [0xffffffff,0x9fffffff,0xffffffff,0x1fffffff,0xffffffff,0x1fffffff,0xfffffffe,0x1fffffff,0xfffffffc,0x1fffffff,0xfffffff8,0x1fffffff,0xfffffff0,0x1fffffff,0xffffffe0,0xffffffff,0x1fffffff,];
|,
# shift 4
  q|0x11	= [0xffffffff,0xcfffffff,0xffffffff,0x8fffffff,0xffffffff,0xfffffff,0xffffffff,0xfffffff,0xfffffffe,0xfffffff,0xfffffffc,0xfffffff,0xfffffff8,0xfffffff,0xfffffff0,0xffffffff,0xfffffff,];
|,
# shift 5
  q|0x11	= [0xffffffff,0xe7ffffff,0xffffffff,0xc7ffffff,0xffffffff,0x87ffffff,0xffffffff,0x7ffffff,0xffffffff,0x7ffffff,0xfffffffe,0x7ffffff,0xfffffffc,0x7ffffff,0xfffffff8,0xffffffff,0x7ffffff,];
|,
# shift 6
  q|0x11	= [0xffffffff,0xf3ffffff,0xffffffff,0xe3ffffff,0xffffffff,0xc3ffffff,0xffffffff,0x83ffffff,0xffffffff,0x3ffffff,0xffffffff,0x3ffffff,0xfffffffe,0x3ffffff,0xfffffffc,0xffffffff,0x3ffffff,];
|,
# shift 7
  q|0x11	= [0xffffffff,0xf9ffffff,0xffffffff,0xf1ffffff,0xffffffff,0xe1ffffff,0xffffffff,0xc1ffffff,0xffffffff,0x81ffffff,0xffffffff,0x1ffffff,0xffffffff,0x1ffffff,0xfffffffe,0xffffffff,0x1ffffff,];
|,
# shift 8
  q|0x11	= [0xffffffff,0xfcffffff,0xffffffff,0xf8ffffff,0xffffffff,0xf0ffffff,0xffffffff,0xe0ffffff,0xffffffff,0xc0ffffff,0xffffffff,0x80ffffff,0xffffffff,0xffffff,0xffffffff,0xffffffff,0xffffff,];
|
);

my $ta = bless [0], 'Math::Base::Convert';

# test 2		shift a zero register
$ta->shiftright(2);
(my $got = Dumper($ta))  =~ s/(\b\d+)/sprintf("0x%x",$1)/ge;
my $exp = qq|0x1\t= [0x0,];
|;
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 3 - 10	simple shift
foreach (1..8) {
  @$ta = @$reg;
  $ta->shiftright($_);
  (my $got = Dumper($ta))  =~ s/(\b\d+)/sprintf("0x%x",$1)/ge;
  print "got: $got\nexp: $exp[$_]\nnot "
	unless $got eq $exp[$_];
  &ok;
}

__END__ 

# test 11 - 18	complex shift
foreach (1..8) {
  @$ta = @$reg;
  $ta->xshiftright($_);
  (my $got = Dumper($ta))  =~ s/(\b\d+)/sprintf("0x%x",$1)/ge;
  print "got: $got\nexp: $exp[$_]\nnot "
	unless $got eq $exp[$_];
  &ok;
}

__END__

#=cut

my $reg = [
	0xfffffffe,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff,
	0xffffffff
];

my $exp;

my $iter = 2;

xshiftright = \&Math::Base::Convert::CalcPP::shiftright;
my $t1 = sub {
#  foreach my $shift(1..4) {
my $shift = 1;
    my $ep = ($iter * 32/$shift)-1;
    my @test = @$reg;
    foreach(0..$ep) {
      shiftright(\@test,$shift);
#      ($exp = Dumper(\@test))  =~ s/(\b\d+)/sprintf("0x%x",$1)/ge;
#      print "$_   ", $exp;
    }
#  }
};

*xshiftright = \&Math::Base::Convert::CalcPP::xshiftright;
my $t2 = sub {
#  foreach my $shift(1..4) {
my $shift = 1;
    my $ep = ($iter * 32/$shift)-1;
    my @test = @$reg;
    foreach(0..$ep) {
      xshiftright(\@test,$shift);
#      ($exp = Dumper(\@test))  =~ s/(\b\d+)/sprintf("0x%x",$1)/ge;
#      print "$_   ", $exp;
    }
#  }
};

&$t1;
&$t2;

use Benchmark qw(timethese);

timethese(-3,{
	new	=> $t1,
	old	=> $t2
},'noc');
