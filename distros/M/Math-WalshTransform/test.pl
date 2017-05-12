#!/usr/bin/perl -w
#########################################################################
#        This Perl script is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This script is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

use Test::Simple tests => 16;
use Math::WalshTransform qw(:ALL);
# $Math::WalshTransform::PP = 1;
my $eps = .000000001;

my @x = (0,2,2,0);
my @X = &fht(@x);
ok (&equal(\@X,[1,0,0,-1]), "Hadamard transform");
@X = &fwt(@x);
ok (&equal(\@X,[1,0,-1,0]), "Walsh transform");
my @IHT = &fhtinv(1,0,0,-1);
ok (&equal(\@IHT, [0,2,2,0]), "Inverse Hadamard transform");
my @IWT = &fwtinv(1,0,-1,0);
ok (&equal(\@IWT, [0,2,2,0]), "Inverse Walsh transform");

my @f;
for ($n=0; $n<=1023; $n++) { push @f, rand 9.9; }

my @H = &fht(@f); @h = &fhtinv(@H);
ok (&equal(\@f,\@h), "Hadamard transform and inverse");

my @W = &fwt(@f); @w = &fwtinv(@W);
ok (&equal(\@f,\@w), "Walsh transform and inverse");

my @HW = &hadamard2walsh(@H);
ok (&equal(\@W,\@HW), "Hadamard to Walsh");

my @WH = &walsh2hadamard(@W);
ok (&equal(\@H,\@WH), "Walsh to Hadamard");

my @f1; for ($n=0; $n<=511; $n++) { push @f1, rand 9.9; }
my @f2; for ($n=0; $n<=511; $n++) { push @f2, rand 9.9; }
my @lc1 = &Math::WalshTransform::old_logical_convolution(\@f1, \@f2);
my @lc2 = &logical_convolution(\@f1, \@f2);
# print "f1= @f1\nf2= @f2\nlc2= @lc2\n"; # to feed hard values to the lua test
ok (&equal(\@lc1,\@lc2), "Logical Convolution");

ok (abs(2.5 - &size(1.0,-0.5,2.0,-1.0)) < $eps, "size");

@x = (1.0, -1.5, 2.0, -2.5);
my @y = (3.0, -3.5, -4.0, 4.5);
ok (&equal(&product(\@x,\@y),[3.0, 5.25, -8.0, -11.25]), "product");

ok (abs(2.5-&distance([0.5,-0.5,3.0,1.0],[-0.5,0.0,1.0,2.0]))<$eps,"distance");

@y = &normalise(1.0,-0.5,2.0,-1.0);
ok (&equal(\@y, [0.4,-0.2,0.8,-0.4]),"normalise");

@y = &average([0.5,-0.5,3.0,1.0],[-0.5,0.0,1.0,2.0],[0.6,1.4,0.-2.2,0.3]);
ok (&equal(\@y,[0.2,0.3,0.6,1.1]), "average");

@y = &biggest(3,  0.5,-0.5,3.0,1.0,-0.5,0.0,1.0,2.0,0.6,1.4,0,-2.2,0.3);
ok (&equal(\@y,[0, 0, 3, 0, 0, 0, 0, 2, 0, 0, 0, -2.2, 0]), "biggest");

@y = &power_spectrum(.5,-.5,3,1,-.5,0,1,2,.6,1.4,0,-2.2,-.7,4.2,-1,5);
my @y2 = (0.74390625, 0.0025, 0.330625, 0.15015625, 0.06890625, 0.105625, 0.49, 0.05640625, 0.0225, 0.00765625, 0.02640625, 0.1225, 1.1025, 0.23765625, 0.47265625, 0.25);
ok (&equal(\@y,\@y2), "power_spectrum");

# --------------------------- infrastructure ----------------
sub equal { my ($xref, $yref) = @_;
	my @x = @$xref; my @y = @$yref;
	if (scalar @x != scalar @y) { return 0; }
	my $i; for ($i=$[; $i<=$#x; $i++) {
		if (abs($x[$i]-$y[$i]) > $eps) { return 0; }
	}
	return 1;
}

__END__

=pod

=head1 NAME

test.pl - Perl script to test Math::WalshTransform.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests Math::WalshTransform.pm

=head1 AUTHOR

Peter J Billam  http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

Math::WalshTransform.pm , http://www.pjb.com.au/ , perl(1).

=cut

