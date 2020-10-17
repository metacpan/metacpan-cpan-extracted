#!/usr/bin/env perl

use Test::Most tests => 1;
use Renard::Incunabula::Common::Setup;
use Intertangle::Yarn::Types qw(Point);
use Intertangle::Taffeta::Transform::Affine2D::Rotation;

subtest "Build an affine rotation around (0,0)" => sub {
	my $eps = 1e-6;
	my $rotate = Intertangle::Taffeta::Transform::Affine2D::Rotation->new(
		angle => 90,
	);

	is $rotate->apply_to_point( [0, 0] ), [0, 0], 'rotate [0,0] -> [0,0] (no rotation at origin)';

	subtest "Rotate along orthogonal basis" => sub {
		ok $rotate->apply_to_point( [ 1,  0] )->near(Point->coerce([ 0,  1]), $eps), 'rotate [ 1,  0] -> [ 0,  1]';
		ok $rotate->apply_to_point( [ 0,  1] )->near(Point->coerce([-1,  0]), $eps), 'rotate [ 0,  1] -> [-1,  0]';
		ok $rotate->apply_to_point( [-1,  0] )->near(Point->coerce([ 0, -1]), $eps), 'rotate [-1,  0] -> [ 0, -1]';
		ok $rotate->apply_to_point( [ 0, -1] )->near(Point->coerce([ 1,  0]), $eps), 'rotate [ 0, -1] -> [ 1,  0]';
	};

	ok $rotate->apply_to_point([1, 1])->near(Point->coerce([-1, 1]), $eps), 'rotate [1,1] -> [-1,1]';
};

done_testing;
