package Geometry::AffineTransform::Test;
use base qw(Test::Class);

use Geometry::AffineTransform;

use strict;
use warnings;

use Test::More;
use List::Util qw(max min);
use Data::Dumper;

sub identity : Test(6) {
	my $self = shift;

	my $t = Geometry::AffineTransform->new();
	my @result;
	@result = $t->transform(10, 5);
	is_deeply(\@result, [10, 5], "identity transform");
	@result = $t->transform(0, 0);
	is_deeply(\@result, [0, 0], "identity transform");
	
	my $inverse = $t->clone()->invert();
	ok(ref($inverse), "clone()->invert()");
	isnt($inverse, $t, "clone()->invert() returns different instance");
	
	@result = $inverse->transform(10, 5);
	is_deeply(\@result, [10, 5], "reverse identity transform");
	@result = $inverse->transform(0, 0);
	is_deeply(\@result, [0, 0], "reverse identity transform");

}


sub inverse : Test(2) {
	my $self = shift;

	my $t = Geometry::AffineTransform->new();
	my @result;
	$t->scale(0, 1)->translate(7, 7);
	@result = $t->transform(10, 5, 20, 6);
	is_deeply(\@result, [7, 12, 7, 13], "to line");

    eval {
    	$t->invert();
    };
    
    like($@, qr/^Unable to invert this transform .zero determinant./, "exception for zero determinant");	
}


sub determinant : Test(2) {
	my $self = shift;

	my $t = Geometry::AffineTransform->new();
	my @result;
	$t->scale(10, 5);
	is($t->determinant(), 50, "determinant()");

    $t->scale(0, 1);
	is($t->determinant(), 0, "determinant()");
}



sub rotate : Test(5) {
	my $self = shift;

	my $t = Geometry::AffineTransform->new();
	is($t->rotate(180), $t);
    my $inverse = $t->clone()->invert();

	is_deeply([$t->transform(10, 5)], [-10, -5], "rotate 180");
	is_deeply([$inverse->transform(-10, -5)], [10, 5], "rotate 180");
	
	$t->rotate(90)->rotate(90);
	is_deeply([$t->transform(10, 5)], [10, 5], "rotate 360");

	$inverse = $t->clone()->invert();
	is_deeply([$inverse->transform(10, 5)], [10, 5], "rotate 360 inverse");
	
}



sub matrix_2x3 : Test(4) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new();
	is_deeply([$t->matrix_2x3()], [1, 0, 0, 1, 0, 0]);

	is($t->set_matrix_2x3(1, 2, 3, 4, 5, 6), $t, "set_matrix_2x3");
	is_deeply([$t->matrix_2x3()], [1, 2, 3, 4, 5, 6]);
	is_deeply([$t->matrix()], [1, 2, 0, 3, 4, 0, 5, 6, 1]);
}



sub concatenate_matrix_2x3 : Test(2) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new();
	$t->set_matrix_2x3(1, 2, 3, 4, 5, 6);
	is($t->concatenate_matrix_2x3(1, 2, 3, 4, 5, 6), $t, "concatenate_matrix_2x3()");
	is_deeply([$t->matrix_2x3()], [7, 10, 15, 22, 28, 40]);
}



sub concatenate : Test(1) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new();
	$t->set_matrix_2x3(1, 2, 3, 4, 5, 6);
	my $t2 = Geometry::AffineTransform->new();
	$t2->set_matrix_2x3(1, 2, 3, 4, 5, 6);
	$t->concatenate($t2);
	is_deeply([$t->matrix_2x3()], [7, 10, 15, 22, 28, 40]);
}



sub translate : Test(2) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new();
	$t->translate(5, 6);
	is_deeply([$t->transform(10, 5)], [15, 11]);
	$t->rotate(90);
	is_deeply([$t->transform(10, 5)], [-11, 15]);
}



sub scale : Test(1) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new();
	$t->scale(3, 2);
	is_deeply([$t->transform(10, 5)], [30, 10]);
}



sub transform_multiple : Test(1) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new();
	$t->scale(3, 2);
	is_deeply([$t->transform(10, 5, 11, 6)], [30, 10, 33, 12]);
}




sub rect_dimensions {
#	my $self = shift;
	my ($x, $y, $x2, $y2) = @_;

	warn(Data::Dumper->Dump([[$x, $y, $x2, $y2]]));
	
	my $w = max($x, $x2) - min($x, $x2);
	my $h = max($y, $y2) - min($y, $y2);
	
	return ($w, $h);
}


sub clone : Test(3) {
	my $self = shift @_;
	my $t = Geometry::AffineTransform->new()->set_matrix_2x3(1, 2, 3, 4, 5, 6);
	my $t2 = $t->clone();
	is_deeply([$t2->matrix_2x3()], [1, 2, 3, 4, 5, 6]);
	$t->set_matrix_2x3(reverse 1, 2, 3, 4, 5, 6);
	is_deeply([$t->matrix_2x3()], [reverse 1, 2, 3, 4, 5, 6]);
	is_deeply([$t2->matrix_2x3()], [1, 2, 3, 4, 5, 6]);
	
}


sub matrix_multiply : Test(1) {
	my $self = shift;

# 	1 2 0
# 	3 4 0
# 	5 6 1

# 	1 2 0
# 	3 4 0
# 	5 6 1

#	1 * 1 + 2 * 3 + 0 * 5 =  7    1 * 2 + 2 * 4 + 0 * 6 = 10    1 * 0 + 2 * 0 + 0 * 1 = 0
#	3 * 1 + 4 * 3 + 0 * 5 = 15    3 * 2 + 4 * 4 + 0 * 6 = 22    3 * 0 + 4 * 0 + 0 * 1 = 0
#	5 * 1 + 6 * 3 + 1 * 5 = 28    5 * 2 + 6 * 4 + 1 * 6 = 40    5 * 0 + 6 * 0 + 1 * 1 = 1
	
	my @result = Geometry::AffineTransform->matrix_multiply([1, 2, 3, 4, 5, 6], [1, 2, 3, 4, 5, 6]);
	is_deeply(\@result, [7, 10, 15, 22, 28, 40]);
#	diag(Data::Dumper->Dump([\@result]));

}


1;

