#!/usr/bin/env perl

use Test::Most tests => 1;
use Renard::Incunabula::Common::Setup;
use Intertangle::Taffeta::Transform::Affine2D::Scaling;

subtest "Build an affine scaling" => sub {
	my $scale = Intertangle::Taffeta::Transform::Affine2D::Scaling->new(
		scale => [2, 4],
	);

	is $scale->apply_to_point( [0, 0] ), [0, 0], 'scale [0,0] -> [0,0]';
	is $scale->apply_to_point( [8, 6] ), [16, 24], 'scale [8,6] -> [16,24]';
};

done_testing;
